import logging
from typing import Optional, Tuple

from opentelemetry import trace, metrics
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.mysql import MySQLInstrumentor

from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter
from opentelemetry._logs import set_logger_provider
import opentelemetry._logs

from config import TelemetryConfig

logger = logging.getLogger("telemetry")

# Global references
_meter = None
_product_operations_counter = None
_frontend_page_views_counter = None
_telemetry_initialized = False
_logger_provider = None


def get_current_trace_context() -> Tuple[str, str]:
    """
    Returns (trace_id, span_id) as hexadecimal strings for the currently active span.
    If no active or valid span exists, returns empty strings or zeroes.
    """
    try:
        span = trace.get_current_span()
        if span:
            ctx = span.get_span_context()
            if ctx and ctx.is_valid:
                return format(ctx.trace_id, "032x"), format(ctx.span_id, "016x")
    except Exception:
        pass
    return "0" * 32, "0" * 16


class TraceContextFilter(logging.Filter):
    """
    Logging filter that automatically attaches trace_id and span_id to every log record,
    enabling automatic trace-to-log correlation in Splunk and observability backends.
    """
    def filter(self, record: logging.LogRecord) -> bool:
        trace_id, span_id = get_current_trace_context()
        record.trace_id = trace_id
        record.span_id = span_id
        return True


def init_telemetry(app) -> bool:
    """
    Initializes OpenTelemetry tracing, metrics, and logs with the OTLP HTTP exporter.
    Instruments Flask, MySQL, and ships application logs to the Splunk OTel Collector.
    """
    global _meter, _product_operations_counter, _telemetry_initialized, _logger_provider

    # Attach trace context filter to app loggers
    context_filter = TraceContextFilter()
    app.logger.addFilter(context_filter)
    logging.getLogger("myapp.audit").addFilter(context_filter)
    logging.getLogger("frontend.audit").addFilter(context_filter)

    if not TelemetryConfig.ENABLED:
        logger.info("OpenTelemetry is disabled via OTEL_ENABLED=false")
        return False

    if _telemetry_initialized:
        logger.debug("OpenTelemetry already initialized")
        return True

    try:
        # 1. Define telemetry resource attributes
        resource = Resource.create(
            {
                SERVICE_NAME: TelemetryConfig.SERVICE_NAME,
                SERVICE_VERSION: TelemetryConfig.SERVICE_VERSION,
                "deployment.environment": TelemetryConfig.ENVIRONMENT,
            }
        )

        # 2. Setup Tracing (OTLP -> Collector /v1/traces)
        trace_endpoint = f"{TelemetryConfig.OTLP_ENDPOINT.rstrip('/')}/v1/traces"
        span_exporter = OTLPSpanExporter(endpoint=trace_endpoint)
        tracer_provider = TracerProvider(resource=resource)
        tracer_provider.add_span_processor(BatchSpanProcessor(span_exporter))
        trace.set_tracer_provider(tracer_provider)

        # 3. Setup Metrics (OTLP -> Collector /v1/metrics)
        try:
            metric_endpoint = f"{TelemetryConfig.OTLP_ENDPOINT.rstrip('/')}/v1/metrics"
            metric_exporter = OTLPMetricExporter(endpoint=metric_endpoint)
            metric_reader = PeriodicExportingMetricReader(
                metric_exporter, export_interval_millis=15000
            )
            meter_provider = MeterProvider(
                resource=resource, metric_readers=[metric_reader]
            )
            metrics.set_meter_provider(meter_provider)
            _meter = metrics.get_meter(TelemetryConfig.SERVICE_NAME)

            _product_operations_counter = _meter.create_counter(
                name="product.operations.total",
                description="Total count of product CRUD operations",
                unit="1",
            )
            _frontend_page_views_counter = _meter.create_counter(
                name="frontend.page_views.total",
                description="Total count of frontend client page view transitions",
                unit="1",
            )
        except Exception as metric_err:
            logger.warning(
                "OTel metrics initialization skipped or encountered error: %s",
                metric_err,
            )

        # 4. Setup Logging (OTLP -> Splunk OTel Collector /v1/logs)
        try:
            log_endpoint = f"{TelemetryConfig.OTLP_ENDPOINT.rstrip('/')}/v1/logs"
            log_exporter = OTLPLogExporter(endpoint=log_endpoint)
            _logger_provider = LoggerProvider(resource=resource)
            _logger_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))
            set_logger_provider(_logger_provider)

            # Attach OTLP handler to ship application logs to Splunk OTel Collector
            otlp_handler = LoggingHandler(level=logging.INFO, logger_provider=_logger_provider)
            otlp_handler.addFilter(context_filter)
            app.logger.addHandler(otlp_handler)
            logging.getLogger("myapp.audit").addHandler(otlp_handler)
            logging.getLogger("frontend.audit").addHandler(otlp_handler)
            logger.info("OTel logging handler attached for Splunk export to %s", log_endpoint)
        except Exception as log_err:
            logger.warning("OTel logging initialization note: %s", log_err)

        # 5. Instrument Flask application
        FlaskInstrumentor().instrument_app(
            app, excluded_urls=TelemetryConfig.EXCLUDED_URLS
        )

        # 6. Instrument MySQL driver
        try:
            MySQLInstrumentor().instrument()
        except Exception as db_inst_err:
            logger.warning("MySQL instrumentation note: %s", db_inst_err)

        _telemetry_initialized = True
        logger.info(
            "OpenTelemetry initialized successfully (Service: %s, Endpoint: %s)",
            TelemetryConfig.SERVICE_NAME,
            TelemetryConfig.OTLP_ENDPOINT,
        )
        return True
    except Exception as e:
        logger.error(
            "Failed to initialize OpenTelemetry exporter: %s. Application continuing normally.",
            e,
        )
        return False


def record_product_operation(operation: str, status: str = "success") -> None:
    """
    Increment business metric counter and annotate the current active span.
    Safe to call even if telemetry is disabled or uninitialized.
    """
    try:
        current_span = trace.get_current_span()
        if current_span and current_span.is_recording():
            current_span.add_event(
                "product.operation",
                {"operation": operation, "status": status},
            )

        if _product_operations_counter is not None:
            _product_operations_counter.add(
                1, {"operation": operation, "status": status}
            )
    except Exception as err:
        logger.debug("Failed recording product operation metric: %s", err)


def record_frontend_page_view(route: str, status: str = "success") -> None:
    """
    Increment frontend page views metric counter and annotate current span.
    Safe to call even if telemetry is disabled or uninitialized.
    """
    try:
        current_span = trace.get_current_span()
        if current_span and current_span.is_recording():
            current_span.add_event(
                "frontend.page_view",
                {"route": route, "status": status},
            )

        if _frontend_page_views_counter is not None:
            _frontend_page_views_counter.add(
                1, {"route": route, "status": status}
            )
    except Exception as err:
        logger.debug("Failed recording frontend page view metric: %s", err)


def flush_telemetry():
    """Forces flushing of traces, metrics, and logs."""
    try:
        tracer_provider = trace.get_tracer_provider()
        if hasattr(tracer_provider, "force_flush"):
            tracer_provider.force_flush()
        meter_provider = metrics.get_meter_provider()
        if hasattr(meter_provider, "force_flush"):
            meter_provider.force_flush()
        if _logger_provider and hasattr(_logger_provider, "force_flush"):
            _logger_provider.force_flush()
    except Exception:
        pass


def get_tracer():
    """Retrieve the standard OpenTelemetry tracer."""
    return trace.get_tracer(TelemetryConfig.SERVICE_NAME)
