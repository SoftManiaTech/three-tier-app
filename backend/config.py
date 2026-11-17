import os
from decimal import Decimal

# Load environment variables if dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv()
    env_file = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_file):
        load_dotenv(dotenv_path=env_file)
except ImportError:
    pass


class DatabaseConfig:
    HOST: str = os.getenv("DB_HOST", "127.0.0.1")
    PORT: int = int(os.getenv("DB_PORT", "3306"))
    NAME: str = os.getenv("DB_NAME", "appdb")
    USER: str = os.getenv("DB_USER", "appuser")
    PASSWORD: str = os.getenv("DB_PASSWORD", "admin123")
    CONNECTION_TIMEOUT: int = int(os.getenv("DB_CONNECTION_TIMEOUT", "5"))


class ServerConfig:
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "5000"))
    DEBUG: bool = os.getenv("FLASK_DEBUG", "false").lower() in ("true", "1", "yes")


class TelemetryConfig:
    ENABLED: bool = os.getenv("OTEL_ENABLED", "false").lower() in ("true", "1", "yes")
    SERVICE_NAME: str = os.getenv("OTEL_SERVICE_NAME", "three-tier-product-api")
    SERVICE_VERSION: str = os.getenv("OTEL_SERVICE_VERSION", "1.0.0")
    ENVIRONMENT: str = os.getenv("OTEL_ENVIRONMENT", "production")
    OTLP_ENDPOINT: str = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")
    EXCLUDED_URLS: str = os.getenv("OTEL_EXCLUDED_URLS", "api/health")


class ProductDomainLimits:
    MAX_NAME_LENGTH: int = 100
    MAX_CATEGORY_LENGTH: int = 50
    DEFAULT_CATEGORY: str = "General"
    MAX_PRICE: Decimal = Decimal("99999999.99")
    PRICE_DECIMAL_PLACES: Decimal = Decimal("0.01")
