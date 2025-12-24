#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClient.h>
#include <DHT.h>  // Library for temperature sensor

// ================= NETWORK SETTINGS =================
const char* ssid = "YOUR_WIFI_NAME";         // <-- WiFi name
const char* password = "YOUR_WIFI_PASSWORD"; // <-- WiFi password

// IP address of your computer (where Docker is running)
// Example: "http://192.168.1.35:5000/api/data"
const char* serverUrl = "http://192.168.1.XX:5000/api/data"; 
const char* classroomId = "CLASS_101"; // Unique ID of your classroom

// ================= PINS AND SENSORS =================
#define PIN_DHT D4     // Temperature sensor (Data)
#define PIN_PIR D2     // Motion sensor (Out)
#define PIN_LDR A0     // Photoresistor (Analog Out)

// Select your sensor type (uncomment the needed line)
#define DHTTYPE DHT11   // Blue sensor
// #define DHTTYPE DHT22   // White sensor (more accurate)

// Initialize temperature sensor
DHT dht(PIN_DHT, DHTTYPE);

void setup() {
    Serial.begin(115200);
    delay(10);
    
    // Pin configuration
    pinMode(PIN_PIR, INPUT); // Motion - input
    // A0 does not need configuration, it's always INPUT
    
    // Start temperature sensor
    dht.begin();

    // Connect to WiFi
    Serial.println();
    Serial.print("[SETUP] Connecting to ");
    Serial.println(ssid);

    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println("\n[SETUP] WiFi connected!");
    Serial.print("[SETUP] IP address: ");
    Serial.println(WiFi.localIP());
}

void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        WiFiClient client;
        HTTPClient http;

        // --- 1. COLLECT DATA FROM SENSORS ---
        
        // Read temperature
        float temp = dht.readTemperature();
        // Check: if sensor is not connected or broken, returns "NaN" (Not a Number)
        if (isnan(temp)) {
            Serial.println("[ERROR] Failed to read from DHT sensor!");
            temp = 0.0; // Send 0 or last value to not break the graph
        }

        // Read light (value from 0 to 1024)
        // 0 = darkness, 1024 = bright light (depends on resistor)
        int light = analogRead(PIN_LDR);

        // Read motion (HIGH = motion detected, LOW = no motion)
        int motion = digitalRead(PIN_PIR);

        // --- 2. FORM JSON ---
        // Output to console for verification before sending
        Serial.print("[SENSORS] T: "); Serial.print(temp);
        Serial.print(" | Light: "); Serial.print(light);
        Serial.print(" | Motion: "); Serial.println(motion);

        String jsonPayload = "{";
        jsonPayload += "\"classroom_id\": \"" + String(classroomId) + "\",";
        jsonPayload += "\"temperature\": " + String(temp) + ",";
        jsonPayload += "\"light\": " + String(light) + ",";
        jsonPayload += "\"motion\": " + String(motion);
        jsonPayload += "}";

        // --- 3. SEND TO SERVER ---
        http.begin(client, serverUrl);
        http.addHeader("Content-Type", "application/json");

        int httpResponseCode = http.POST(jsonPayload);

        if (httpResponseCode > 0) {
            Serial.print("[SUCCESS] Data sent. Code: ");
            Serial.println(httpResponseCode);
        } else {
            Serial.print("[ERROR] Send failed. Code: ");
            Serial.println(httpResponseCode);
        }
        http.end();

    } else {
        Serial.println("[ERROR] WiFi not connected");
    }

    // Pause for 10 seconds (no need to send too frequently)
    delay(10000);
}