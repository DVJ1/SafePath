import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/backend_service.dart';
import 'services/emergency_service.dart';
import 'services/hardware_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/tts_audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for accessible handheld usage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Core Services
  final storageService = await StorageService.init();
  final locationService = LocationService();
  final ttsService = TtsAudioService();
  await ttsService.init(initialRate: storageService.getTtsSpeed());

  final notificationService = NotificationService();
  await notificationService.init();

  final initialConfig = storageService.getEsp32Config();
  final hardwareService = HardwareService(initialConfig: initialConfig);

  final initialHistory = storageService.getEmergencyHistory();
  final backendService = MockCloudBackendService(initialHistory: initialHistory);

  final emergencyService = EmergencyService(
    storageService: storageService,
    locationService: locationService,
    ttsService: ttsService,
    notificationService: notificationService,
    backendService: backendService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storageService: storageService,
            hardwareService: hardwareService,
            ttsService: ttsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(
            storageService: storageService,
            hardwareService: hardwareService,
            locationService: locationService,
            emergencyService: emergencyService,
            ttsService: ttsService,
            notificationService: notificationService,
            backendService: backendService,
          ),
        ),
      ],
      child: const SafePathApp(),
    ),
  );
}

class SafePathApp extends StatelessWidget {
  const SafePathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'SafePath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
