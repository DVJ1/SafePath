import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_event.dart';
import '../models/esp32_config.dart';
import '../models/stick_sensor_data.dart';
import '../services/backend_service.dart';
import '../services/emergency_service.dart';
import '../services/hardware_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/tts_audio_service.dart';

class AppStateProvider extends ChangeNotifier {
  final StorageService _storageService;
  final HardwareService _hardwareService;
  final LocationService _locationService;
  final EmergencyService _emergencyService;
  final TtsAudioService _ttsService;
  final NotificationService _notificationService;
  final BackendService _backendService;

  String _currentRole = 'user'; // 'user' (Blind User) or 'caregiver'
  String get currentRole => _currentRole;
  bool get isUserRole => _currentRole == 'user';
  bool get isCaregiverRole => _currentRole == 'caregiver';

  StickSensorData _sensorData = StickSensorData.initial();
  StickSensorData get sensorData => _sensorData;

  LocationResult? _currentLocation;
  LocationResult? get currentLocation => _currentLocation;

  EmergencyCountdownState _countdownState = EmergencyCountdownState.idle();
  EmergencyCountdownState get countdownState => _countdownState;

  EmergencyEvent? _activeEmergency;
  EmergencyEvent? get activeEmergency => _activeEmergency;

  List<EmergencyEvent> _emergencyHistory = [];
  List<EmergencyEvent> get emergencyHistory => _emergencyHistory;

  bool _isVoiceGuidanceEnabled = true;
  bool get isVoiceGuidanceEnabled => _isVoiceGuidanceEnabled;

  // Stream Subscriptions
  StreamSubscription? _sensorSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _countdownSub;
  StreamSubscription? _activeEmergencySub;
  StreamSubscription? _historySub;

  // Debouncing for voice sensor alerts
  DateTime _lastObstacleSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
  DateTime _lastHazardSpokenTime = DateTime.now().subtract(const Duration(seconds: 10));
  ObstacleSeverity _lastObstacleSeverity = ObstacleSeverity.clear;
  SurfaceHazardType _lastSurfaceHazard = SurfaceHazardType.normalDry;

  AppStateProvider({
    required StorageService storageService,
    required HardwareService hardwareService,
    required LocationService locationService,
    required EmergencyService emergencyService,
    required TtsAudioService ttsService,
    required NotificationService notificationService,
    required BackendService backendService,
  })  : _storageService = storageService,
        _hardwareService = hardwareService,
        _locationService = locationService,
        _emergencyService = emergencyService,
        _ttsService = ttsService,
        _notificationService = notificationService,
        _backendService = backendService {
    _init();
  }

  Future<void> _init() async {
    _currentRole = _storageService.getActiveRole();
    _emergencyHistory = _storageService.getEmergencyHistory();
    _activeEmergency = _emergencyService.activeEmergency;
    _sensorData = _hardwareService.currentData;

    // Listen to hardware sensor stream
    _sensorSub = _hardwareService.sensorStream.listen(_onSensorDataReceived);

    // Listen to GPS location updates
    _locationSub = _locationService.locationStream.listen((loc) {
      _currentLocation = loc;
      notifyListeners();
    });

    // Listen to emergency countdown stream
    _countdownSub = _emergencyService.countdownStream.listen((state) {
      _countdownState = state;
      notifyListeners();
    });

    // Listen to active emergency changes from backend
    _activeEmergencySub = _backendService.activeEmergencyStream.listen((ev) {
      _activeEmergency = ev;
      _emergencyHistory = _storageService.getEmergencyHistory();
      notifyListeners();
    });

    // Listen to history changes from backend
    _historySub = _backendService.emergencyHistoryStream.listen((hist) {
      _emergencyHistory = hist;
      notifyListeners();
    });

    // Fetch initial location and start streams
    refreshLocation();
    _locationService.startLocationUpdates();
    _hardwareService.start();

    // Welcome speech
    if (isUserRole) {
      _ttsService.speak('SafePath active. Smart stick monitor connected.');
    }
  }

