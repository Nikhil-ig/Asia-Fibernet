// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isBot;
  final String text;
  const MessageBubble({super.key, required this.isBot, required this.text});

  @override
  Widget build(BuildContext context) {
    final align = isBot ? Alignment.centerLeft : Alignment.centerRight;
    final color = isBot
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.primaryContainer;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text),
      ),
    );
  }
}
