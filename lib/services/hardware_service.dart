import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/esp32_config.dart';
import '../models/stick_sensor_data.dart';

class HardwareService {
  Esp32Config _config;
  Timer? _pollingTimer;
  Timer? _simTimer;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;

  final _sensorDataController = StreamController<StickSensorData>.broadcast();
  Stream<StickSensorData> get sensorStream => _sensorDataController.stream;

  StickSensorData _currentData = StickSensorData.initial();
  StickSensorData get currentData => _currentData;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  String? _lastError;
  String? get lastError => _lastError;

  int _consecutiveFailures = 0;
  final Random _random = Random();

  // Simulation physics state variables
  double _simDistance = 150.0;
  double _simStepDirection = -5.0;

  HardwareService({Esp32Config? initialConfig})
      : _config = initialConfig ?? const Esp32Config();

  void updateConfig(Esp32Config newConfig) {
    final bool modeChanged = _config.isSimulationMode != newConfig.isSimulationMode ||
        _config.ipAddress != newConfig.ipAddress ||
        _config.port != newConfig.port ||
        _config.useWebSocket != newConfig.useWebSocket;

    _config = newConfig;

    if (modeChanged) {
      restart();
    }
  }

  void start() {
    stop();
    if (_config.isSimulationMode) {
      _startSimulation();
    } else {
      _startHardwareCommunication();
    }
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _simTimer?.cancel();
    _simTimer = null;
    _wsSubscription?.cancel();
    _wsSubscription = null;
    try {
      _wsChannel?.sink.close();
    } catch (_) {}
    _wsChannel = null;
    _isConnecting = false;
  }

  void restart() {
    stop();
    start();
  }

  // --- Real Physical ESP32 Hardware Integration ---

  void _startHardwareCommunication() {
    _isConnecting = true;
    _consecutiveFailures = 0;
    _lastError = null;

    if (_config.useWebSocket) {
      _connectWebSocket();
    } else {
      _startHttpPolling();
    }
  }

  void _startHttpPolling() {
    _pollEsp32Http();
    _pollingTimer = Timer.periodic(
      Duration(milliseconds: _config.pollingIntervalMs),
      (_) => _pollEsp32Http(),
    );
  }

