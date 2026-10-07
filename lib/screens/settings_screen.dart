import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';
import 'caregiver_dashboard_screen.dart';
import 'contacts_screen.dart';
import 'hardware_settings_screen.dart';
import 'role_selection_screen.dart';
import 'user_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _userNameController;
  late TextEditingController _userPhoneController;
  late TextEditingController _userNotesController;
  late TextEditingController _userBloodController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<SettingsProvider>(context, listen: false).userProfile;
    _userNameController = TextEditingController(text: profile.name);
    _userPhoneController = TextEditingController(text: profile.phoneNumber);
    _userNotesController = TextEditingController(text: profile.medicalNotes);
    _userBloodController = TextEditingController(text: profile.bloodGroup);
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPhoneController.dispose();
    _userNotesController.dispose();
    _userBloodController.dispose();
    super.dispose();
  }

  void _saveUserProfile(SettingsProvider settings) {
    final cur = settings.userProfile;
    final updated = cur.copyWith(
      name: _userNameController.text.trim(),
      phoneNumber: _userPhoneController.text.trim(),
      medicalNotes: _userNotesController.text.trim(),
      bloodGroup: _userBloodController.text.trim(),
    );
    settings.updateUserProfile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User Profile Updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Accessibility'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Role Selection & Switcher
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Application Mode',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Mode: ${appState.isUserRole ? "Visually Impaired User" : "Caregiver Monitor"}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appState.isUserRole ? AppColors.primaryBlue : AppColors.safeGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                                );
                              },
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('Switch Role'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final next = appState.isUserRole ? 'caregiver' : 'user';
                                await appState.setRole(next);
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => next == 'user'
                                          ? const UserDashboardScreen()
                                          : const CaregiverDashboardScreen(),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: Text('To ${appState.isUserRole ? "Caregiver" : "User"}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Accessibility & Voice Settings
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.accessibility_rounded, color: AppColors.primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'Accessibility & Feedback',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('High Contrast Mode'),
                        subtitle: const Text('Vibrant borders and high-visibility color contrast'),
                        value: settings.isHighContrast,
                        onChanged: (_) => settings.toggleHighContrast(),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dark Mode Interface'),
                        subtitle: const Text('Saves OLED battery and reduces eye strain'),
                        value: settings.isDarkMode,
                        onChanged: (_) => settings.toggleDarkMode(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Voice Speech Rate: ${settings.ttsSpeed.toStringAsFixed(2)}x',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        value: settings.ttsSpeed,
                        min: 0.2,
                        max: 0.9,
                        divisions: 7,
                        label: '${settings.ttsSpeed.toStringAsFixed(2)}x',
                        onChanged: (val) => settings.setTtsSpeed(val),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          appState.speakCurrentStatus();
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Test Voice & Tactile Buzz'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. User Medical & Personal Profile
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.medical_services_rounded, color: AppColors.emergencyRed),
                              SizedBox(width: 8),
                              Text(
                                'User Safety & Medical Info',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ContactsScreen()),
                              );
                            },
                            child: const Text('Contacts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _userNameController,
                        decoration: const InputDecoration(
                          labelText: 'User Full Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _userPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'User Phone',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _userBloodController,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _userNotesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Medical & Emergency Notes (Allergies, conditions)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _saveUserProfile(settings),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save User Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. ESP32 Stick Hardware Shortcut
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: const Icon(Icons.memory_rounded, color: AppColors.primaryBlue),
                  title: const Text('ESP32 Wi-Fi Hardware Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('IP: ${settings.esp32Config.ipAddress} • ${settings.esp32Config.isSimulationMode ? "Simulation Active" : "Physical ESP32"}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HardwareSettingsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 5. Backend & Cloud Architecture Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_sync_rounded, color: AppColors.safeGreen),
                          SizedBox(width: 8),
                          Text(
                            'Backend & Cloud Sync Status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black38 : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Mode: Robust Local Storage + Reactive Broadcast Repository.\nReady for Firebase Cloud Firestore & FCM push notifications.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Version Footer
              Center(
                child: Text(
                  'SafePath v1.0.0 • Smart Blind Stick Companion',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
