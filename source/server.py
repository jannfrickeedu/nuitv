import json
import os
import random
from decimal import Decimal
from bottle import Bottle, run, request, response, static_file, template
from mysql.connector.pooling import MySQLConnectionPool
from dotenv import load_dotenv


class _Encoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)


def to_json(obj):
    return json.dumps(obj, cls=_Encoder)


app = Bottle()

load_dotenv()
HOST = os.getenv("NUITV_DB_HOST", "web3.kinet.ch")
USER = os.getenv("NUITV_DB_USER", "omdb_user")
PASSWORD = os.getenv("NUITV_DB_PASSWORD")
DATABASE = os.getenv("NUITV_DB_NAME", "omdb")

pool = None
pool_error = None

pool = MySQLConnectionPool(
    pool_name="nuitv",
    pool_size=3,
    host=HOST,
    user=USER,
    password=PASSWORD,
    database=DATABASE,
)

def get_movie(movie_id):
    db = pool.get_connection()
    cursor = db.cursor(dictionary=True)

    cursor.execute(
        "SELECT m.id, m.name, m.kind, m.date, YEAR(m.date) AS year, "
        "m.vote_average, m.runtime, a.text "
        "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
        "WHERE m.id = %s",
        (movie_id,),
    )
    movie = cursor.fetchone()

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
        cast = cursor.fetchall()

        cursor.execute(
            "SELECT `key` FROM trailers WHERE movie_id = %s AND source = 'youtube' LIMIT 1",
            (movie_id,),
        )
        row = cursor.fetchone()
        if row:
            trailer = row["key"]

    cursor.close()
    db.close()
    return movie, cast, trailer


def search_shows(query):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT m.id, m.name, m.kind, YEAR(m.date) AS year, m.vote_average, a.text "
        "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
        "WHERE m.name LIKE %s AND m.kind IN ('movie', 'series') LIMIT 20",
        (f"%{query}%",),
    )
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results


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
        return template("detail", movie=None, cast=[], trailer=None, error=str(e))
    return template("detail", movie=movie, cast=cast, trailer=trailer, error=None)


def get_random_movies(limit=10):
    db = pool.get_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute(
        "SELECT COUNT(*) AS cnt FROM movies m "
        "INNER JOIN abstracts a ON a.movie_id = m.id "
        "WHERE m.kind IN ('movie', 'series') AND a.text IS NOT NULL"
    )
    total = cursor.fetchone()["cnt"]
    offset = random.randint(0, max(0, total - limit))
    cursor.execute(
        "SELECT m.id, m.name, m.kind, YEAR(m.date) AS year, m.vote_average, a.text "
        "FROM movies m INNER JOIN abstracts a ON a.movie_id = m.id "
        "WHERE m.kind IN ('movie', 'series') AND a.text IS NOT NULL "
        "LIMIT %s OFFSET %s",
        (limit, offset),
    )
    movies = cursor.fetchall()
    cursor.close()
    db.close()
    return movies


@app.route("/swipe")
def swipe():
    movies = get_random_movies(10)
    return template("swipe", initial_movies=to_json(movies))


@app.route("/api/random")
def random_movies():
    response.content_type = "application/json"
    return to_json(get_random_movies(10))


@app.route("/static/<filepath:path>")
def serve_static(filepath):
    return static_file(filepath, root="static")


if __name__ == "__main__":
    run(app, host="localhost", port=8080, debug=True, reloader=True)
