enum ObstacleSeverity {
  clear,
  warning, // < 100 cm
  danger,  // < 40 cm
}

enum SurfaceHazardType {
  normalDry,
  waterPuddle,
  potholeOrDrop,
  mudOrSlippery,
}

class StickSensorData {
  final double distanceCm;
  final ObstacleSeverity obstacleSeverity;
  final SurfaceHazardType surfaceHazard;
  final double moistureLevelPercent;
  final bool fallDetected;
  final double ax;
  final double ay;
  final double az;
  final double gx;
  final double gy;
  final double gz;
  final int batteryPercent;
  final double batteryVoltage;
  final bool isConnected;
  final bool isSimulated;
  final DateTime timestamp;
  final String? rawData;

  const StickSensorData({
    required this.distanceCm,
    required this.obstacleSeverity,
    required this.surfaceHazard,
    required this.moistureLevelPercent,
    required this.fallDetected,
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.batteryPercent,
    required this.batteryVoltage,
    required this.isConnected,
    required this.isSimulated,
    required this.timestamp,
    this.rawData,
  });

  factory StickSensorData.initial() {
    return StickSensorData(
      distanceCm: 150.0,
      obstacleSeverity: ObstacleSeverity.clear,
      surfaceHazard: SurfaceHazardType.normalDry,
      moistureLevelPercent: 5.0,
      fallDetected: false,
      ax: 0.0,
      ay: 9.8,
      az: 0.2,
      gx: 0.0,
      gy: 0.0,
      gz: 0.0,
      batteryPercent: 92,
      batteryVoltage: 4.12,
      isConnected: false,
      isSimulated: true,
      timestamp: DateTime.now(),
    );
  }

  factory StickSensorData.fromJson(Map<String, dynamic> json, {bool isSimulated = false}) {
    final double dist = (json['distance_cm'] as num?)?.toDouble() ?? 150.0;
    final double moisture = (json['moisture'] as num?)?.toDouble() ?? 0.0;
    final bool fall = json['fall_detected'] == true || (json['fall'] == 1);

    // Derive obstacle severity
    ObstacleSeverity severity = ObstacleSeverity.clear;
    if (dist < 40.0) {
      severity = ObstacleSeverity.danger;
    } else if (dist < 100.0) {
      severity = ObstacleSeverity.warning;
    }

    // Derive surface hazard
    SurfaceHazardType surface = SurfaceHazardType.normalDry;
    final String? hazardStr = json['surface_hazard']?.toString().toLowerCase();
    if (hazardStr == 'water' || hazardStr == 'puddle' || moisture > 55.0) {
      surface = SurfaceHazardType.waterPuddle;
    } else if (hazardStr == 'pothole' || hazardStr == 'drop') {
      surface = SurfaceHazardType.potholeOrDrop;
    } else if (hazardStr == 'mud' || moisture > 35.0) {
      surface = SurfaceHazardType.mudOrSlippery;
    }

    return StickSensorData(
      distanceCm: dist,
      obstacleSeverity: severity,
      surfaceHazard: surface,
      moistureLevelPercent: moisture,
      fallDetected: fall,
      ax: (json['ax'] as num?)?.toDouble() ?? 0.0,
      ay: (json['ay'] as num?)?.toDouble() ?? 9.8,
      az: (json['az'] as num?)?.toDouble() ?? 0.0,
      gx: (json['gx'] as num?)?.toDouble() ?? 0.0,
      gy: (json['gy'] as num?)?.toDouble() ?? 0.0,
      gz: (json['gz'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: (json['battery_percent'] as num?)?.toInt() ?? 85,
      batteryVoltage: (json['battery_v'] as num?)?.toDouble() ?? 3.95,
      isConnected: true,
      isSimulated: isSimulated,
      timestamp: DateTime.now(),
      rawData: json.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance_cm': distanceCm,
      'obstacle_severity': obstacleSeverity.name,
      'surface_hazard': surfaceHazard.name,
      'moisture': moistureLevelPercent,
      'fall_detected': fallDetected,
      'ax': ax,
      'ay': ay,
      'az': az,
      'gx': gx,
      'gy': gy,
      'gz': gz,
      'battery_percent': batteryPercent,
      'battery_v': batteryVoltage,
      'is_connected': isConnected,
      'is_simulated': isSimulated,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  StickSensorData copyWith({
    double? distanceCm,
    ObstacleSeverity? obstacleSeverity,
    SurfaceHazardType? surfaceHazard,
    double? moistureLevelPercent,
    bool? fallDetected,
    double? ax,
    double? ay,
    double? az,
    double? gx,
    double? gy,
    double? gz,
    int? batteryPercent,
    double? batteryVoltage,
    bool? isConnected,
    bool? isSimulated,
    DateTime? timestamp,
    String? rawData,
  }) {
    return StickSensorData(
      distanceCm: distanceCm ?? this.distanceCm,
      obstacleSeverity: obstacleSeverity ?? this.obstacleSeverity,
      surfaceHazard: surfaceHazard ?? this.surfaceHazard,
      moistureLevelPercent: moistureLevelPercent ?? this.moistureLevelPercent,
      fallDetected: fallDetected ?? this.fallDetected,
      ax: ax ?? this.ax,
      ay: ay ?? this.ay,
      az: az ?? this.az,
      gx: gx ?? this.gx,
      gy: gy ?? this.gy,
      gz: gz ?? this.gz,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      isConnected: isConnected ?? this.isConnected,
      isSimulated: isSimulated ?? this.isSimulated,
      timestamp: timestamp ?? this.timestamp,
      rawData: rawData ?? this.rawData,
    );
  }
}
