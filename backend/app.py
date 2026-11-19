import os
import time
import logging
from decimal import Decimal, InvalidOperation
from flask import Flask, g, jsonify, request
from flask_cors import CORS

from db import get_connection
from config import ServerConfig, ProductDomainLimits
from telemetry import init_telemetry, record_product_operation, get_current_trace_context

app = Flask(__name__)
CORS(app)
init_telemetry(app)

logger = logging.getLogger("myapp.audit")


@app.before_request
def start_request_timer():
    g.request_started_at = time.perf_counter()


@app.after_request
def log_request(response):
    """Log one concise record for every HTTP request with trace and span IDs."""
    started_at = getattr(g, "request_started_at", None)
    duration_ms = (time.perf_counter() - started_at) * 1000 if started_at else 0
    trace_id, span_id = get_current_trace_context()
    app.logger.info(
        'request trace_id=%s span_id=%s method=%s path=%s status=%s duration_ms=%.2f remote_addr=%s',
        trace_id,
        span_id,
        request.method,
        request.path,
        response.status_code,
        duration_ms,
        request.remote_addr or "unknown",
    )
    return response


def format_product(product):
    if not product:
        return None
    formatted = dict(product)
    if "price" in formatted and formatted["price"] is not None:
        formatted["price"] = str(formatted["price"])
    if "created_at" in formatted and formatted["created_at"] is not None:
        formatted["created_at"] = (
            formatted["created_at"].isoformat()
            if hasattr(formatted["created_at"], "isoformat")
            else str(formatted["created_at"])
        )
    if "updated_at" in formatted and formatted["updated_at"] is not None:
        formatted["updated_at"] = (
            formatted["updated_at"].isoformat()
            if hasattr(formatted["updated_at"], "isoformat")
            else str(formatted["updated_at"])
        )
    return formatted


@app.get("/api/health")
def health():
    return jsonify({"status": "healthy", "service": "backend"}), 200


@app.post("/api/logs")
def ingest_frontend_logs():
    """
    Ingest client-side frontend logs and forward them into the logging pipeline.
    When OpenTelemetry is enabled, these logs are automatically exported to the
    Splunk OpenTelemetry Collector along with their trace context.
    """
    data = request.get_json(silent=True) or {}
    level = (data.get("level") or "info").upper()
    message = data.get("message") or "Frontend event"
    trace_id = data.get("trace_id") or "unknown"
    component = data.get("component") or "frontend-ui"
    details = data.get("details") or {}

    frontend_logger = logging.getLogger("frontend.audit")
    log_msg = f"[frontend] component={component} trace_id={trace_id} message={message} details={details}"
    if level == "ERROR":
        frontend_logger.error(log_msg)
    elif level in ("WARN", "WARNING"):
        frontend_logger.warning(log_msg)
    else:
        frontend_logger.info(log_msg)
    return jsonify({"status": "received", "trace_id": trace_id}), 200


