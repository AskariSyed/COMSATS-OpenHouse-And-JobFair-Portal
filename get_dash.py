import sqlite3

conn = sqlite3.connect('/home/askari/jobfair-observability/grafana-data/grafana.db')
conn.text_factory = lambda b: b.decode(errors='ignore')
c = conn.cursor()
c.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = c.fetchall()

found = False
for t in tables:
    table = t[0]
    c.execute(f"PRAGMA table_info({table})")
    cols = [col[1] for col in c.fetchall()]
    
    for col in cols:
        query = f"SELECT {col} FROM {table} WHERE CAST({col} AS TEXT) LIKE '%Backend Requests / Minute%' LIMIT 1"
        try:
            c.execute(query)
            res = c.fetchone()
            if res:
                print(f"FOUND IN TABLE {table}, COLUMN {col}")
                print("CONTENT:", res[0])
                found = True
        except Exception as e:
            pass

if not found:
    print("Not found in any table")
