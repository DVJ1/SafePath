import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/emergency_event.dart';
import '../models/stick_sensor_data.dart';
import 'backend_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'tts_audio_service.dart';

class EmergencyCountdownState {
  final bool isCountingDown;
  final int secondsRemaining;
  final EmergencyType type;
  final StickSensorData? sensorSnapshot;

  EmergencyCountdownState({
    required this.isCountingDown,
    required this.secondsRemaining,
    required this.type,
    this.sensorSnapshot,
  });

  factory EmergencyCountdownState.idle() => EmergencyCountdownState(
        isCountingDown: false,
        secondsRemaining: 0,
        type: EmergencyType.sosManual,
      );
}

class EmergencyService {
  final StorageService _storageService;
  final LocationService _locationService;
  final TtsAudioService _ttsService;
  final NotificationService _notificationService;
  final BackendService _backendService;
  final Uuid _uuid = const Uuid();

  Timer? _countdownTimer;
  EmergencyCountdownState _countdownState = EmergencyCountdownState.idle();
  final _countdownController = StreamController<EmergencyCountdownState>.broadcast();
  Stream<EmergencyCountdownState> get countdownStream => _countdownController.stream;
  EmergencyCountdownState get countdownState => _countdownState;

  EmergencyEvent? _activeEmergency;
  EmergencyEvent? get activeEmergency => _activeEmergency;

  EmergencyService({
    required StorageService storageService,
    required LocationService locationService,
    required TtsAudioService ttsService,
    required NotificationService notificationService,
    required BackendService backendService,
  })  : _storageService = storageService,
        _locationService = locationService,
        _ttsService = ttsService,
        _notificationService = notificationService,
        _backendService = backendService {
    _initActiveEmergency();
  }

  void _initActiveEmergency() {
    final history = _storageService.getEmergencyHistory();
    for (final event in history) {
      if (event.isActive) {
        _activeEmergency = event;
        break;
      }
    }
  }

