import os
import socket
import sqlite3
import logging
from decimal import Decimal
import mysql.connector
from config import DatabaseConfig

logger = logging.getLogger("db")

SQLITE_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "fallback.db"))


class SQLiteCursorWrapper:
    def __init__(self, cursor, dictionary=False):
        self._cursor = cursor
        self._dictionary = dictionary

    def execute(self, query, params=None):
        adapted_query = query.replace("%s", "?")
        if params is None:
            return self._cursor.execute(adapted_query)
        adapted_params = tuple(
            float(p) if isinstance(p, Decimal) else p for p in params
        )
        return self._cursor.execute(adapted_query, adapted_params)

    def fetchall(self):
        rows = self._cursor.fetchall()
        if self._dictionary:
            return [dict(row) for row in rows]
        return rows

    def fetchone(self):
        row = self._cursor.fetchone()
        if row is None:
            return None
        if self._dictionary:
            return dict(row)
        return row

    @property
    def rowcount(self):
        return self._cursor.rowcount

    @property
    def lastrowid(self):
        return self._cursor.lastrowid

    def close(self):
        self._cursor.close()


class SQLiteConnectionWrapper:
    def __init__(self, conn):
        self._conn = conn

    def cursor(self, dictionary=False):
        return SQLiteCursorWrapper(self._conn.cursor(), dictionary=dictionary)

    def commit(self):
        self._conn.commit()

    def rollback(self):
        self._conn.rollback()

    def close(self):
        self._conn.close()


def _init_sqlite_db():
    conn = sqlite3.connect(SQLITE_DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL DEFAULT 'General',
            price NUMERIC NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    """)
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM products")
    if cur.fetchone()[0] == 0:
        cur.executemany(
            "INSERT INTO products (name, description, category, price) VALUES (?, ?, ?, ?)",
            [
                ("Wireless Noise-Canceling Headphones", "Over-ear Bluetooth headphones with active noise cancellation and 30-hour battery life.", "Electronics", 12999.00),
                ("Smart LED Desk Lamp", "Adjustable color temperature desk lamp with touch controls and USB charging port.", "Electronics", 2499.00),
                ("Mechanical Gaming Keyboard", "RGB backlit mechanical keyboard with tactile blue switches and detachable USB-C cable.", "Peripherals", 3499.00),
                ("Ergonomic Optical Mouse", "Wireless ergonomic mouse with adjustable DPI, silent clicks, and comfortable thumb rest.", "Peripherals", 1299.00),
                ("Aluminium Laptop Stand", "Foldable ergonomic laptop riser compatible with laptops from 10 to 17 inches.", "Accessories", 1499.00),
                ("Extended Gaming Mouse Pad", "Extra large water-resistant micro-texture cloth pad with anti-fray stitched edges.", "Accessories", 699.00),
            ]
        )
        conn.commit()
    conn.close()


def _is_mysql_listening() -> bool:
    """Fast check if MySQL host:port is accepting connections."""
    try:
        sock = socket.create_connection(
            (DatabaseConfig.HOST, DatabaseConfig.PORT), timeout=0.2
        )
        sock.close()
        return True
    except Exception:
        return False


def get_connection():
    """Create and return a database connection. Tries MySQL first; falls back to SQLite if unavailable."""
    if _is_mysql_listening():
        try:
            return mysql.connector.connect(
                host=DatabaseConfig.HOST,
                port=DatabaseConfig.PORT,
                user=DatabaseConfig.USER,
                password=DatabaseConfig.PASSWORD,
                database=DatabaseConfig.NAME,
                connection_timeout=DatabaseConfig.CONNECTION_TIMEOUT,
            )
        except Exception as e:
            logger.warning("MySQL connection error: %s. Falling back to SQLite.", e)

    _init_sqlite_db()
    conn = sqlite3.connect(SQLITE_DB_PATH)
    conn.row_factory = sqlite3.Row
    return SQLiteConnectionWrapper(conn)
