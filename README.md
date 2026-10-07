# SafePath — Smart Blind Stick Companion & Caregiver Safety Network

**SafePath** is a production-grade, accessible Android application engineered to serve as the intelligent companion for a Smart Blind Stick equipped with ultrasonic obstacle sensing (HC-SR04), fall detection (MPU6050 6-DOF IMU), surface hazard/puddle sensing, phone GPS tracking, and instantaneous caregiver emergency dispatch.

---

## 🌟 Key Features

### 🦯 For Visually Impaired Users
- **Accessible Design**: Material 3 interface with WCAG AAA high contrast, large touch targets (min 58px), dark & light modes, and full TalkBack screen reader support with semantic labels.
- **Voice Guidance & Speech Queue**: Real-time Text-to-Speech announcements for obstacle proximity, surface conditions, battery status, and emergency triggers.
- **Obstacle Proximity Warnings**: Live distance monitoring with 3-tier severity (Clear Path > 100cm, Approaching Warning 40-100cm, Imminent Danger < 40cm).
- **Surface Hazard Detection**: Distinguishes normal dry terrain, wet puddles/water hazards, steep drops/potholes, and muddy ground.
- **MPU6050 Fall Detection & False Alarm Window**: Automatic fall trigger with a 5-second voice countdown and tactile buzzing allowing false alarm cancellation.
- **Prominent Emergency SOS**: Big accessible SOS button with safety confirmation and instant GPS coordinate broadcast.
- **Phone GPS Integration**: High-accuracy GPS location retrieval, accuracy radius, and OpenStreetMap view.

### 🛡️ For Caregivers
- **Monitored User Profile**: Access user medical notes, blood group, emergency contacts, and phone dialer.
- **Live Safety Telemetry**: Real-time stick battery, sensor snapshot, and connection status.
- **Interactive OpenStreetMap Radar**: Live user location tracking with 1-tap navigation launch in Google Maps or default GPS app.
- **Emergency Dispatch Workflow**: Complete 6-stage lifecycle:
  `Triggered` ➔ `Notification Sent` ➔ `Acknowledged` ➔ `Responding (En Route)` ➔ `Assistance Coordinated` ➔ `Resolved & Safe`
- **Emergency History & Logs**: Filterable timeline of all past alarms, sensor snapshots at trigger instant, and resolution notes.

---

## 🛠️ Architecture Overview

```
lib/
├── constants/           # High contrast colors (AppColors), semantic strings (AppStrings), Accessible themes (AppTheme)
├── models/              # StickSensorData, EmergencyEvent, UserProfile, Esp32Config
├── services/
│   ├── storage_service.dart      # SharedPreferences local persistence
│   ├── location_service.dart     # Phone GPS geolocator & continuous position stream
│   ├── hardware_service.dart     # ESP32 Wi-Fi HTTP / WebSocket client & Smart Stick simulator
│   ├── tts_audio_service.dart    # Text-to-Speech & haptic feedback patterns
│   ├── notification_service.dart # Android high-priority emergency notification channels
│   ├── backend_service.dart      # Backend repository (Local Mock Broadcast + Firebase ready)
│   └── emergency_service.dart    # Emergency coordinator & 5s false alarm countdown
├── providers/
│   ├── app_state_provider.dart   # Master reactive state provider
│   └── settings_provider.dart    # Preferences, contacts, hardware config
├── widgets/                      # AccessibleButton, SosEmergencyButton, SensorStatusCard, LiveMapView, etc.
└── screens/                      # UserDashboardScreen, CaregiverDashboardScreen, EmergencyDetailsScreen, etc.
```

---

## 🧪 ESP32 Hardware Integration & Simulation

- **Physical Mode**: Communicates over local Wi-Fi with the ESP32 stick using HTTP GET (`http://192.168.4.1/sensors`) or WebSockets. Includes auto-reconnect and timeout handling.
- **Simulation Mode**: Built-in realistic hardware simulator generating smooth sensor physics for offline testing:
  - 🚶 Normal Walk
  - ⚠️ Approaching Obstacle (90cm)
  - 🚨 Close Danger Obstacle (22cm)
  - 💧 Water Puddle Detection
  - 🕳️ Steep Drop / Pothole
  - 💥 Fall Detection Alarm (MPU6050 acceleration spike + gravity vector shift)
  - 🪫 Low Battery Alert

---

## 🚀 Building & Testing

### Run Tests:
```bash
flutter test
```

### Build Android Debug APK:
```bash
flutter build apk --debug
```
The resulting APK is generated at:
`build/app/outputs/flutter-apk/app-debug.apk`
