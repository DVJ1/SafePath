enum SimulationScenario {
  normalWalking,
  approachingObstacle,
  dangerObstacleClose,
  waterPuddle,
  potholeDrop,
  fallDetected,
  lowBattery,
}

class Esp32Config {
  final String ipAddress;
  final int port;
  final String endpointPath;
  final bool useWebSocket;
  final int webSocketPort;
  final int pollingIntervalMs;
  final bool autoReconnect;
  final bool isSimulationMode;
  final SimulationScenario currentScenario;

  const Esp32Config({
    this.ipAddress = '192.168.4.1',
    this.port = 80,
    this.endpointPath = '/sensors',
    this.useWebSocket = false,
    this.webSocketPort = 81,
    this.pollingIntervalMs = 800,
    this.autoReconnect = true,
    this.isSimulationMode = true,
    this.currentScenario = SimulationScenario.normalWalking,
  });

  String get httpUrl => 'http://$ipAddress:$port$endpointPath';
  String get wsUrl => 'ws://$ipAddress:$webSocketPort/ws';

  Map<String, dynamic> toJson() {
    return {
      'ip_address': ipAddress,
      'port': port,
      'endpoint_path': endpointPath,
      'use_web_socket': useWebSocket,
      'web_socket_port': webSocketPort,
      'polling_interval_ms': pollingIntervalMs,
      'auto_reconnect': autoReconnect,
      'is_simulation_mode': isSimulationMode,
      'scenario': currentScenario.name,
    };
  }

  factory Esp32Config.fromJson(Map<String, dynamic> json) {
    return Esp32Config(
      ipAddress: json['ip_address'] as String? ?? '192.168.4.1',
      port: (json['port'] as num?)?.toInt() ?? 80,
      endpointPath: json['endpoint_path'] as String? ?? '/sensors',
      useWebSocket: json['use_web_socket'] as bool? ?? false,
      webSocketPort: (json['web_socket_port'] as num?)?.toInt() ?? 81,
      pollingIntervalMs: (json['polling_interval_ms'] as num?)?.toInt() ?? 800,
      autoReconnect: json['auto_reconnect'] as bool? ?? true,
      isSimulationMode: json['is_simulation_mode'] as bool? ?? true,
      currentScenario: SimulationScenario.values.firstWhere(
        (s) => s.name == json['scenario'],
        orElse: () => SimulationScenario.normalWalking,
      ),
    );
  }

  Esp32Config copyWith({
    String? ipAddress,
    int? port,
    String? endpointPath,
    bool? useWebSocket,
    int? webSocketPort,
    int? pollingIntervalMs,
    bool? autoReconnect,
    bool? isSimulationMode,
    SimulationScenario? currentScenario,
  }) {
    return Esp32Config(
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      endpointPath: endpointPath ?? this.endpointPath,
      useWebSocket: useWebSocket ?? this.useWebSocket,
      webSocketPort: webSocketPort ?? this.webSocketPort,
      pollingIntervalMs: pollingIntervalMs ?? this.pollingIntervalMs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      isSimulationMode: isSimulationMode ?? this.isSimulationMode,
      currentScenario: currentScenario ?? this.currentScenario,
    );
  }
}
