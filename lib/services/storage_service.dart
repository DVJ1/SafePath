import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_event.dart';
import '../models/esp32_config.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _keyRole = 'safepath_active_role';
  static const String _keyUserProfile = 'safepath_user_profile';
  static const String _keyCaregiverProfile = 'safepath_caregiver_profile';
  static const String _keyEsp32Config = 'safepath_esp32_config';
  static const String _keyEmergencyHistory = 'safepath_emergency_history';
  static const String _keyTtsSpeed = 'safepath_tts_speed';
  static const String _keyHighContrast = 'safepath_high_contrast';
  static const String _keyDarkMode = 'safepath_dark_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Active Role ('user' or 'caregiver')
  String getActiveRole() {
    return _prefs.getString(_keyRole) ?? 'user';
  }

  Future<void> setActiveRole(String role) async {
    await _prefs.setString(_keyRole, role);
  }

  // User Profile
  UserProfile getUserProfile() {
    final String? data = _prefs.getString(_keyUserProfile);
    if (data != null) {
      try {
        return UserProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (_) {}
    }
    return UserProfile.defaultUser();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(_keyUserProfile, jsonEncode(profile.toJson()));
  }

  // Caregiver Profile
  CaregiverProfile getCaregiverProfile() {
    final String? data = _prefs.getString(_keyCaregiverProfile);
    if (data != null) {
      try {
        return CaregiverProfile.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (_) {}
    }
    return CaregiverProfile.defaultCaregiver();
  }

  Future<void> saveCaregiverProfile(CaregiverProfile profile) async {
    await _prefs.setString(_keyCaregiverProfile, jsonEncode(profile.toJson()));
  }

  // ESP32 Config
  Esp32Config getEsp32Config() {
    final String? data = _prefs.getString(_keyEsp32Config);
    if (data != null) {
      try {
        return Esp32Config.fromJson(jsonDecode(data) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const Esp32Config();
  }

  Future<void> saveEsp32Config(Esp32Config config) async {
    await _prefs.setString(_keyEsp32Config, jsonEncode(config.toJson()));
  }

  // Emergency Events History
  List<EmergencyEvent> getEmergencyHistory() {
    final String? data = _prefs.getString(_keyEmergencyHistory);
    if (data != null) {
      try {
        final List<dynamic> list = jsonDecode(data) as List<dynamic>;
        return list
            .map((e) => EmergencyEvent.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveEmergencyHistory(List<EmergencyEvent> history) async {
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyEmergencyHistory, encoded);
  }

  Future<void> addEmergencyEvent(EmergencyEvent event) async {
    final history = getEmergencyHistory();
    // Prepend new event
    history.insert(0, event);
    // Keep max 50 recent events
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    await saveEmergencyHistory(history);
  }

  Future<void> updateEmergencyEvent(EmergencyEvent updatedEvent) async {
    final history = getEmergencyHistory();
    final index = history.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      history[index] = updatedEvent;
      await saveEmergencyHistory(history);
    }
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyEmergencyHistory);
  }

  // Settings
  double getTtsSpeed() => _prefs.getDouble(_keyTtsSpeed) ?? 0.5;
  Future<void> setTtsSpeed(double speed) => _prefs.setDouble(_keyTtsSpeed, speed);

  bool getHighContrast() => _prefs.getBool(_keyHighContrast) ?? false;
  Future<void> setHighContrast(bool val) => _prefs.setBool(_keyHighContrast, val);

  bool getDarkMode() => _prefs.getBool(_keyDarkMode) ?? true;
  Future<void> setDarkMode(bool val) => _prefs.setBool(_keyDarkMode, val);
}
