# SafePath Firebase Cloud Integration & Architecture Guide

SafePath is built using a clean Repository/Backend service pattern (`lib/services/backend_service.dart`).
Out of the box, SafePath operates with **Zero External Dependencies** using its robust **Local Development & Reactive Stream Repository**.

When you are ready to connect to production Google Firebase Cloud services, follow this guide.

---

## 1. Firebase Services Utilized

| Service | Purpose | Free Tier Compatibility |
|---|---|---|
| **Cloud Firestore** | Real-time bi-directional sync of active emergencies, sensor telemetry, and caregiver acknowledgments | Generous 50,000 reads / 20,000 writes/day |
| **Firebase Cloud Messaging (FCM)** | Remote push notifications to caregiver devices when blind stick triggers SOS or fall detection | 100% Free / Unlimited |
| **Firebase Authentication** | User & Caregiver login (Email/Password, Phone OTP, Google Sign-in) | Unlimited free phone auth up to 10k/mo |

---

## 2. Cloud Firestore Database Schema

### Collection: `emergencies`
Document ID: `{emergencyId}` (UUID v4)
```json
{
  "id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
  "userId": "user-001",
  "userName": "Alex Mercer",
  "type": "sosManual | fallDetected | severeHazard | stickDisconnectedEmergency",
  "status": "triggered | notificationSent | acknowledged | responding | assistanceCoordinated | resolved | cancelled",
  "timestamp": "2026-10-04T12:00:00.000Z",
  "latitude": 28.6139,
  "longitude": 77.2090,
  "accuracyMeters": 12.5,
  "addressLabel": "Near Main St & 4th Ave",
  "batteryPercent": 88,
  "notes": "Fall detected by MPU6050 accelerometer",
  "acknowledgedBy": "Sarah Mercer",
  "acknowledgedAt": "2026-10-04T12:00:15.000Z",
  "respondingBy": "Sarah Mercer",
  "respondingAt": "2026-10-04T12:00:45.000Z",
  "resolvedAt": null,
  "resolutionNotes": null,
  "sensorSnapshot": {
    "distance_cm": 22.0,
    "surface_hazard": "waterPuddle",
    "moisture": 78.0,
    "fall_detected": true,
    "ax": 26.4,
    "ay": 1.2,
    "az": 8.0,
    "battery_v": 4.02
  }
}
```

### Collection: `users`
Document ID: `{userId}`
```json
{
  "id": "user-001",
  "name": "Alex Mercer",
  "phoneNumber": "+1-555-0199",
  "bloodGroup": "B+",
  "medicalNotes": "Moderate visual impairment. Uses SafePath Smart Stick.",
  "lastLocation": {
    "latitude": 28.6139,
    "longitude": 77.2090,
    "updatedAt": "2026-10-04T12:00:00.000Z"
  },
  "contacts": [
    {
      "id": "c-1",
      "name": "Sarah Mercer",
      "phoneNumber": "+1-555-0123",
      "relationship": "Sister & Primary Caregiver",
      "isPrimary": true,
      "fcmToken": "eXamPleFcmToken..."
    }
  ]
}
```

---

## 3. Step-by-Step Firebase Project Setup

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/).
   - Click **Add Project** and name it `SafePath`.

2. **Register Android App**:
   - Package name: `com.safepath.app.safepath`
   - Download `google-services.json` and place it in `android/app/google-services.json`.

3. **Install FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=safepath
   ```

4. **Add Firebase Packages to `pubspec.yaml`**:
   ```yaml
   dependencies:
     firebase_core: ^3.0.0
     firebase_auth: ^5.0.0
     cloud_firestore: ^5.0.0
     firebase_messaging: ^15.0.0
   ```

5. **Firestore Security Rules**:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /emergencies/{emergencyId} {
         allow read, write: if request.auth != null;
       }
       match /users/{userId} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```
