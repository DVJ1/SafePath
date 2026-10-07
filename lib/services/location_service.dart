import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isMockedOrSimulated;
  final bool isStale;
  final String? error;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    this.isMockedOrSimulated = false,
    this.isStale = false,
    this.error,
  });

  String get coordinatesDisplay => '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<LocationResult>.broadcast();
  Stream<LocationResult> get locationStream => _locationController.stream;

  LocationResult? _lastKnownLocation;
  LocationResult? get lastKnownLocation => _lastKnownLocation;

  bool _isPermissionGranted = false;
  bool get isPermissionGranted => _isPermissionGranted;

  bool _isGpsServiceEnabled = false;
  bool get isGpsServiceEnabled => _isGpsServiceEnabled;

  /// Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    try {
      _isGpsServiceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isPermissionGranted = false;
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isPermissionGranted = false;
        return false;
      }

      _isPermissionGranted = (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always);
      return _isPermissionGranted;
    } catch (e) {
      debugPrint('LocationService: Error checking permissions: $e');
      _isPermissionGranted = false;
      return false;
    }
  }

  /// Get current high accuracy GPS location with graceful fallback
  Future<LocationResult> getCurrentLocation({bool allowSimulationFallback = true}) async {
    final hasPerm = await checkAndRequestPermissions();

    if (!hasPerm) {
      if (allowSimulationFallback) {
        // Clear fallback with honest simulation flag
        final simLoc = LocationResult(
          latitude: 28.6139,
          longitude: 77.2090,
          accuracyMeters: 15.0,
          timestamp: DateTime.now(),
          isMockedOrSimulated: true,
          error: 'GPS permission denied. Using fallback coordinates.',
        );
        _lastKnownLocation = simLoc;
        return simLoc;
      } else {
        throw Exception('Location permission denied');
      }
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final result = LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        timestamp: position.timestamp,
        isMockedOrSimulated: position.isMocked,
      );

      _lastKnownLocation = result;
      _locationController.add(result);
      return result;
    } catch (e) {
      debugPrint('LocationService: getCurrentPosition failed: $e. Trying last known...');

      // Attempt last known location from platform
      try {
        final Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final result = LocationResult(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            accuracyMeters: lastKnown.accuracy,
            timestamp: lastKnown.timestamp,
            isMockedOrSimulated: lastKnown.isMocked,
            isStale: true,
          );
          _lastKnownLocation = result;
          _locationController.add(result);
          return result;
        }
      } catch (_) {}

      // If all else fails and simulation fallback allowed:
      if (allowSimulationFallback) {
        final fallback = LocationResult(
          latitude: 28.6139,
          longitude: 77.2090,
          accuracyMeters: 25.0,
          timestamp: DateTime.now(),
          isMockedOrSimulated: true,
          error: 'GPS timeout. Fallback simulation coordinate used.',
        );
        _lastKnownLocation = fallback;
        return fallback;
      }

      throw Exception('Unable to determine device location: $e');
    }
  }

  /// Start continuous GPS location stream
  void startLocationUpdates() {
    _positionStreamSubscription?.cancel();

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        final result = LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          timestamp: position.timestamp,
          isMockedOrSimulated: position.isMocked,
        );
        _lastKnownLocation = result;
        _locationController.add(result);
      },
      onError: (err) {
        debugPrint('Location stream error: $err');
      },
    );
  }

  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
}
