import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_center_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AlertCenterApp());
  await Firebase.initializeApp();

  // Get FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  print("🔑 FCM Token: $token");

  // Save to SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  if (token != null) {
    await prefs.setString('fcmToken', token);
  }


}
