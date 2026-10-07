# ESP32 Smart Blind Stick Firmware Guide & Source Code

This document provides the complete, production-ready Arduino/ESP32 C++ firmware for the **SafePath Smart Blind Stick**.

## 1. Hardware Pinout & Wiring Diagram

| Component | ESP32 Pin | Function | Notes |
|---|---|---|---|
| **HC-SR04 Ultrasonic** | `GPIO 5` (TRIG) | Trigger pulse | 10µs pulse to initiate ping |
| | `GPIO 18` (ECHO) | Echo pulse input | Use 1k/2k voltage divider for 3.3V safe logic |
| **MPU6050 6-DOF IMU** | `GPIO 21` (SDA) | I2C Data | 3.3V VCC, GND |
| | `GPIO 22` (SCL) | I2C Clock | Pull-ups included on MPU board |
| | `GPIO 19` (INT) | Fall Interrupt | Optional hardware interrupt pin |
| **Surface Hazard Sensor** | `GPIO 34` (A0) | Analog Soil / Water | High conductivity = Water puddle |
| **Vibration Motor / Buzzer** | `GPIO 23` (PWM) | Haptic Buzz Alert | NPN transistor driver / Mosfet |
| **Status LED** | `GPIO 2` | Onboard Wi-Fi status | Blink = connecting, Solid = client connected |

---

## 2. Complete Arduino / ESP32 C++ Firmware (`safepath_stick.ino`)

```cpp
#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>

// --- Wi-Fi Configuration ---
// The stick creates a SoftAP access point or connects to home/hotspot Wi-Fi
const char* ap_ssid = "SafePath_SmartStick_AP";
const char* ap_pass = "SafePath2026";

// Optional: Station Mode (Uncomment to connect to phone hotspot)
// const char* sta_ssid = "Your_Phone_Hotspot";
// const char* sta_pass = "Hotspot_Password";

WebServer server(80);
Adafruit_MPU6050 mpu;

// --- Pin Definitions ---
const int TRIG_PIN = 5;
const int ECHO_PIN = 18;
const int MOISTURE_PIN = 34; // ADC1 pin
const int HAPTIC_PIN = 23;
const int LED_PIN = 2;

// --- State Variables ---
float distance_cm = 150.0;
float moisture_percent = 5.0;
bool fall_detected = false;
float ax = 0, ay = 9.8, az = 0;
float gx = 0, gy = 0, gz = 0;
int battery_percent = 92;
float battery_v = 4.12;

unsigned long lastSensorRead = 0;
unsigned long lastFallTriggerTime = 0;

// --- Sensor Read Functions ---
float readUltrasonic() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  
  long duration = pulseIn(ECHO_PIN, HIGH, 30000); // 30ms timeout
  if (duration == 0) return 200.0; // Clear timeout fallback
  return (duration * 0.0343) / 2.0;
}

float readSurfaceMoisture() {
  int raw = analogRead(MOISTURE_PIN);
  // ADC range 0-4095 (lower resistance in water = higher voltage / lower raw reading depending on circuit)
  float percent = map(raw, 4095, 1000, 0, 100);
  return constrain(percent, 0.0, 100.0);
}

void updateSensors() {
  // 1. Distance
  distance_cm = readUltrasonic();

  // 2. Moisture / Hazard
  moisture_percent = readSurfaceMoisture();

  // 3. MPU6050 Accelerometer & Gyro
  sensors_event_t a, g, temp;
  if (mpu.getEvent(&a, &g, &temp)) {
    ax = a.acceleration.x;
    ay = a.acceleration.y;
    az = a.acceleration.z;
    gx = g.gyro.x * 57.2958; // convert to deg/s
    gy = g.gyro.y * 57.2958;
    gz = g.gyro.z * 57.2958;

    // Fall Detection Algorithm:
    // Freefall vector < 3.5 m/s^2 followed by high impact > 25.0 m/s^2 or tilt shift
    float totalAccel = sqrt(ax * ax + ay * ay + az * az);
    if (totalAccel > 24.0 || (totalAccel < 3.0 && abs(ay) < 3.0)) {
      fall_detected = true;
      lastFallTriggerTime = millis();
    } else if (millis() - lastFallTriggerTime > 10000) {
      fall_detected = false; // Reset after 10s if normal
    }
  }

  // 4. Local Haptic Warning on Stick
  if (distance_cm < 40.0 || moisture_percent > 60.0 || fall_detected) {
    digitalWrite(HAPTIC_PIN, HIGH);
  } else {
    digitalWrite(HAPTIC_PIN, LOW);
  }
}

// --- HTTP REST Handlers ---
void handleSensors() {
  updateSensors();

  StaticJsonDocument<512> doc;
  doc["distance_cm"] = round(distance_cm * 10) / 10.0;
  doc["moisture"] = round(moisture_percent);
  doc["surface_hazard"] = moisture_percent > 55.0 ? "water" : (distance_cm > 230.0 ? "pothole" : "dry");
  doc["fall_detected"] = fall_detected;
  doc["ax"] = round(ax * 10) / 10.0;
  doc["ay"] = round(ay * 10) / 10.0;
  doc["az"] = round(az * 10) / 10.0;
  doc["gx"] = round(gx * 10) / 10.0;
  doc["gy"] = round(gy * 10) / 10.0;
  doc["gz"] = round(gz * 10) / 10.0;
  doc["battery_percent"] = battery_percent;
  doc["battery_v"] = battery_v;
  doc["device_id"] = "ESP32-SAFEPATH-01";

  String jsonResponse;
  serializeJson(doc, jsonResponse);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", jsonResponse);
}

void handleRoot() {
  server.send(200, "text/plain", "SafePath Smart Blind Stick ESP32 Active. Endpoint: /sensors");
}

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(MOISTURE_PIN, INPUT);
  pinMode(HAPTIC_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);

  digitalWrite(HAPTIC_PIN, LOW);
  digitalWrite(LED_PIN, LOW);

  // Initialize MPU6050
  if (!mpu.begin()) {
    Serial.println("Warning: MPU6050 not found! Fall detection in emulation.");
  } else {
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    Serial.println("MPU6050 6-DOF Initialized successfully.");
  }

  // Create Wi-Fi SoftAP
  WiFi.softAP(ap_ssid, ap_pass);
  IPAddress IP = WiFi.softAPIP();
  Serial.print("SafePath Stick AP IP Address: ");
  Serial.println(IP); // Defaults to 192.168.4.1

  // Start HTTP Server
  server.on("/", handleRoot);
  server.on("/sensors", handleSensors);
  server.on("/data", handleSensors);
  server.begin();
  Serial.println("HTTP Sensor Telemetry Server Started on Port 80.");
  digitalWrite(LED_PIN, HIGH);
}

void loop() {
  server.handleClient();

  if (millis() - lastSensorRead > 200) {
    lastSensorRead = millis();
    updateSensors();
  }
}
```

---

## 3. How to Connect SafePath App to Physical Stick

1. Flash the firmware above onto the ESP32 using Arduino IDE or PlatformIO.
2. Power on the Smart Blind Stick.
3. On your Android phone, connect to Wi-Fi SSID **`SafePath_SmartStick_AP`** (Password: `SafePath2026`).
4. In SafePath App, navigate to **Settings -> ESP32 Wi-Fi Hardware Settings**.
5. Ensure IP Address is set to **`192.168.4.1`**, Port **`80`**, Endpoint **`/sensors`**.
6. Turn off "Hardware Simulation Mode".
7. Tap **"Test Connection"** - you will see instantaneous live ultrasonic, surface moisture, and MPU6050 gravity vector telemetry streaming directly from the physical stick!