  Future<void> _pollEsp32Http() async {
    try {
      final uri = Uri.parse(_config.httpUrl);
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        final data = StickSensorData.fromJson(json, isSimulated: false);
        _handleNewSensorData(data);
        _consecutiveFailures = 0;
        _lastError = null;
        _isConnecting = false;
      } else {
        _handleHardwareFailure('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      _handleHardwareFailure('Failed to connect to ESP32 at ${_config.ipAddress}: $e');
    }
  }

  void _connectWebSocket() {
    try {
      final uri = Uri.parse(_config.wsUrl);
      _wsChannel = WebSocketChannel.connect(uri);
      _isConnecting = false;

      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> json =
                jsonDecode(message.toString()) as Map<String, dynamic>;
            final data = StickSensorData.fromJson(json, isSimulated: false);
            _handleNewSensorData(data);
            _consecutiveFailures = 0;
            _lastError = null;
          } catch (e) {
            debugPrint('WS parse error: $e');
          }
        },
        onError: (err) {
          _handleHardwareFailure('WebSocket error: $err');
          if (_config.autoReconnect) {
            Future.delayed(const Duration(seconds: 3), () {
              if (!_config.isSimulationMode) _connectWebSocket();
            });
          }
        },
        onDone: () {
          _handleHardwareFailure('WebSocket closed by ESP32');
          if (_config.autoReconnect) {
            Future.delayed(const Duration(seconds: 3), () {
              if (!_config.isSimulationMode) _connectWebSocket();
            });
          }
        },
      );
    } catch (e) {
      _handleHardwareFailure('WS Connect error: $e');
    }
  }

  void _handleHardwareFailure(String errorMsg) {
    _consecutiveFailures++;
    _lastError = errorMsg;
    debugPrint('ESP32 Communication Warning: $errorMsg (Fail count: $_consecutiveFailures)');

    if (_consecutiveFailures >= 3) {
      _currentData = _currentData.copyWith(
        isConnected: false,
        isSimulated: false,
        timestamp: DateTime.now(),
      );
      _sensorDataController.add(_currentData);
    }
  }

  // --- Realistic Smart Stick Simulation Provider ---

  void _startSimulation() {
    _isConnecting = false;
    _lastError = null;

    _simTimer = Timer.periodic(
      Duration(milliseconds: _config.pollingIntervalMs),
      (_) => _generateSimulationTick(),
    );
  }

  void _generateSimulationTick() {
    StickSensorData generated;

    switch (_config.currentScenario) {
      case SimulationScenario.normalWalking:
        // Clear path with slight natural ultrasonic jitter
        _simDistance = 140.0 + (_random.nextDouble() * 30.0);
        generated = StickSensorData(
          distanceCm: _simDistance,
          obstacleSeverity: ObstacleSeverity.clear,
          surfaceHazard: SurfaceHazardType.normalDry,
          moistureLevelPercent: 5.0 + (_random.nextDouble() * 3.0),
          fallDetected: false,
          ax: 0.1 + (_random.nextDouble() * 0.4 - 0.2),
          ay: 9.8 + (_random.nextDouble() * 0.3 - 0.15),
          az: 0.3 + (_random.nextDouble() * 0.2),
          gx: (_random.nextDouble() * 2.0 - 1.0),
          gy: (_random.nextDouble() * 2.0 - 1.0),
          gz: (_random.nextDouble() * 2.0 - 1.0),
          batteryPercent: 88,
          batteryVoltage: 4.05,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_NORMAL_WALK',
        );
        break;

      case SimulationScenario.approachingObstacle:
        // Distance decreases step by step to simulate approaching wall or pole
        _simDistance += _simStepDirection * 6.0;
        if (_simDistance <= 30.0) {
          _simDistance = 30.0;
          _simStepDirection = 4.0; // rebound
        } else if (_simDistance >= 160.0) {
          _simDistance = 160.0;
          _simStepDirection = -5.0;
        }

        final severity = _simDistance < 40.0
            ? ObstacleSeverity.danger
            : (_simDistance < 95.0 ? ObstacleSeverity.warning : ObstacleSeverity.clear);

        generated = StickSensorData(
          distanceCm: _simDistance,
          obstacleSeverity: severity,
          surfaceHazard: SurfaceHazardType.normalDry,
          moistureLevelPercent: 6.0,
          fallDetected: false,
          ax: 0.4,
          ay: 9.7,
          az: 0.8,
          gx: 1.2,
          gy: -0.5,
          gz: 0.8,
          batteryPercent: 86,
          batteryVoltage: 4.01,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_OBSTACLE_APPROACH (dist: ${_simDistance.toStringAsFixed(1)})',
        );
        break;

      case SimulationScenario.dangerObstacleClose:
        generated = StickSensorData(
          distanceCm: 22.0 + (_random.nextDouble() * 5.0),
          obstacleSeverity: ObstacleSeverity.danger,
          surfaceHazard: SurfaceHazardType.normalDry,
          moistureLevelPercent: 6.0,
          fallDetected: false,
          ax: 0.2,
          ay: 9.8,
          az: 0.1,
          gx: 0.0,
          gy: 0.0,
          gz: 0.0,
          batteryPercent: 84,
          batteryVoltage: 3.98,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_IMMINENT_DANGER_OBSTACLE',
        );
        break;

      case SimulationScenario.waterPuddle:
        generated = StickSensorData(
          distanceCm: 135.0,
          obstacleSeverity: ObstacleSeverity.clear,
          surfaceHazard: SurfaceHazardType.waterPuddle,
          moistureLevelPercent: 84.0 + (_random.nextDouble() * 8.0),
          fallDetected: false,
          ax: 0.3,
          ay: 9.6,
          az: 0.5,
          gx: 0.5,
          gy: 0.2,
          gz: -0.1,
          batteryPercent: 82,
          batteryVoltage: 3.95,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_WATER_PUDDLE_DETECTED',
        );
        break;

      case SimulationScenario.potholeDrop:
        generated = StickSensorData(
          distanceCm: 245.0, // Ultrasonic sensor sees steep drop / sudden open hole
          obstacleSeverity: ObstacleSeverity.clear,
          surfaceHazard: SurfaceHazardType.potholeOrDrop,
          moistureLevelPercent: 8.0,
          fallDetected: false,
          ax: -1.2,
          ay: 8.9,
          az: 2.1,
          gx: 5.4,
          gy: -3.2,
          gz: 1.1,
          batteryPercent: 80,
          batteryVoltage: 3.92,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_POTHOLE_OR_STEEP_DROP',
        );
        break;

      case SimulationScenario.fallDetected:
        // High impact MPU6050 spike + stick lying flat (gravity shifted to X/Z axis)
        generated = StickSensorData(
          distanceCm: 15.0,
          obstacleSeverity: ObstacleSeverity.danger,
          surfaceHazard: SurfaceHazardType.normalDry,
          moistureLevelPercent: 10.0,
          fallDetected: true,
          ax: 24.8, // Impact spike
          ay: 1.2,  // Stick horizontal on ground
          az: 8.9,
          gx: 180.0, // Sudden rotation
          gy: 95.0,
          gz: 45.0,
          batteryPercent: 78,
          batteryVoltage: 3.88,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_FALL_DETECTED_ALARM',
        );
        break;

      case SimulationScenario.lowBattery:
        generated = StickSensorData(
          distanceCm: 120.0,
          obstacleSeverity: ObstacleSeverity.clear,
          surfaceHazard: SurfaceHazardType.normalDry,
          moistureLevelPercent: 5.0,
          fallDetected: false,
          ax: 0.1,
          ay: 9.8,
          az: 0.1,
          gx: 0.0,
          gy: 0.0,
          gz: 0.0,
          batteryPercent: 9,
          batteryVoltage: 3.38,
          isConnected: true,
          isSimulated: true,
          timestamp: DateTime.now(),
          rawData: 'SIM_LOW_BATTERY',
        );
        break;
    }

    _handleNewSensorData(generated);
  }

  void _handleNewSensorData(StickSensorData data) {
    _currentData = data;
    _sensorDataController.add(data);
  }

  /// Manually inject sensor data (e.g. for developer direct testing)
  void injectTestData(StickSensorData testData) {
    _handleNewSensorData(testData);
  }

  void dispose() {
    stop();
    _sensorDataController.close();
  }
}
