import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'notifications.dart';
import 'supabase_service.dart';
import 'settings_page.dart';
import 'chat_page.dart';
import 'background_service.dart'; // ✅ Make sure this exists

class AlertCenterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alert Center',
      theme: ThemeData.dark(),
      home: AlertDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AlertDashboard extends StatefulWidget {
  @override
  _AlertDashboardState createState() => _AlertDashboardState();
}

class _AlertDashboardState extends State<AlertDashboard> {
  List<dynamic> _alerts = [];
  String supabaseUrl = '';
  String anonKey = '';
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => fetchAlerts());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      supabaseUrl = prefs.getString('supabaseUrl') ?? '';
      anonKey = prefs.getString('anonKey') ?? '';
    });
  }

  Future<void> fetchAlerts() async {
    final alerts = await fetchLatestAlerts(supabaseUrl, anonKey);
    setState(() {
      _alerts = alerts.reversed.toList();
      connected = alerts.isNotEmpty;
    });

    if (alerts.isNotEmpty) {
      await showNotification("🔔 New Alert", alerts.last['message'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('📡 Supabase Alerts'),
            Text(
              connected ? "🟢 Connected" : "🔴 Disconnected",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchAlerts),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsPage()),
              );
              await _loadSettings();
              await fetchAlerts();
            },
          ),
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatPage()),
              );
            },
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? Center(child: Text("No alerts detected. Chill."))
          : ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final msg = alert['message'] ?? '';
          final ts = alert['timestamp'] ?? '';
          final bot = alert['bot_name'] ?? '';
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade200.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Timestamp: $ts', style: TextStyle(fontSize: 15)),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    margin: EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Message: $msg', style: TextStyle(fontSize: 15)),
                  ),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Bot Name: $bot', style: TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            await initializeService();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Background service started')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start service: $e')),
            );
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Service'),
      ),
    );
  }
}
