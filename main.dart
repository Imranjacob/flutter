import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(AlertCenterApp());
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
        _alerts = data.reversed.toList(); // Show newest first
      });
    } else {
      print('❌ Failed to fetch alerts: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📡 Supabase Alerts'),
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
              await _loadSettings(); // Reload if changed
              await fetchAlerts();
            },
          ),
        ],
      ),
      body: _alerts.isEmpty
          ? Center(child: Text("No alerts detected.Chill."))
          : ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          final msg = alert['message'] ?? '';
          final ts = alert['timestamp'] ?? '';
          final bot = alert['botname'] ?? '';
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade200.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Timestamp: $ts',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Message: $msg',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Bot Name: $bot',
                      style: TextStyle(fontSize: 16),
                    ),
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
                  icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off,
                  ),
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
