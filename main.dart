import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'background_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  runApp(AlertCenterApp());
  await initializeService();

}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'alerts_channel',
    'Alerts',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
}

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
    if (supabaseUrl.isEmpty || anonKey.isEmpty) {
      print("⚠️ Supabase credentials not set.");
      setState(() => connected = false);
      return;
    }

    final url = Uri.parse('$supabaseUrl/rest/v1/alerts?select=*');
    final response = await http.get(
      url,
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _alerts = data.reversed.toList();
        connected = true;
      });
      if (data.isNotEmpty) {
        showNotification("🔔 New Alert", data.first['message'] ?? '');
      }
    } else {
      print('❌ Failed to fetch alerts: ${response.body}');
      setState(() => connected = false);
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchAlerts,
          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

bool _obscureKey = true;

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController urlController = TextEditingController();
  TextEditingController keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    urlController.text = prefs.getString('supabaseUrl') ?? '';
    keyController.text = prefs.getString('anonKey') ?? '';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabaseUrl', urlController.text);
    await prefs.setString('anonKey', keyController.text);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Settings saved.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("⚙️ Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(labelText: "Supabase URL"),
            ),
            SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: "Supabase anon key",
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureKey = !_obscureKey;
                    });
                  },
                ),
              ),
              obscureText: _obscureKey,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: Icon(Icons.save),
              label: Text("Save Settings"),
            )
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _controller = TextEditingController();
  String _response = '';

  Future<void> sendCommand() async {
    final command = _controller.text.trim();
    if (command.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('http://192.168.10.106:5000/status'));
      if (response.statusCode == 200) {
        setState(() => _response = response.body);
      } else {
        setState(() => _response = '❌ Failed to get status');
      }
    } catch (e) {
      setState(() => _response = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("💬 Command Center")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: "/status or other command"),
              onSubmitted: (_) => sendCommand(),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sendCommand,
              icon: Icon(Icons.send),
              label: Text("Send"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _response,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
