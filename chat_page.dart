import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
