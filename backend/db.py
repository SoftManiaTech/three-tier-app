import mysql.connector
from config import DatabaseConfig


def get_connection():
    """Create and return a MySQL database connection using central config."""
    return mysql.connector.connect(
        host=DatabaseConfig.HOST,
        port=DatabaseConfig.PORT,
        user=DatabaseConfig.USER,
        password=DatabaseConfig.PASSWORD,
        database=DatabaseConfig.NAME,
        connection_timeout=DatabaseConfig.CONNECTION_TIMEOUT,
    )
