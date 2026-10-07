import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String emergencyChannelId = 'safepath_emergency_channel';
  static const String emergencyChannelName = 'SafePath Emergency Alerts';
  static const String emergencyChannelDesc = 'High priority emergency alerts for SOS and Fall Detection';

  static const String hazardChannelId = 'safepath_hazard_channel';
  static const String hazardChannelName = 'SafePath Hazard Warnings';
  static const String hazardChannelDesc = 'Obstacle and surface hazard notifications';

  Future<void> init() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      final androidPlatformPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlatformPlugin != null) {
        await androidPlatformPlugin.requestNotificationsPermission();

        const AndroidNotificationChannel emergencyChannel =
            AndroidNotificationChannel(
          emergencyChannelId,
          emergencyChannelName,
          description: emergencyChannelDesc,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        );

        const AndroidNotificationChannel hazardChannel =
            AndroidNotificationChannel(
          hazardChannelId,
          hazardChannelName,
          description: hazardChannelDesc,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        );

        await androidPlatformPlugin.createNotificationChannel(emergencyChannel);
        await androidPlatformPlugin.createNotificationChannel(hazardChannel);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init notice: $e');
      _isInitialized = false;
    }
  }

  /// Show high priority Emergency Alert notification
  Future<void> showEmergencyNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('Notification [Simulated Alert]: $title - $body');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        emergencyChannelId,
        emergencyChannelName,
        channelDescription: emergencyChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Show hazard or status update notification
  Future<void> showHazardNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        hazardChannelId,
        hazardChannelName,
        channelDescription: hazardChannelDesc,
        importance: Importance.high,
        priority: Priority.defaultPriority,
      );

      const NotificationDetails details = NotificationDetails(android: androidDetails);
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Failed to show hazard notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }
}
