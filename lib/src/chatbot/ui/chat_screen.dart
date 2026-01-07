// lib/ui/chat_screen.dart
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../models/question.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Message> _messages = [];
  Question? _activeQuestion; // currently selected flow
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialMessage();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --------------------------------------------------------------
  // 1. Show initial message + quick replies
  // --------------------------------------------------------------
  void _showInitialMessage() {
    setState(() {
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: "Hi! I'm your Asia assistant. How can I help you today?",
        ),
      );

      const initialOptions = [
        'Check Internet Status',
        'View My Bill',
        'Upgrade/Downgrade Plan',
        'Report a Problem',
        'Talk to Agent',
        'Raise a Complaint',
      ];

      for (var opt in initialOptions) {
        _messages.add(
          _Message(sender: Sender.bot, text: opt, isQuickReply: true),
        );
      }
    });
  }

  // --------------------------------------------------------------
  // 2. Send user message
  // --------------------------------------------------------------
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_Message(sender: Sender.user, text: text));
    });
    _controller.clear();
    _handleUserInput(text.trim());
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 3. Handle user input
  // --------------------------------------------------------------
  void _handleUserInput(String input) {
    // Try to match a quick-reply or typed question
    final matched = questions.firstWhere(
      (q) => q.text.toLowerCase() == input.toLowerCase(),
      orElse:
          () => Question(
            text: input,
            options: ['I need more help'],
            correctIndex: 0,
            answer: 'We will get back to you shortly.',
          ),
    );

    setState(() {
      _activeQuestion = matched;
      _messages.add(_Message(sender: Sender.bot, text: matched.text));

      // Show options if any
      for (var opt in matched.options) {
        _messages.add(
          _Message(sender: Sender.bot, text: opt, isQuickReply: true),
        );
      }
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 4. Handle quick-reply tap
  // --------------------------------------------------------------
  void _onQuickReplyTap(String text) {
    setState(() {
      _messages.add(_Message(sender: Sender.user, text: text));
    });

    // === Special Flows ===
    if (text == 'Talk to Agent') {
      _handleTalkToAgent();
      return;
    }

    if (text == 'I need more help') {
      _handleFallbackHelp();
      return;
    }

    if (text == 'Report a Problem') {
      _handleReportProblem();
      return;
    }

    if (text == 'Raise a Complaint') {
      _handleRaiseComplaint();
      return;
    }

    // === Option selection inside a question ===
    if (_activeQuestion != null && _activeQuestion!.options.contains(text)) {
      _handleOptionSelection(text);
      return;
    }

    // === New question selected ===
    _handleUserInput(text);
  }

  // --------------------------------------------------------------
  // 5. Talk to Agent Flow
  // --------------------------------------------------------------
  void _handleTalkToAgent() {
    setState(() {
      _messages.add(
        _Message(
          sender: Sender.bot,
          text:
              'All agents are busy at the moment. Would you like to leave a message or get a callback?',
        ),
      );
      _messages.add(
        _Message(sender: Sender.bot, text: 'Leave Message', isQuickReply: true),
      );
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: 'Request Callback',
          isQuickReply: true,
        ),
      );
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 6. Fallback "I need more help"
  // --------------------------------------------------------------
  void _handleFallbackHelp() {
    setState(() {
      _messages.add(
        _Message(sender: Sender.bot, text: 'We will get back to you shortly.'),
      );
      // Show all initial options again
      const options = [
        'Check Internet Status',
        'View My Bill',
        'Upgrade/Downgrade Plan',
        'Report a Problem',
        'Talk to Agent',
        'Raise a Complaint',
      ];
      for (var opt in options) {
        _messages.add(
          _Message(sender: Sender.bot, text: opt, isQuickReply: true),
        );
      }
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 7. Report a Problem Flow
  // --------------------------------------------------------------
  void _handleReportProblem() {
    final q = questions.firstWhere((q) => q.id == 'problem_type');
    setState(() {
      _activeQuestion = q;
      _messages.add(_Message(sender: Sender.bot, text: q.text));
      for (var opt in q.options) {
        _messages.add(
          _Message(sender: Sender.bot, text: opt, isQuickReply: true),
        );
      }
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 8. Raise Complaint Flow
  // --------------------------------------------------------------
  void _handleRaiseComplaint() {
    final q = questions.firstWhere((q) => q.id == 'complaint_category');
    setState(() {
      _activeQuestion = q;
      _messages.add(_Message(sender: Sender.bot, text: q.text));
      for (var opt in q.options) {
        _messages.add(
          _Message(sender: Sender.bot, text: opt, isQuickReply: true),
        );
      }
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // 9. Handle option selection (e.g., "No Internet")
  // --------------------------------------------------------------
  void _handleOptionSelection(String selectedOption) {
    setState(() {
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: 'Thanks! Please describe the issue briefly.',
        ),
      );
      // In real app: collect text input → create ticket
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: 'Ticket created. An engineer will contact you soon.',
        ),
      );
      _activeQuestion = null;
      _messages.add(_Message(sender: Sender.bot, text: 'Anything else?'));
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: 'Check Internet Status',
          isQuickReply: true,
        ),
      );
      _messages.add(
        _Message(sender: Sender.bot, text: 'Talk to Agent', isQuickReply: true),
      );
    });
    _scrollToBottom();
  }

  // --------------------------------------------------------------
  // UI
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                if (m.isQuickReply) {
                  return _QuickReplyButton(
                    text: m.text,
                    onTap: () => _onQuickReplyTap(m.text),
                  );
                }
                return _ChatBubble(message: m);
              },
            ),
          ),
          // _buildInputBar(),
          SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF9C27B0)),
            onPressed: () => _sendMessage(_controller.text),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// Message Model
// -----------------------------------------------------------------
enum Sender { user, bot }

class _Message {
  final Sender sender;
  final String text;
  final bool isQuickReply;

  const _Message({
    required this.sender,
    required this.text,
    this.isQuickReply = false,
  });
}

// -----------------------------------------------------------------
// Chat Bubble
// -----------------------------------------------------------------
class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.sender == Sender.bot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[_BotAvatar(), const SizedBox(width: 10)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? const Color(0xFFF5F5F5) : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isBot ? Colors.black87 : Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          // if (!isBot) ...[
          //   const SizedBox(width: 10),
          //   const SizedBox(width: 36, height: 36),
          // ],
        ],
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'AF',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _QuickReplyButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _QuickReplyButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            ),
            onPressed: onTap,
            child: Text(text),
          ),
        ),
      ),
    );
  }
}
