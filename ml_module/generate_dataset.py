import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

def generate_smart_class_data(days=30):
    """
    Generates a synthetic dataset representing classroom environment data.
    Useful for training ML models when real historical data is scarce.
    """
    start_date = datetime.now() - timedelta(days=days)
    data = []

    current_time = start_date
    while current_time < datetime.now():
        # Determine time of day
        hour = current_time.hour
        is_day = 8 <= hour <= 18
        is_class_time = 9 <= hour <= 16

        # 1. Temperature Simulation
        # Base temperature is higher during the day and when students are present
        base_temp = 20
        if is_day: base_temp += 3
        if is_class_time: base_temp += random.uniform(1, 3)
        temp = base_temp + random.uniform(-1, 1)

        # 2. Light Level Simulation (Lux)
        if is_day:
            light = random.uniform(300, 800) # Natural daylight
        else:
            # At night, lights are usually off, but sometimes left on accidentally
            if random.random() > 0.95: # 5% chance lights were forgotten
                light = random.uniform(300, 400)
            else:
                light = random.uniform(0, 50)

        # 3. Motion Detection Simulation
        if is_class_time:
            motion = 1 if random.random() > 0.2 else 0 # High activity during class
        else:
            motion = 1 if random.random() > 0.9 else 0 # Rare activity at night (security/cleaning)

        # 4. Energy Consumption Calculation (Target Variable for ML)
        # Simplified logic: Lighting + AC usage
        energy_consumption = 0
        if light > 100: energy_consumption += 0.5 # Lights are ON
        if temp > 24: energy_consumption += 1.5 # Air Conditioning is likely ON

        data.append({
            "timestamp": current_time,
            "temperature": round(temp, 1),
            "light_level": int(light),
            "motion": motion,
            "energy_kwh": round(energy_consumption, 2)
        })

        # Data interval: 15 minutes
        current_time += timedelta(minutes=15)

    # Save to CSV
    filename = "smart_class_history.csv"
    df = pd.DataFrame(data)
    df.to_csv(filename, index=False)
    print(f"[SUCCESS] Generated {len(df)} records. Saved to {filename}")

if __name__ == "__main__":
    generate_smart_class_data()