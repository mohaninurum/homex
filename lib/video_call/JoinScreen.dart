import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatsapp_chat_direct/video_call/CallScreen.dart';


class JoinScreen extends StatefulWidget {
  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController roomId = TextEditingController();

  @override
  void initState() {

    Setpermisstion();
    super.initState();
  }

  Setpermisstion() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase WebRTC Group Call")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: roomId,
              decoration: const InputDecoration(
                hintText: "Enter Room ID",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallScreen(roomId: roomId.text),
                  ),
                );
              },
              child: const Text("Join Call"),
            ),
          ],
        ),
      ),
    );
  }
}
