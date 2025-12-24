# 🏫 Smart Class Energy Optimization System

![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)
![Python](https://img.shields.io/badge/Python-3.9-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Docker](https://img.shields.io/badge/Deploy-Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![C++](https://img.shields.io/badge/Firmware-C++-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Hardware](https://img.shields.io/badge/Hardware-ESP8266-000000?style=for-the-badge&logo=arduino&logoColor=white)

## 📖 Overview

**Smart Class** is a comprehensive Full-Stack IoT ecosystem designed to monitor, analyze, and optimize energy consumption in educational environments.

The system solves the problem of energy waste (lights/AC left on) by providing real-time monitoring through distributed sensors, a centralized server for data processing, and multi-platform client applications.

### 🌟 Key Features
* **Real-time Monitoring:** Tracks Temperature, Light levels, and Motion.
* **Cross-Platform Mobile App:** Built with Flutter (Android/iOS).
* **Web Dashboard:** User-friendly interface for quick status checks.
* **Data Analytics:** Specialized Streamlit dashboard for historical data analysis.
* **Scalable Architecture:** Dockerized backend ensuring easy deployment on Raspberry Pi or Cloud.

---

## 🏗 System Architecture

The project is divided into three main layers:

1.  **Hardware Layer (Edge):**
    * **Device:** Wemos D1 Mini (ESP8266).
    * **Sensors:** DHT11 (Temperature), PIR (Motion), LDR (Light).
    * **Protocol:** HTTP/JSON over Wi-Fi.

2.  **Server Layer (Backend):**
    * **Tech Stack:** Python, Flask, SQLite.
    * **Deployment:** Docker & Docker Compose.
    * **Services:** REST API + Web Dashboard + Streamlit App.

3.  **Client Layer (Frontend):**
    * **Mobile:** Flutter App for remote monitoring.
    * **Web:** HTML/JS Dashboard & Streamlit Analytics.

---

## 📂 Project Structure

```text
smart-class-system/
├── firmware/                 # C++ code for Wemos D1 Mini (Arduino Framework)
├── server/                   # Backend services
│   ├── app.py                # Flask REST API & Web Server
│   ├── dashboard_app.py      # Streamlit Analytics Dashboard
│   ├── Dockerfile            # Container configuration
│   └── docker-compose.yml    # Orchestration for API + Streamlit
└── mobile_app/               # Flutter source code
    └── lib/main.dart         # Main mobile application logic