  /// Start 5-second countdown to allow false alarm cancellation
  void initiateEmergencyCountdown({
    required EmergencyType type,
    StickSensorData? sensorSnapshot,
    int initialSeconds = 5,
  }) {
    // If already in an active emergency or already counting down, don't restart
    if (_countdownState.isCountingDown) return;

    _countdownTimer?.cancel();
    _countdownState = EmergencyCountdownState(
      isCountingDown: true,
      secondsRemaining: initialSeconds,
      type: type,
      sensorSnapshot: sensorSnapshot,
    );
    _countdownController.add(_countdownState);

    final String reason = type == EmergencyType.fallDetected
        ? 'Fall detected!'
        : 'Emergency button activated!';
    _ttsService.speakEmergency('$reason Emergency will trigger in $initialSeconds seconds. Tap cancel if safe.');

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final int nextSec = _countdownState.secondsRemaining - 1;
      if (nextSec > 0) {
        _countdownState = EmergencyCountdownState(
          isCountingDown: true,
          secondsRemaining: nextSec,
          type: type,
          sensorSnapshot: sensorSnapshot,
        );
        _countdownController.add(_countdownState);
        _ttsService.speak('$nextSec', interrupt: true);
        _ttsService.triggerHeavyHaptic();
      } else {
        // Countdown reached 0 -> Trigger emergency
        timer.cancel();
        _countdownState = EmergencyCountdownState.idle();
        _countdownController.add(_countdownState);
        _executeEmergencyTrigger(type, sensorSnapshot);
      }
    });
  }

  /// Cancel countdown (false alarm caught in time)
  void cancelCountdown() {
    if (_countdownState.isCountingDown) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _countdownState = EmergencyCountdownState.idle();
      _countdownController.add(_countdownState);

      _ttsService.speak('Emergency cancelled. False alarm averted.', interrupt: true);
      _ttsService.triggerMediumHaptic();
    }
  }

  /// Trigger emergency immediately (bypassing countdown or called after countdown expires)
  Future<EmergencyEvent> triggerImmediateEmergency({
    required EmergencyType type,
    StickSensorData? sensorSnapshot,
    String? customNote,
  }) async {
    cancelCountdown();
    return _executeEmergencyTrigger(type, sensorSnapshot, customNote: customNote);
  }

  Future<EmergencyEvent> _executeEmergencyTrigger(
    EmergencyType type,
    StickSensorData? sensorSnapshot, {
    String? customNote,
  }) async {
    final String eventId = _uuid.v4();
    final DateTime now = DateTime.now();

    // Capture device GPS location
    LocationResult location;
    try {
      location = await _locationService.getCurrentLocation();
    } catch (_) {
      location = LocationResult(
        latitude: 28.6139,
        longitude: 77.2090,
        accuracyMeters: 20.0,
        timestamp: now,
        isMockedOrSimulated: true,
        isStale: true,
      );
    }

    final EmergencyEvent event = EmergencyEvent(
      id: eventId,
      type: type,
      status: EmergencyStatus.triggered,
      timestamp: now,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracyMeters: location.accuracyMeters,
      addressLabel: 'Near GPS (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})',
      isLocationAvailable: location.error == null,
      isStaleLocation: location.isStale,
      batteryPercent: sensorSnapshot?.batteryPercent ?? 85,
      sensorSnapshot: sensorSnapshot,
      notes: customNote ?? (type == EmergencyType.fallDetected ? 'Fall detected by MPU6050 accelerometer' : 'Manual SOS triggered'),
      isLocalOnly: true,
      isSimulated: sensorSnapshot?.isSimulated ?? false,
    );

    _activeEmergency = event;
    await _storageService.addEmergencyEvent(event);
    await _backendService.publishEmergency(event);

    // Audio announcement & notifications
    _ttsService.speakEmergency('Emergency SOS Alert sent to caregivers! Help is being requested.');
    _notificationService.showEmergencyNotification(
      id: 999,
      title: '🚨 SAFEPATH EMERGENCY SOS DISPATCHED',
      body: '${event.typeDisplayName} at ${location.coordinatesDisplay}. Alerting caregivers...',
    );

    return event;
  }

  /// Caregiver acknowledges emergency
  Future<void> acknowledgeEmergency(String emergencyId, {String? responderName}) async {
    await _backendService.updateEmergencyStatus(
      emergencyId: emergencyId,
      newStatus: EmergencyStatus.acknowledged,
      responderName: responderName,
    );

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      _activeEmergency = _activeEmergency!.copyWith(
        status: EmergencyStatus.acknowledged,
        acknowledgedBy: responderName ?? 'Caregiver Sarah',
        acknowledgedAt: DateTime.now(),
      );
      await _storageService.updateEmergencyEvent(_activeEmergency!);
    }

    _ttsService.speak('Emergency acknowledged by caregiver ${responderName ?? "Sarah"}.', interrupt: true);
    _notificationService.showEmergencyNotification(
      id: 998,
      title: 'Caregiver Acknowledged',
      body: '${responderName ?? "Sarah"} has seen the alert.',
    );
  }

  /// Caregiver marks themselves as responding
  Future<void> markResponding(String emergencyId, {String? responderName}) async {
    await _backendService.updateEmergencyStatus(
      emergencyId: emergencyId,
      newStatus: EmergencyStatus.responding,
      responderName: responderName,
    );

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      _activeEmergency = _activeEmergency!.copyWith(
        status: EmergencyStatus.responding,
        respondingBy: responderName ?? 'Caregiver Sarah',
        respondingAt: DateTime.now(),
      );
      await _storageService.updateEmergencyEvent(_activeEmergency!);
    }

    _ttsService.speak('Caregiver ${responderName ?? "Sarah"} is currently en route to your location.', interrupt: true);
  }

  /// Assistance Coordinated
  Future<void> markAssistanceCoordinated(String emergencyId, {String? details}) async {
    await _backendService.updateEmergencyStatus(
      emergencyId: emergencyId,
      newStatus: EmergencyStatus.assistanceCoordinated,
      note: details,
    );

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      _activeEmergency = _activeEmergency!.copyWith(
        status: EmergencyStatus.assistanceCoordinated,
        notes: details,
      );
      await _storageService.updateEmergencyEvent(_activeEmergency!);
    }
  }

  /// Resolve emergency
  Future<void> resolveEmergency(String emergencyId, {String? note}) async {
    await _backendService.updateEmergencyStatus(
      emergencyId: emergencyId,
      newStatus: EmergencyStatus.resolved,
      note: note ?? 'User confirmed safe.',
    );

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      final resolved = _activeEmergency!.copyWith(
        status: EmergencyStatus.resolved,
        resolvedAt: DateTime.now(),
        resolutionNotes: note ?? 'Safety confirmed by caregiver.',
      );
      await _storageService.updateEmergencyEvent(resolved);
      _activeEmergency = null;
    }

    _ttsService.speak('Emergency resolved. You are marked as safe.', interrupt: true);
  }

  /// Cancel active emergency
  Future<void> cancelActiveEmergency(String emergencyId, {String? reason}) async {
    await _backendService.cancelEmergency(emergencyId, reason: reason);

    if (_activeEmergency != null && _activeEmergency!.id == emergencyId) {
      final cancelled = _activeEmergency!.copyWith(
        status: EmergencyStatus.cancelled,
        resolvedAt: DateTime.now(),
        resolutionNotes: reason ?? 'User cancelled false alarm',
      );
      await _storageService.updateEmergencyEvent(cancelled);
      _activeEmergency = null;
    }

    _ttsService.speak('Active emergency cancelled.', interrupt: true);
  }

  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.close();
  }
}
