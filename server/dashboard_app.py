import streamlit as st
import pandas as pd
import sqlite3
import time
import os

# Database path (same as in app.py)
if os.path.exists('/app/data'):
    DB_NAME = "/app/data/smart_class.db"
else:
    DB_NAME = "smart_class.db"

st.set_page_config(page_title="Smart Class Analytics", layout="wide")

st.title("📊 Smart Class Analytics App")

# Function to load data
def load_data():
    conn = sqlite3.connect(DB_NAME)
    # Read the last 100 records
    df = pd.read_sql_query("SELECT * FROM sensor_data ORDER BY id DESC LIMIT 100", conn)
    conn.close()
    return df

# Create placeholders for auto-refresh
placeholder = st.empty()

while True:
    df = load_data()
    
    with placeholder.container():
        if not df.empty:
            # KPI Metrics
            latest = df.iloc[0]
            col1, col2, col3 = st.columns(3)
            col1.metric("Temperature", f"{latest['temperature']} °C")
            col2.metric("Light Level", f"{latest['light_level']}")
            
            motion_text = "Yes" if latest['motion_detected'] == 1 else "No"
            col3.metric("Motion Detected", motion_text)

            # Charts
            st.subheader("Temperature & Light History")
            st.line_chart(df[['temperature', 'light_level']])
            
            st.subheader("Raw Data")
            st.dataframe(df)
        else:
            st.warning("Waiting for data...")

    # Update every 2 seconds
    time.sleep(2)