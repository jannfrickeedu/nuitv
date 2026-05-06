from bottle import Bottle, run, request, static_file, template
from mysql.connector import connect

app = Bottle()


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


@app.route("/static/<filepath:path>")
def serve_static(filepath):
    return static_file(filepath, root="static")


if __name__ == "__main__":
    run(app, host="localhost", port=8080, debug=True, reloader=True)