  void _onSensorDataReceived(StickSensorData data) {
    _sensorData = data;
    notifyListeners();

    // 1. Fall detection trigger
    if (data.fallDetected && !_countdownState.isCountingDown && (_activeEmergency == null || !_activeEmergency!.isActive)) {
      _emergencyService.initiateEmergencyCountdown(
        type: EmergencyType.fallDetected,
        sensorSnapshot: data,
        initialSeconds: 5,
      );
      return;
    }

    // 2. Obstacle Proximity Voice Alert with Debounce
    if (_isVoiceGuidanceEnabled && !_countdownState.isCountingDown && (_activeEmergency == null || !_activeEmergency!.isActive)) {
      final now = DateTime.now();

      if (data.obstacleSeverity == ObstacleSeverity.danger &&
          (_lastObstacleSeverity != ObstacleSeverity.danger || now.difference(_lastObstacleSpokenTime).inSeconds > 3)) {
        _lastObstacleSpokenTime = now;
        _lastObstacleSeverity = data.obstacleSeverity;
        _ttsService.speak('Warning! Obstacle ${data.distanceCm.toInt()} centimeters ahead.', interrupt: true);
        _notificationService.showHazardNotification(
          id: 101,
          title: 'Obstacle Warning',
          body: 'Obstacle detected ${data.distanceCm.toInt()} cm ahead!',
        );
      } else if (data.obstacleSeverity == ObstacleSeverity.warning &&
          _lastObstacleSeverity != ObstacleSeverity.warning &&
          now.difference(_lastObstacleSpokenTime).inSeconds > 5) {
        _lastObstacleSpokenTime = now;
        _lastObstacleSeverity = data.obstacleSeverity;
        _ttsService.speak('Caution: Obstacle approaching in ${data.distanceCm.toInt()} centimeters.');
      } else if (data.obstacleSeverity == ObstacleSeverity.clear && _lastObstacleSeverity != ObstacleSeverity.clear) {
        _lastObstacleSeverity = ObstacleSeverity.clear;
      }

      // 3. Surface Hazard Voice Alert with Debounce
      if (data.surfaceHazard != SurfaceHazardType.normalDry &&
          (data.surfaceHazard != _lastSurfaceHazard || now.difference(_lastHazardSpokenTime).inSeconds > 6)) {
        _lastHazardSpokenTime = now;
        _lastSurfaceHazard = data.surfaceHazard;

        if (data.surfaceHazard == SurfaceHazardType.waterPuddle) {
          _ttsService.speak('Caution: Water puddle or wet surface detected on ground.');
          _notificationService.showHazardNotification(
            id: 102,
            title: 'Water Puddle Alert',
            body: 'Moisture level ${data.moistureLevelPercent.toInt()}%. Surface wet.',
          );
        } else if (data.surfaceHazard == SurfaceHazardType.potholeOrDrop) {
          _ttsService.speak('Warning! Steep drop or pothole detected ahead! Step carefully.', interrupt: true);
          _notificationService.showHazardNotification(
            id: 103,
            title: 'Steep Drop Warning',
            body: 'Steep drop or open hole detected.',
          );
        } else if (data.surfaceHazard == SurfaceHazardType.mudOrSlippery) {
          _ttsService.speak('Caution: Slippery or muddy terrain detected.');
        }
      } else if (data.surfaceHazard == SurfaceHazardType.normalDry) {
        _lastSurfaceHazard = SurfaceHazardType.normalDry;
      }
    }
  }

  // --- Role Switching ---
  Future<void> setRole(String newRole) async {
    _currentRole = newRole;
    await _storageService.setActiveRole(newRole);
    notifyListeners();

    if (newRole == 'user') {
      _ttsService.speak('Switched to Visually Impaired User Mode. Large buttons and voice alerts enabled.');
    } else {
      _ttsService.speak('Switched to Caregiver Monitor Mode. Real-time emergency dashboard enabled.');
    }
  }

