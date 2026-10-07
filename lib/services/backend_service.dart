import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_event.dart';
import '../models/stick_sensor_data.dart';

abstract class BackendService {
  Stream<EmergencyEvent?> get activeEmergencyStream;
  Stream<List<EmergencyEvent>> get emergencyHistoryStream;
  EmergencyEvent? get currentActiveEmergency;

  Future<bool> publishEmergency(EmergencyEvent event);
  Future<bool> updateEmergencyStatus({
    required String emergencyId,
    required EmergencyStatus newStatus,
    String? responderName,
    String? note,
  });
  Future<bool> cancelEmergency(String emergencyId, {String? reason});
  Future<bool> syncUserTelemetry({
    required String userId,
    required double latitude,
    required double longitude,
    required StickSensorData sensorData,
  });
}

/// Robust Local & Mock Cloud Backend for local testing, development, and offline mode.
/// Provides real-time reactive streams simulating Cloud Firestore listeners.
class MockCloudBackendService implements BackendService {
  final _activeEmergencyController = StreamController<EmergencyEvent?>.broadcast();
  final _historyController = StreamController<List<EmergencyEvent>>.broadcast();

  EmergencyEvent? _activeEmergency;
  final List<EmergencyEvent> _history = [];

  @override
  Stream<EmergencyEvent?> get activeEmergencyStream => _activeEmergencyController.stream;

  @override
  Stream<List<EmergencyEvent>> get emergencyHistoryStream => _historyController.stream;

  @override
  EmergencyEvent? get currentActiveEmergency => _activeEmergency;

  MockCloudBackendService({List<EmergencyEvent>? initialHistory}) {
    if (initialHistory != null && initialHistory.isNotEmpty) {
      _history.addAll(initialHistory);
      for (final ev in initialHistory) {
        if (ev.isActive) {
          _activeEmergency = ev;
          break;
        }
      }
    }
  }

  @override
  Future<bool> publishEmergency(EmergencyEvent event) async {
    debugPrint('BackendService: Publishing emergency ${event.id} (Type: ${event.type})');
    
    // Simulate brief network dispatch delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Update state to notificationSent if triggered
    final dispatchedEvent = event.copyWith(
      status: EmergencyStatus.notificationSent,
      isLocalOnly: true, // Marked local development mode until Firebase is active
    );

    _activeEmergency = dispatchedEvent;
    _history.insert(0, dispatchedEvent);

    _activeEmergencyController.add(_activeEmergency);
    _historyController.add(List.unmodifiable(_history));

    return true;
  }

  @override
  Future<bool> updateEmergencyStatus({
    required String emergencyId,
    required EmergencyStatus newStatus,
    String? responderName,
    String? note,
  }) async {
    debugPrint('BackendService: Updating emergency $emergencyId to $newStatus');

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      final now = DateTime.now();
      _activeEmergency = _activeEmergency!.copyWith(
        status: newStatus,
        acknowledgedBy: newStatus == EmergencyStatus.acknowledged
            ? (responderName ?? 'Caregiver Sarah')
            : _activeEmergency!.acknowledgedBy,
        acknowledgedAt: newStatus == EmergencyStatus.acknowledged
            ? now
            : _activeEmergency!.acknowledgedAt,
        respondingBy: newStatus == EmergencyStatus.responding
            ? (responderName ?? 'Caregiver Sarah')
            : _activeEmergency!.respondingBy,
        respondingAt: newStatus == EmergencyStatus.responding
            ? now
            : _activeEmergency!.respondingAt,
        resolvedAt: newStatus == EmergencyStatus.resolved
            ? now
            : _activeEmergency!.resolvedAt,
        resolutionNotes: note ?? _activeEmergency!.resolutionNotes,
      );

      // If resolved or cancelled, clear active emergency pointer
      if (newStatus == EmergencyStatus.resolved || newStatus == EmergencyStatus.cancelled) {
        _updateHistoryItem(_activeEmergency!);
        _activeEmergencyController.add(null);
        _activeEmergency = null;
      } else {
        _updateHistoryItem(_activeEmergency!);
        _activeEmergencyController.add(_activeEmergency);
      }

      _historyController.add(List.unmodifiable(_history));
      return true;
    }

    return false;
  }

  @override
  Future<bool> cancelEmergency(String emergencyId, {String? reason}) async {
    return updateEmergencyStatus(
      emergencyId: emergencyId,
      newStatus: EmergencyStatus.cancelled,
      note: reason ?? 'User cancelled false alarm',
    );
  }

  @override
  Future<bool> syncUserTelemetry({
    required String userId,
    required double latitude,
    required double longitude,
    required StickSensorData sensorData,
  }) async {
    // In local mode, logs telemetry updates
    return true;
  }

  void _updateHistoryItem(EmergencyEvent updated) {
    final index = _history.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _history[index] = updated;
    } else {
      _history.insert(0, updated);
    }
  }

  void dispose() {
    _activeEmergencyController.close();
    _historyController.close();
  }
}
