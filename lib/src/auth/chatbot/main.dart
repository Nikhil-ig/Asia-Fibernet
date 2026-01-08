// lib/main.dart
import 'package:flutter/material.dart';
import 'ui/chat_screen.dart';

void main() {
  runApp(const ChatBotApp());
}

class ChatBotApp extends StatelessWidget {
  const ChatBotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FAQ Chatbot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  } 
}