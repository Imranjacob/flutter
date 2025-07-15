import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),

    );
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'mychannel',
      'Alert Service',
      channelDescription: 'Important alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }
}