from bottle import Bottle, run, request, static_file, template
from mysql.connector import connect

app = Bottle()


def get_movie(movie_id):
    db = connect(
        host="web3.kinet.ch",
        user="omdb_user",
        password="QhPSNctsBRgsYOKEbASI",
        database="omdb",
    )
    cursor = db.cursor(dictionary=True)

    cursor.execute(
        "SELECT m.id, m.name, m.kind, m.date, YEAR(m.date) AS year, "
        "m.vote_average, m.runtime, a.text "
        "FROM movies m LEFT JOIN abstracts a ON a.movie_id = m.id "
        "WHERE m.id = %s",
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
            "WHERE c.movie_id = %s AND jn.name = 'Actor' AND jn.language = 'en' "
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

    cursor.close()
    db.close()
    return movie, cast, trailer


def search_shows(query):
    db = connect(
        host="web3.kinet.ch",
        user="omdb_user",
        password="QhPSNctsBRgsYOKEbASI",
        database="omdb",
    )
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


@app.route("/static/<filepath:path>")
def serve_static(filepath):
    return static_file(filepath, root="static")


if __name__ == "__main__":
    run(app, host="localhost", port=8080, debug=True, reloader=True)
