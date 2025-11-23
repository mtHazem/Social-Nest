import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Chats'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_rounded, size: 80, color: Color(0xFF7C3AED)),
            const SizedBox(height: 16),
            const Text('Chat is coming soon!', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Real-time messaging will be available soon.', style: TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }
}