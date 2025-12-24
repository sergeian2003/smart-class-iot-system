from flask import Flask, request, jsonify, render_template 
import sqlite3
import os
from datetime import datetime

app = Flask(__name__)
# If the folder 'data' doesn't exist (running locally without docker), it saves in current dir
if os.path.exists('/app/data'):
    DB_NAME = "/app/data/smart_class.db"
else:
    DB_NAME = "smart_class.db"

# --- Database Initialization ---
def init_db():
    """Initializes the SQLite database and creates the table if it doesn't exist."""
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS sensor_data
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  classroom_id TEXT,
                  temperature REAL,
                  light_level INTEGER,
                  motion_detected INTEGER,
                  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    conn.commit()
    conn.close()
    print(f"[INFO] Database {DB_NAME} initialized.")
   
# --- Web Interface --- 
@app.route('/')
def index():
    return render_template('index.html')

# --- API Endpoint: Receive Data ---
@app.route('/api/data', methods=['POST'])
def receive_data():
    """Receives sensor data from Wemos D1 Mini via JSON."""
    try:
        data = request.json
        classroom_id = data.get('classroom_id')
        temp = data.get('temperature')
        light = data.get('light')
        motion = data.get('motion')

        # Save to Database
        conn = sqlite3.connect(DB_NAME)
        c = conn.cursor()
        c.execute("INSERT INTO sensor_data (classroom_id, temperature, light_level, motion_detected) VALUES (?, ?, ?, ?)",
                  (classroom_id, temp, light, motion))
        conn.commit()
        conn.close()

        print(f"[DATA RECEIVED] {classroom_id} | Temp: {temp}°C | Light: {light} | Motion: {motion}")
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"[ERROR] {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

# --- API Endpoint: Get Latest Data (For Testing/Debugging) ---
@app.route('/api/latest', methods=['GET'])
def get_latest():
    """Returns the last 10 records from the database."""
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT * FROM sensor_data ORDER BY id DESC LIMIT 10")
    rows = c.fetchall()
    conn.close()
    return jsonify(rows)

if __name__ == '__main__':
    init_db()
    # Run on all interfaces (0.0.0.0) on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)