  // --- Emergency Actions ---
  void triggerManualSos() {
    _emergencyService.initiateEmergencyCountdown(
      type: EmergencyType.sosManual,
      sensorSnapshot: _sensorData,
      initialSeconds: 5,
    );
  }

  Future<void> triggerImmediateSos() async {
    await _emergencyService.triggerImmediateEmergency(
      type: EmergencyType.sosManual,
      sensorSnapshot: _sensorData,
    );
    notifyListeners();
  }

  void cancelEmergencyCountdown() {
    _emergencyService.cancelCountdown();
    notifyListeners();
  }

  Future<void> cancelActiveEmergency({String? reason}) async {
    if (_activeEmergency != null) {
      await _emergencyService.cancelActiveEmergency(_activeEmergency!.id, reason: reason);
      _activeEmergency = null;
      _emergencyHistory = _storageService.getEmergencyHistory();
      notifyListeners();
    }
  }

  // --- Caregiver Actions ---
  Future<void> acknowledgeEmergency(String emergencyId, {String? responderName}) async {
    await _emergencyService.acknowledgeEmergency(emergencyId, responderName: responderName);
    _emergencyHistory = _storageService.getEmergencyHistory();
    notifyListeners();
  }

  Future<void> markResponding(String emergencyId, {String? responderName}) async {
    await _emergencyService.markResponding(emergencyId, responderName: responderName);
    _emergencyHistory = _storageService.getEmergencyHistory();
    notifyListeners();
  }

  Future<void> markAssistanceCoordinated(String emergencyId, {String? note}) async {
    await _emergencyService.markAssistanceCoordinated(emergencyId, details: note);
    _emergencyHistory = _storageService.getEmergencyHistory();
    notifyListeners();
  }

  Future<void> resolveEmergency(String emergencyId, {String? note}) async {
    await _emergencyService.resolveEmergency(emergencyId, note: note);
    _activeEmergency = null;
    _emergencyHistory = _storageService.getEmergencyHistory();
    notifyListeners();
  }

  // --- Location Actions ---
  Future<void> refreshLocation() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      _currentLocation = loc;
      notifyListeners();
    } catch (_) {}
  }

  // --- Voice Feedback Actions ---
  void toggleVoiceGuidance() {
    _isVoiceGuidanceEnabled = !_isVoiceGuidanceEnabled;
    notifyListeners();
    _ttsService.speak(_isVoiceGuidanceEnabled ? 'Voice alerts enabled' : 'Voice alerts muted');
  }

  void speakCurrentStatus() {
    String status = 'SafePath status: ';
    if (_sensorData.isConnected) {
      status += 'Stick is connected. ';
    } else {
      status += 'Stick is in simulation mode. ';
    }

    if (_sensorData.obstacleSeverity == ObstacleSeverity.clear) {
      status += 'Path ahead is clear. ';
    } else {
      status += 'Obstacle at ${_sensorData.distanceCm.toInt()} centimeters. ';
    }

    if (_sensorData.surfaceHazard == SurfaceHazardType.waterPuddle) {
      status += 'Ground is wet with water puddle. ';
    } else if (_sensorData.surfaceHazard == SurfaceHazardType.potholeOrDrop) {
      status += 'Warning: steep drop or hole ahead. ';
    } else {
      status += 'Surface is dry and normal. ';
    }

    status += 'Battery is at ${_sensorData.batteryPercent} percent.';
    _ttsService.speak(status, interrupt: true);
  }

  // --- Quick Scenario Testing Helpers ---
  void setSimulationScenario(SimulationScenario scenario) {
    final curConfig = _storageService.getEsp32Config();
    final updated = curConfig.copyWith(
      isSimulationMode: true,
      currentScenario: scenario,
    );
    _storageService.saveEsp32Config(updated);
    _hardwareService.updateConfig(updated);
    notifyListeners();

    _ttsService.speak('Simulation scenario set to ${scenario.name}');
  }

  Future<void> clearHistory() async {
    await _storageService.clearHistory();
    _emergencyHistory = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _locationSub?.cancel();
    _countdownSub?.cancel();
    _activeEmergencySub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
