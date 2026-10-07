import 'package:flutter/foundation.dart';
import '../models/esp32_config.dart';
import '../models/user_profile.dart';
import '../services/hardware_service.dart';
import '../services/storage_service.dart';
import '../services/tts_audio_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final HardwareService _hardwareService;
  final TtsAudioService _ttsService;

  UserProfile _userProfile = UserProfile.defaultUser();
  UserProfile get userProfile => _userProfile;

  CaregiverProfile _caregiverProfile = CaregiverProfile.defaultCaregiver();
  CaregiverProfile get caregiverProfile => _caregiverProfile;

  Esp32Config _esp32Config = const Esp32Config();
  Esp32Config get esp32Config => _esp32Config;

  bool _isHighContrast = false;
  bool get isHighContrast => _isHighContrast;

  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  double _ttsSpeed = 0.5;
  double get ttsSpeed => _ttsSpeed;

  SettingsProvider({
    required StorageService storageService,
    required HardwareService hardwareService,
    required TtsAudioService ttsService,
  })  : _storageService = storageService,
        _hardwareService = hardwareService,
        _ttsService = ttsService {
    _loadSettings();
  }

  void _loadSettings() {
    _userProfile = _storageService.getUserProfile();
    _caregiverProfile = _storageService.getCaregiverProfile();
    _esp32Config = _storageService.getEsp32Config();
    _isHighContrast = _storageService.getHighContrast();
    _isDarkMode = _storageService.getDarkMode();
    _ttsSpeed = _storageService.getTtsSpeed();
    notifyListeners();
  }

  // --- User Profile ---
  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await _storageService.saveUserProfile(profile);
    notifyListeners();
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    final updatedContacts = List<EmergencyContact>.from(_userProfile.contacts)..add(contact);
    final updated = _userProfile.copyWith(contacts: updatedContacts);
    await updateUserProfile(updated);
  }

  Future<void> removeEmergencyContact(String contactId) async {
    final updatedContacts = _userProfile.contacts.where((c) => c.id != contactId).toList();
    final updated = _userProfile.copyWith(contacts: updatedContacts);
    await updateUserProfile(updated);
  }

  // --- Caregiver Profile ---
  Future<void> updateCaregiverProfile(CaregiverProfile profile) async {
    _caregiverProfile = profile;
    await _storageService.saveCaregiverProfile(profile);
    notifyListeners();
  }

  // --- ESP32 Hardware Config ---
  Future<void> updateEsp32Config(Esp32Config config) async {
    _esp32Config = config;
    await _storageService.saveEsp32Config(config);
    _hardwareService.updateConfig(config);
    notifyListeners();
  }

  Future<void> setSimulationMode(bool enabled) async {
    final updated = _esp32Config.copyWith(isSimulationMode: enabled);
    await updateEsp32Config(updated);
    _ttsService.speak(enabled ? 'Simulation mode enabled' : 'Connecting to physical ESP32 device at ${_esp32Config.ipAddress}');
  }

  Future<void> setEsp32Ip(String ip) async {
    final updated = _esp32Config.copyWith(ipAddress: ip.trim());
    await updateEsp32Config(updated);
  }

  // --- Theme & Accessibility ---
  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    await _storageService.setHighContrast(_isHighContrast);
    notifyListeners();
    _ttsService.speak(_isHighContrast ? 'High contrast mode enabled' : 'Standard contrast mode enabled');
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTtsSpeed(double speed) async {
    _ttsSpeed = speed;
    await _storageService.setTtsSpeed(speed);
    await _ttsService.setSpeechRate(speed);
    notifyListeners();
  }
}
