import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/models/emergency_event.dart';
import 'package:safepath/models/esp32_config.dart';
import 'package:safepath/models/stick_sensor_data.dart';
import 'package:safepath/models/user_profile.dart';
import 'package:safepath/services/backend_service.dart';

void main() {
  group('StickSensorData Tests', () {
    test('Correctly calculates obstacle severity from distance', () {
      final clearData = StickSensorData.fromJson({'distance_cm': 150.0});
      expect(clearData.obstacleSeverity, ObstacleSeverity.clear);

      final warningData = StickSensorData.fromJson({'distance_cm': 85.0});
      expect(warningData.obstacleSeverity, ObstacleSeverity.warning);

      final dangerData = StickSensorData.fromJson({'distance_cm': 25.0});
      expect(dangerData.obstacleSeverity, ObstacleSeverity.danger);
    });

    test('Correctly parses surface hazard and moisture levels', () {
      final dryData = StickSensorData.fromJson({'distance_cm': 120.0, 'moisture': 5.0});
      expect(dryData.surfaceHazard, SurfaceHazardType.normalDry);

      final puddleData = StickSensorData.fromJson({
        'distance_cm': 120.0,
        'moisture': 75.0,
        'surface_hazard': 'water',
      });
      expect(puddleData.surfaceHazard, SurfaceHazardType.waterPuddle);

      final dropData = StickSensorData.fromJson({
        'distance_cm': 250.0,
        'surface_hazard': 'pothole',
      });
      expect(dropData.surfaceHazard, SurfaceHazardType.potholeOrDrop);
    });

    test('Correctly identifies fall detection from MPU6050 JSON payload', () {
      final fallData = StickSensorData.fromJson({
        'fall_detected': true,
        'ax': 28.5,
        'ay': 1.0,
        'az': 7.2,
      });
      expect(fallData.fallDetected, isTrue);
      expect(fallData.ax, 28.5);
    });
  });

  group('EmergencyEvent Lifecycle Tests', () {
    test('Emergency event lifecycle transitions correctly', () {
      final event = EmergencyEvent(
        id: 'test-event-101',
        type: EmergencyType.sosManual,
        status: EmergencyStatus.triggered,
        timestamp: DateTime.now(),
        latitude: 28.6139,
        longitude: 77.2090,
      );

      expect(event.isActive, isTrue);
      expect(event.typeDisplayName, 'Manual SOS Alarm');
      expect(event.statusDisplayName, 'Alert Triggered');

      final ackEvent = event.copyWith(
        status: EmergencyStatus.acknowledged,
        acknowledgedBy: 'Caregiver Sarah',
        acknowledgedAt: DateTime.now(),
      );
      expect(ackEvent.isActive, isTrue);
      expect(ackEvent.acknowledgedBy, 'Caregiver Sarah');
      expect(ackEvent.statusDisplayName, 'Caregiver Acknowledged');

      final respondingEvent = ackEvent.copyWith(
        status: EmergencyStatus.responding,
        respondingBy: 'Caregiver Sarah',
        respondingAt: DateTime.now(),
      );
      expect(respondingEvent.isActive, isTrue);
      expect(respondingEvent.statusDisplayName, 'Caregiver Responding');

      final resolvedEvent = respondingEvent.copyWith(
        status: EmergencyStatus.resolved,
        resolvedAt: DateTime.now(),
        resolutionNotes: 'Assistance completed, user safe.',
      );
      expect(resolvedEvent.isActive, isFalse);
      expect(resolvedEvent.statusDisplayName, 'Resolved & Safe');
    });

    test('EmergencyEvent JSON roundtrip serialization works', () {
      final original = EmergencyEvent(
        id: 'json-test-1',
        type: EmergencyType.fallDetected,
        status: EmergencyStatus.notificationSent,
        timestamp: DateTime.parse('2026-10-04T12:00:00Z'),
        latitude: 37.7749,
        longitude: -122.4194,
        accuracyMeters: 8.5,
        batteryPercent: 90,
        notes: 'Simulated fall test',
      );

      final json = original.toJson();
      final reconstructed = EmergencyEvent.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.type, original.type);
      expect(reconstructed.status, original.status);
      expect(reconstructed.latitude, original.latitude);
      expect(reconstructed.longitude, original.longitude);
      expect(reconstructed.notes, original.notes);
    });
  });

  group('UserProfile & Esp32Config Tests', () {
    test('Default user profile has valid contacts', () {
      final profile = UserProfile.defaultUser();
      expect(profile.contacts.isNotEmpty, isTrue);
      expect(profile.contacts.any((c) => c.isPrimary), isTrue);
    });

    test('Esp32Config generates correct HTTP and WebSocket URLs', () {
      const config = Esp32Config(
        ipAddress: '192.168.1.150',
        port: 8080,
        endpointPath: '/data',
        webSocketPort: 8081,
      );

      expect(config.httpUrl, 'http://192.168.1.150:8080/data');
      expect(config.wsUrl, 'ws://192.168.1.150:8081/ws');
    });
  });

  group('Mock Cloud Backend Tests', () {
    test('Mock backend publishes emergency and notifies subscribers', () async {
      final backend = MockCloudBackendService();
      final event = EmergencyEvent(
        id: 'backend-test-1',
        type: EmergencyType.sosManual,
        status: EmergencyStatus.triggered,
        timestamp: DateTime.now(),
      );

      bool received = false;
      final sub = backend.activeEmergencyStream.listen((ev) {
        if (ev?.id == event.id) {
          received = true;
        }
      });

      await backend.publishEmergency(event);
      expect(backend.currentActiveEmergency?.id, event.id);
      expect(backend.currentActiveEmergency?.status, EmergencyStatus.notificationSent);

      await Future.delayed(const Duration(milliseconds: 50));
      expect(received, isTrue);
      await sub.cancel();
    });
  });
}
