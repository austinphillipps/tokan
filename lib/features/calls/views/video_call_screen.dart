// lib/video_call_screen.dart
import 'package:flutter/material.dart';

class VideoCallScreen extends StatelessWidget {
  final String conversationId;
  final String friendId;

  const VideoCallScreen({
    Key? key,
    required this.conversationId,
    required this.friendId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder – intégrez ici votre solution d'appel vidéo (ex. JitsiMeet, Agora)
    return Scaffold(
      appBar: AppBar(
        title: Text("Appel vidéo avec $friendId"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 120, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Appel vidéo en cours...",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.videocam_off),
              label: const Text("Terminer l'appel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
