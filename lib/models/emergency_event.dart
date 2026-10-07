import 'stick_sensor_data.dart';

enum EmergencyType {
  sosManual,
  fallDetected,
  severeHazard,
  stickDisconnectedEmergency,
}

enum EmergencyStatus {
  triggered,
  notificationSent,
  acknowledged,
  responding,
  assistanceCoordinated,
  resolved,
  cancelled,
  failedDelivery,
}

class EmergencyEvent {
  final String id;
  final EmergencyType type;
  final EmergencyStatus status;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? addressLabel;
  final bool isLocationAvailable;
  final bool isStaleLocation;
  final int? batteryPercent;
  final String? notes;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? respondingBy;
  final DateTime? respondingAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final StickSensorData? sensorSnapshot;
  final bool isLocalOnly;
  final bool isSimulated;

  EmergencyEvent({
    required this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.addressLabel,
    this.isLocationAvailable = true,
    this.isStaleLocation = false,
    this.batteryPercent,
    this.notes,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.respondingBy,
    this.respondingAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.sensorSnapshot,
    this.isLocalOnly = false,
    this.isSimulated = false,
  });

  String get typeDisplayName {
    switch (type) {
      case EmergencyType.sosManual:
        return 'Manual SOS Alarm';
      case EmergencyType.fallDetected:
        return 'Fall Detection Alert';
      case EmergencyType.severeHazard:
        return 'Hazard Warning Alert';
      case EmergencyType.stickDisconnectedEmergency:
        return 'Stick Disconnected Alert';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EmergencyStatus.triggered:
        return 'Alert Triggered';
      case EmergencyStatus.notificationSent:
        return 'Alert Dispatched';
      case EmergencyStatus.acknowledged:
        return 'Caregiver Acknowledged';
      case EmergencyStatus.responding:
        return 'Caregiver Responding';
      case EmergencyStatus.assistanceCoordinated:
        return 'Assistance Coordinated';
      case EmergencyStatus.resolved:
        return 'Resolved & Safe';
      case EmergencyStatus.cancelled:
        return 'False Alarm Cancelled';
      case EmergencyStatus.failedDelivery:
        return 'Dispatch Delivery Failed';
    }
  }

  bool get isActive {
    return status == EmergencyStatus.triggered ||
        status == EmergencyStatus.notificationSent ||
        status == EmergencyStatus.acknowledged ||
        status == EmergencyStatus.responding ||
        status == EmergencyStatus.assistanceCoordinated;
  }

  EmergencyEvent copyWith({
    String? id,
    EmergencyType? type,
    EmergencyStatus? status,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    String? addressLabel,
    bool? isLocationAvailable,
    bool? isStaleLocation,
    int? batteryPercent,
    String? notes,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? respondingBy,
    DateTime? respondingAt,
    DateTime? resolvedAt,
    String? resolutionNotes,
    StickSensorData? sensorSnapshot,
    bool? isLocalOnly,
    bool? isSimulated,
  }) {
    return EmergencyEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      addressLabel: addressLabel ?? this.addressLabel,
      isLocationAvailable: isLocationAvailable ?? this.isLocationAvailable,
      isStaleLocation: isStaleLocation ?? this.isStaleLocation,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      notes: notes ?? this.notes,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      respondingBy: respondingBy ?? this.respondingBy,
      respondingAt: respondingAt ?? this.respondingAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      sensorSnapshot: sensorSnapshot ?? this.sensorSnapshot,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      isSimulated: isSimulated ?? this.isSimulated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'address_label': addressLabel,
      'is_location_available': isLocationAvailable,
      'is_stale_location': isStaleLocation,
      'battery_percent': batteryPercent,
      'notes': notes,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'responding_by': respondingBy,
      'responding_at': respondingAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'sensor_snapshot': sensorSnapshot?.toJson(),
      'is_local_only': isLocalOnly,
      'is_simulated': isSimulated,
    };
  }

  factory EmergencyEvent.fromJson(Map<String, dynamic> json) {
    return EmergencyEvent(
      id: json['id'] as String,
      type: EmergencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyType.sosManual,
      ),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EmergencyStatus.triggered,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      addressLabel: json['address_label'] as String?,
      isLocationAvailable: json['is_location_available'] as bool? ?? true,
      isStaleLocation: json['is_stale_location'] as bool? ?? false,
      batteryPercent: json['battery_percent'] as int?,
      notes: json['notes'] as String?,
      acknowledgedBy: json['acknowledged_by'] as String?,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      respondingBy: json['responding_by'] as String?,
      respondingAt: json['responding_at'] != null
          ? DateTime.parse(json['responding_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionNotes: json['resolution_notes'] as String?,
      sensorSnapshot: json['sensor_snapshot'] != null
          ? StickSensorData.fromJson(Map<String, dynamic>.from(json['sensor_snapshot']))
          : null,
      isLocalOnly: json['is_local_only'] as bool? ?? false,
      isSimulated: json['is_simulated'] as bool? ?? false,
    );
  }
}
