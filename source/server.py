import json
import os
import random
from datetime import date, datetime
from decimal import Decimal
from bottle import Bottle, run, request, response, static_file, template
from mysql.connector.pooling import MySQLConnectionPool
from dotenv import load_dotenv


class _Encoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return float(o)
        if isinstance(o, (date, datetime)):
            return o.isoformat()
        return super().default(o)


def to_json(obj):
    return json.dumps(obj, cls=_Encoder)


def to_script_json(obj):
    return (
        json.dumps(obj, cls=_Encoder)
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
        .replace("&", "\\u0026")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")
    )


app = Bottle()

load_dotenv()
HOST = os.getenv("NUITV_DB_HOST", "web3.kinet.ch")
USER = os.getenv("NUITV_DB_USER", "omdb_user")
PASSWORD = os.getenv("NUITV_DB_PASSWORD")
DATABASE = os.getenv("NUITV_DB_NAME", "omdb")

pool = None
pool_error = None


def init_pool():
    global pool, pool_error

    if pool is not None:
        return pool

    if not PASSWORD:
        pool_error = "NUITV_DB_PASSWORD is not set"
        return None

    try:
        pool = MySQLConnectionPool(
            pool_name="nuitv",
            pool_size=3,
            host=HOST,
            user=USER,
            password=PASSWORD,
            database=DATABASE,
        )
        pool_error = None
        return pool
    except Exception as e:
        pool_error = f"Database pool initialization failed: {e}"
        return None


def get_db_connection():
    active_pool = init_pool()
    if active_pool is None:
        raise RuntimeError(pool_error or "Database is not configured")

    try:
        return active_pool.get_connection()
    except Exception as e:
        raise RuntimeError(f"Database connection unavailable: {e}") from e


def get_movie(movie_id):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute(
            "SELECT m.id, m.name, m.kind, m.date, YEAR(m.date) AS year, "
            "m.vote_average, m.runtime, a.text "
            "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
            "WHERE m.id = %s AND vote_average IS NOT NULL ",
            (movie_id,),
        )
        movie = cursor.fetchone()

        cast = []
        trailer = None
        if movie:
            cursor.execute(
                "SELECT DISTINCT p.name, c.role FROM casts c "
                "JOIN people p ON p.id = c.person_id "
                "JOIN job_names jn ON jn.job_id = c.job_id "
                "WHERE c.movie_id = %s AND jn.name = 'Actor' AND jn.language = 'en' AND vote_average IS NOT NULL "
                "ORDER BY c.position LIMIT 15",
                (movie_id,),
            )
            cast = cursor.fetchall()

            cursor.execute(
                "SELECT `key` FROM trailers WHERE movie_id = %s AND source = 'youtube' LIMIT 1",
                (movie_id,),
            )
            row = cursor.fetchone()
            if row:
                trailer = row["key"]

        return movie, cast, trailer
    finally:
        cursor.close()
        db.close()


def search_shows(query):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT m.id, m.name, m.kind, YEAR(m.date) AS year, m.vote_average, a.text "
            "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
            "WHERE m.name LIKE %s AND m.kind IN ('movie', 'series') AND vote_average IS NOT NULL LIMIT 20",
            (f"%{query}%",),
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        db.close()


@app.route("/")
def index():
    query = request.query.get("q", "").strip()
    results = None
    error = None

    if query:
        try:
            results = search_shows(query)
        except Exception as e:
            error = str(e)

    return template("index", query=query, results=results, error=error)


@app.route("/movie/<movie_id:int>")
def movie_detail(movie_id):
    try:
        movie, cast, trailer = get_movie(movie_id)
    except Exception as e:
        return template(
            "detail",
            movie=None,
            cast=[],
            trailer=None,
            error=str(e),
            movie_json="null",
        )

    return template(
        "detail",
        movie=movie,
        cast=cast,
        trailer=trailer,
        error=None,
        movie_json=to_script_json(movie) if movie else "null",
    )


def get_random_movies(limit=10):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM movies m "
            "LEFT JOIN abstracts a ON a.movie_id = m.id "
            "WHERE m.kind IN ('movie', 'series') AND a.text IS NOT NULL AND vote_average IS NOT NULL"
        )
        total = cursor.fetchone()["cnt"]
        offset = random.randint(0, max(0, total - limit))
        cursor.execute(
            "SELECT m.id, m.name, m.kind, YEAR(m.date) AS year, m.vote_average, a.text "
            "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
            "WHERE m.kind IN ('movie', 'series') AND a.text IS NOT NULL AND vote_average IS NOT NULL "
            "LIMIT %s OFFSET %s",
            (limit, offset),
        )
        return cursor.fetchall()
    finally:
        cursor.close()
        db.close()


def get_movies_by_ids(ids):
    if not ids:
        return []

    normalized_ids = []
    for raw_id in ids:
        try:
            movie_id = int(raw_id)
        except (TypeError, ValueError):
            continue
        if movie_id not in normalized_ids:
            normalized_ids.append(movie_id)

    if not normalized_ids:
        return []

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    try:
        placeholders = ", ".join(["%s"] * len(normalized_ids))
        cursor.execute(
            "SELECT m.id, m.name, m.kind, YEAR(m.date) AS year, m.vote_average, a.text "
            "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
            f"WHERE m.id IN ({placeholders}) AND vote_average IS NOT NULL",
            tuple(normalized_ids),
        )
        rows = cursor.fetchall()
        by_id = {row["id"]: row for row in rows}
        return [by_id[movie_id] for movie_id in normalized_ids if movie_id in by_id]
    finally:
        cursor.close()
        db.close()


@app.route("/swipe")
def swipe():
    try:
        movies = get_random_movies(10)
    except Exception:
        movies = []
    return template("swipe", initial_movies_json=to_script_json(movies))


@app.route("/likes")
def likes_page():
    return template("likes")


@app.route("/api/random")
def random_movies():
    response.content_type = "application/json"
    try:
        return to_json(get_random_movies(10))
    except Exception:
        return to_json([])


@app.post("/api/movies/by-ids")
def movies_by_ids():
    response.content_type = "application/json"
    payload = request.json or {}
    ids = payload.get("ids", []) if isinstance(payload, dict) else []

    try:
        return to_json(get_movies_by_ids(ids))
    except Exception:
        return to_json([])


@app.route("/static/<filepath:path>")
def serve_static(filepath):
    return static_file(filepath, root="static")


if __name__ == "__main__":
    run(app, host="localhost", port=8080, debug=True, reloader=True)
