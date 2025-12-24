import sqlite3
from flask import Flask, request, jsonify, render_template
import os

app = Flask(__name__)

# Database path handling
if os.path.exists('/app/data'):
    DB_NAME = "/app/data/smart_class.db"
else:
    DB_NAME = "smart_class.db"

def init_db():
    """Initializes the DB with sensor history AND current state tables."""
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    
    # 1. History Table (Sensor Data)
    c.execute('''CREATE TABLE IF NOT EXISTS sensor_data
                 (id INTEGER PRIMARY KEY AUTOINCREMENT,
                  classroom_id TEXT,
                  temperature REAL,
                  light_level INTEGER,
                  motion_detected INTEGER,
                  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')

    # 2. State Table (Current Status for Control)
    c.execute('''CREATE TABLE IF NOT EXISTS classroom_state
                 (classroom_id TEXT PRIMARY KEY,
                  light_status TEXT DEFAULT 'OFF',  -- ON, OFF
                  mode TEXT DEFAULT 'AUTO',         -- AUTO, MANUAL
                  last_temp REAL DEFAULT 0,
                  last_lux INTEGER DEFAULT 0,
                  last_motion INTEGER DEFAULT 0)''')
    
    # Pre-populate classes 101, 102, 103 if not exist
    classes = ['Class 101', 'Class 102', 'Class 103']
    for cls in classes:
        c.execute("INSERT OR IGNORE INTO classroom_state (classroom_id) VALUES (?)", (cls,))
    
    conn.commit()
    conn.close()
    print(f"[INFO] Database initialized with State table.")

# --- API: Receive Data from Sensors ---
@app.route('/api/data', methods=['POST'])
def receive_data():
    try:
        data = request.json
        # Normalize classroom_id (e.g., "CLASS_101" -> "Class 101") if needed
        # For this demo, we assume Wemos sends "Class 101" or similar
        cid = data.get('classroom_id', 'Class 101') 
        temp = data.get('temperature', 0)
        light = data.get('light', 0)
        motion = data.get('motion', 0)

        conn = sqlite3.connect(DB_NAME)
        c = conn.cursor()
        
        # 1. Log history
        c.execute("INSERT INTO sensor_data (classroom_id, temperature, light_level, motion_detected) VALUES (?, ?, ?, ?)",
                  (cid, temp, light, motion))
        
        # 2. Update current state (Sensors only, preserve Mode)
        # We only update temp/lux/motion here. Light status depends on Logic.
        c.execute('''UPDATE classroom_state 
                     SET last_temp = ?, last_lux = ?, last_motion = ?
                     WHERE classroom_id = ?''', (temp, light, motion, cid))
        
        # (Optional) Simple Logic: If AUTO, update Light Status based on Motion
        c.execute("SELECT mode FROM classroom_state WHERE classroom_id = ?", (cid,))
        row = c.fetchone()
        if row and row[0] == 'AUTO':
            new_status = 'ON' if motion == 1 else 'OFF'
            c.execute("UPDATE classroom_state SET light_status = ? WHERE classroom_id = ?", (new_status, cid))

        conn.commit()
        conn.close()
        return jsonify({"status": "success"}), 200
    except Exception as e:
        print(f"[ERROR] {e}")
        return jsonify({"status": "error"}), 500

# --- API: Control Lights (Web/App buttons) ---
@app.route('/api/control', methods=['POST'])
def control_light():
    """Handle buttons: Light ON, Light OFF, Reset to AUTO"""
    data = request.json
    cid = data.get('classroom_id')
    action = data.get('action') # 'ON', 'OFF', 'AUTO'

    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()

    if action == 'AUTO':
        c.execute("UPDATE classroom_state SET mode = 'AUTO' WHERE classroom_id = ?", (cid,))
    else:
        # If Manual ON/OFF, set mode to MANUAL
        c.execute("UPDATE classroom_state SET mode = 'MANUAL', light_status = ? WHERE classroom_id = ?", (action, cid))

    conn.commit()
    conn.close()
    return jsonify({"status": "updated", "action": action})

# --- API: Get All States (For Web Dashboard) ---
@app.route('/api/status', methods=['GET'])
def get_status():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    c.execute("SELECT * FROM classroom_state")
    rows = [dict(row) for row in c.fetchall()]
    conn.close()
    return jsonify(rows)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
