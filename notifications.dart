import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> showNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'my_foreground',
    'Background Service',
    importance: Importance.max,
    priority: Priority.high,
  );

  const notificationDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
  );
}