@app.get("/api/products")
def get_products():
    category = request.args.get("category")
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        if category and category.strip():
            cursor.execute(
                "SELECT id, name, description, category, price, created_at, updated_at "
                "FROM products WHERE category = %s ORDER BY id DESC",
                (category.strip(),),
            )
        else:
            cursor.execute(
                "SELECT id, name, description, category, price, created_at, updated_at "
                "FROM products ORDER BY id DESC"
            )
        rows = cursor.fetchall()
        products = [format_product(row) for row in rows]
        trace_id, span_id = get_current_trace_context()
        logger.info(
            "db.query.products_success count=%d category=%s trace_id=%s span_id=%s",
            len(products),
            category.strip() if category else "ALL",
            trace_id,
            span_id,
        )
        return jsonify(products), 200
    except Exception:
        trace_id, span_id = get_current_trace_context()
        logger.exception("db.query.products_failed trace_id=%s span_id=%s", trace_id, span_id)
        return jsonify({"error": "Unable to retrieve products", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


@app.get("/api/products/<int:id>")
def get_product(id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, name, description, category, price, created_at, updated_at "
            "FROM products WHERE id = %s",
            (id,),
        )
        product = cursor.fetchone()
        trace_id, span_id = get_current_trace_context()
        if product is None:
            logger.warning("db.query.product_not_found product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
            return jsonify({"error": "Product not found"}), 404
        logger.info("db.query.product_found product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        return jsonify(format_product(product)), 200
    except Exception:
        trace_id, span_id = get_current_trace_context()
        logger.exception("db.query.product_failed product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        return jsonify({"error": "Unable to retrieve product", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


@app.post("/api/products")
def create_product():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"error": "JSON body required"}), 400

    name = data.get("name")
    if not isinstance(name, str) or not name.strip():
        return jsonify({"error": "Product name is required"}), 400
    name = name.strip()
    if len(name) > ProductDomainLimits.MAX_NAME_LENGTH:
        return jsonify({"error": f"Name must be {ProductDomainLimits.MAX_NAME_LENGTH} characters or less"}), 400

    raw_price = data.get("price")
    if raw_price is None or raw_price == "":
        return jsonify({"error": "Price is required"}), 400
    try:
        price = Decimal(str(raw_price))
        if not price.is_finite() or price <= 0 or price > ProductDomainLimits.MAX_PRICE:
            raise InvalidOperation
        price = price.quantize(ProductDomainLimits.PRICE_DECIMAL_PLACES)
    except (InvalidOperation, ValueError, TypeError):
        return jsonify({"error": "Enter a valid positive price"}), 400

    description = data.get("description")
    if description is not None:
        if not isinstance(description, str):
            return jsonify({"error": "Description must be a string"}), 400
        description = description.strip()
    else:
        description = ""

    category = data.get("category")
    if category is not None:
        if not isinstance(category, str):
            return jsonify({"error": "Category must be a string"}), 400
        category = category.strip()
        if not category:
            category = ProductDomainLimits.DEFAULT_CATEGORY
        elif len(category) > ProductDomainLimits.MAX_CATEGORY_LENGTH:
            return jsonify({"error": f"Category must be {ProductDomainLimits.MAX_CATEGORY_LENGTH} characters or less"}), 400
    else:
        category = ProductDomainLimits.DEFAULT_CATEGORY

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "INSERT INTO products (name, description, category, price) VALUES (%s, %s, %s, %s)",
            (name, description, category, price),
        )
        conn.commit()
        product_id = cursor.lastrowid
        trace_id, span_id = get_current_trace_context()
        logger.info("product.create.success product_id=%s trace_id=%s span_id=%s", product_id, trace_id, span_id)
        record_product_operation("create", status="success")

        cursor.execute(
            "SELECT id, name, description, category, price, created_at, updated_at "
            "FROM products WHERE id = %s",
            (product_id,),
        )
        created_product = cursor.fetchone()
        return jsonify(format_product(created_product)), 201
    except Exception:
        if conn is not None:
            conn.rollback()
        trace_id, span_id = get_current_trace_context()
        logger.exception("product.create.failed trace_id=%s span_id=%s", trace_id, span_id)
        record_product_operation("create", status="failure")
        return jsonify({"error": "Unable to save product", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


@app.put("/api/products/<int:id>")
def update_product(id):
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"error": "JSON body required"}), 400

    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, name, description, category, price, created_at, updated_at "
            "FROM products WHERE id = %s",
            (id,),
        )
        existing = cursor.fetchone()
        if not existing:
            return jsonify({"error": "Product not found"}), 404

        name = existing["name"]
        if "name" in data:
            val = data["name"]
            if not isinstance(val, str) or not val.strip():
                return jsonify({"error": "Product name cannot be empty"}), 400
            val = val.strip()
            if len(val) > ProductDomainLimits.MAX_NAME_LENGTH:
                return jsonify({"error": f"Name must be {ProductDomainLimits.MAX_NAME_LENGTH} characters or less"}), 400
            name = val

        price = existing["price"]
        if "price" in data:
            raw_price = data["price"]
            if raw_price is None or raw_price == "":
                return jsonify({"error": "Price cannot be empty"}), 400
            try:
                val = Decimal(str(raw_price))
                if not val.is_finite() or val <= 0 or val > ProductDomainLimits.MAX_PRICE:
                    raise InvalidOperation
                price = val.quantize(ProductDomainLimits.PRICE_DECIMAL_PLACES)
            except (InvalidOperation, ValueError, TypeError):
                return jsonify({"error": "Enter a valid positive price"}), 400

        description = existing["description"]
        if "description" in data:
            val = data["description"]
            if val is not None and not isinstance(val, str):
                return jsonify({"error": "Description must be a string"}), 400
            description = val.strip() if isinstance(val, str) else ""

        category = existing["category"]
        if "category" in data:
            val = data["category"]
            if val is not None and not isinstance(val, str):
                return jsonify({"error": "Category must be a string"}), 400
            if isinstance(val, str):
                val = val.strip()
                category = val if val else ProductDomainLimits.DEFAULT_CATEGORY
            else:
                category = ProductDomainLimits.DEFAULT_CATEGORY
            if len(category) > ProductDomainLimits.MAX_CATEGORY_LENGTH:
                return jsonify({"error": f"Category must be {ProductDomainLimits.MAX_CATEGORY_LENGTH} characters or less"}), 400

        cursor.execute(
            "UPDATE products SET name = %s, description = %s, category = %s, price = %s "
            "WHERE id = %s",
            (name, description, category, price, id),
        )
        conn.commit()
        trace_id, span_id = get_current_trace_context()
        logger.info("product.update.success product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        record_product_operation("update", status="success")

        cursor.execute(
            "SELECT id, name, description, category, price, created_at, updated_at "
            "FROM products WHERE id = %s",
            (id,),
        )
        updated = cursor.fetchone()
        return jsonify(format_product(updated)), 200
    except Exception:
        if conn is not None:
            conn.rollback()
        trace_id, span_id = get_current_trace_context()
        logger.exception("product.update.failed product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        record_product_operation("update", status="failure")
        return jsonify({"error": "Unable to update product", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


@app.delete("/api/products/<int:id>")
def delete_product(id):
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM products WHERE id = %s", (id,))
        if cursor.rowcount == 0:
            return jsonify({"error": "Product not found"}), 404
        conn.commit()
        trace_id, span_id = get_current_trace_context()
        logger.info("product.delete.success product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        record_product_operation("delete", status="success")
        return jsonify({"message": "Product deleted successfully", "id": id, "trace_id": trace_id}), 200
    except Exception:
        if conn is not None:
            conn.rollback()
        trace_id, span_id = get_current_trace_context()
        logger.exception("product.delete.failed product_id=%s trace_id=%s span_id=%s", id, trace_id, span_id)
        record_product_operation("delete", status="failure")
        return jsonify({"error": "Unable to delete product", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


@app.get("/api/categories")
def get_categories():
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT DISTINCT category FROM products "
            "WHERE category IS NOT NULL AND category != '' "
            "ORDER BY category ASC"
        )
        rows = cursor.fetchall()
        categories = [row[0] for row in rows]
        trace_id, span_id = get_current_trace_context()
        logger.info("db.query.categories_success count=%d trace_id=%s span_id=%s", len(categories), trace_id, span_id)
        return jsonify(categories), 200
    except Exception:
        trace_id, span_id = get_current_trace_context()
        logger.exception("db.query.categories_failed trace_id=%s span_id=%s", trace_id, span_id)
        return jsonify({"error": "Unable to retrieve categories", "trace_id": trace_id}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


if __name__ == "__main__":
    app.run(host=ServerConfig.HOST, port=ServerConfig.PORT, debug=ServerConfig.DEBUG)
