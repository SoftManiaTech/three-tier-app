import logging
from typing import Optional

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

from config import TelemetryConfig

logger = logging.getLogger("telemetry")

# Global metrics references
_meter = None
_product_operations_counter = None
_telemetry_initialized = False


def init_telemetry(app) -> bool:
    """
    Initializes OpenTelemetry tracing and metrics with the OTLP HTTP exporter.
    Instruments the Flask app and MySQL client.
    Fails gracefully if the collector is unreachable or if telemetry is disabled.
    """
    global _meter, _product_operations_counter, _telemetry_initialized

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

        # 2. Setup Tracing
        trace_endpoint = f"{TelemetryConfig.OTLP_ENDPOINT.rstrip('/')}/v1/traces"
        span_exporter = OTLPSpanExporter(endpoint=trace_endpoint)
        tracer_provider = TracerProvider(resource=resource)
        tracer_provider.add_span_processor(BatchSpanProcessor(span_exporter))
        trace.set_tracer_provider(tracer_provider)

        # 3. Setup Metrics
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
        except Exception as metric_err:
            logger.warning(
                "OTel metrics initialization skipped or encountered error: %s",
                metric_err,
            )

        # 4. Instrument Flask application
        FlaskInstrumentor().instrument_app(
            app, excluded_urls=TelemetryConfig.EXCLUDED_URLS
        )

        # 5. Instrument MySQL driver
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
        # Annotate current active span with business event
        current_span = trace.get_current_span()
        if current_span and current_span.is_recording():
            current_span.add_event(
                "product.operation",
                {"operation": operation, "status": status},
            )

        # Increment metric counter
        if _product_operations_counter is not None:
            _product_operations_counter.add(
                1, {"operation": operation, "status": status}
            )
    except Exception as err:
        logger.debug("Failed recording product operation metric: %s", err)


def get_tracer():
    """Retrieve the standard OpenTelemetry tracer."""
    return trace.get_tracer(TelemetryConfig.SERVICE_NAME)
