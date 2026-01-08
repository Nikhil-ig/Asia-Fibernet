// lib/ui/chat_screen.dart
import 'dart:convert';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/theme/colors.dart';

import '../widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  String? _selectedCategory;
  String? _selectedSubCategory;
  Map<String, List<String>> _apiCategories = {};
  final String _baseUrl = 'https://asiafibernet.in'; // Base URL for API calls
  final String token =
      // 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjdXN0b21lcl9pZCI6NCwibW9iaWxlIjoiNTUyMzIzNTY1NiIsImlhdCI6MTc2NzYxNTI3MiwiZXhwIjoxNzY3OTc1MjcyfQ.iQD_OeESMnP85mNoOApdf2hPjNxX85LLznFVkPlr6hM'; // Base URL for API calls
      AppSharedPref.instance.getToken();

  String generateTicketNo() {
    final now = DateTime.now();
    final timePart = _formatDateTime(now);
    final randPart = (now.millisecondsSinceEpoch % 1000).toString().padLeft(
      3,
      '0',
    );
    return 'TKT-B-$timePart-$randPart';
  }

  // String generateTicketNoByTech() {
  //   final now = DateTime.now();
  //   final timePart = _formatDateTime(now);
  //   final randPart = (now.millisecondsSinceEpoch % 1000).toString().padLeft(
  //         3,
  //         '0',
  //       );
  //   return 'TKT-T-$timePart-$randPart';
  // }

  String _formatDateTime(DateTime dt) {
    return "${dt.year % 100}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}-${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}";
  }

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

    if (_activeQuestion?.id == 'agent_leave_message') {
      _submitAgentMessage(text.trim());
      return;
    }

    if (_selectedCategory != null && _activeQuestion == null) {
      _submitComplaint(text.trim());
      return;
    }

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

    if (text == 'Leave Message') {
      _handleLeaveMessage();
      return;
    }

    if (text == 'Request Callback') {
      _handleRequestCallback();
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
      print('>>>>>>>>>>>>>Raised complaint');
      return;
    }

    // === Option selection inside a question ===
    // if (_activeQuestion != null && _activeQuestion!.options.contains(text)) {
    if (_activeQuestion != null) {
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
    _selectedCategory = null;
    _selectedSubCategory = null;
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

  void _handleLeaveMessage() {
    setState(() {
      _activeQuestion = const Question(
        id: 'agent_leave_message',
        text: 'Please type your message below.',
        options: [],
        correctIndex: -1,
        answer: '',
      );
      _messages.add(
        _Message(sender: Sender.bot, text: 'Please type your message below.'),
      );
    });
    _scrollToBottom();
  }

  Future<void> _submitAgentMessage(String message) async {
    setState(() {
      _activeQuestion = null;
    });
    await _submitGenericRequest('Agent Message', message);
  }

  Future<void> _handleRequestCallback() async {
    await _submitGenericRequest(
      'Callback Request',
      'User requested a callback.',
    );
  }

  Future<void> _submitGenericRequest(
    String category,
    String description,
  ) async {
    final ticketNo = generateTicketNo();
    setState(() {
      _messages.add(_Message(sender: Sender.bot, text: 'Processing...'));
    });
    _scrollToBottom();

    try {
      final uri = Uri.parse('$_baseUrl/af/api/raise_complaint.php');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "registered_mobile": "4654654646",
          'category': category,
          'sub_category': 'General',
          'description': description,
          'ticket_no': ticketNo,
        }),
      );

      if (!mounted) return;
      String msg;
      print(response.body);
      if (response.statusCode == 200) {
        if (category == 'Callback Request') {
          final agentNum =
              (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
                  .toString();
          msg =
              'Success! Your Ticket number is $ticketNo. Agent #$agentNum will call you shortly.';
        } else {
          msg = 'Success! Your Ticket number is $ticketNo.';
        }
      } else {
        msg = 'Something went wrong. Please try again.';
      }
      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: msg));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: 'Error: $e'));
      });
    }
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
  Future<void> _handleRaiseComplaint() async {
    setState(() {
      _messages.add(
        _Message(sender: Sender.bot, text: 'Fetching categories...'),
      );
    });
    _scrollToBottom();

    List<String> options = [];
    _apiCategories.clear();

    try {
      final uri = Uri.parse('$_baseUrl/af/api/get_ticket_categroy.php');
      print('Fetching categories from $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      print(
        "get_ticket_categroy >>>>>>>>>>>>>>>>>>\nResponse Status:${response.body}",
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['data'] != null) {
          final data = jsonResponse['data'] as List;
          for (var item in data) {
            final catName = item['category_name'].toString();
            options.add(catName);

            if (item['subcategories'] != null) {
              List<String> subs = [];
              for (var sub in item['subcategories']) {
                subs.add(sub['subcategory_name'].toString().trim());
              }
              _apiCategories[catName] = subs;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }

    if (!mounted) return;
    final q =
        options.isNotEmpty
            ? Question(
              id: 'complaint_category',
              text: 'Select complaint category',
              options: options,
              correctIndex: -1,
              answer: 'Please describe your complaint in detail.',
            )
            : questions.firstWhere((q) => q.id == 'complaint_category');

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
    // 1. Check if we are in the main complaint category selection
    if (_activeQuestion?.id == 'complaint_category') {
      // Check dynamic API categories first
      if (_apiCategories.containsKey(selectedOption)) {
        final subs = _apiCategories[selectedOption];
        if (subs != null && subs.isNotEmpty) {
          setState(() {
            _selectedCategory = selectedOption;
            final subQ = Question(
              id: 'sub_dynamic',
              text: 'Select subcategory for $selectedOption',
              options: subs,
              correctIndex: -1,
              answer: '',
            );
            _activeQuestion = subQ;
            _messages.add(_Message(sender: Sender.bot, text: subQ.text));
            for (var opt in subQ.options) {
              _messages.add(
                _Message(sender: Sender.bot, text: opt, isQuickReply: true),
              );
            }
          });
          _scrollToBottom();
          return;
        }
      }

      // Check if there's a sub-question for this category
      try {
        final subQ = questions.firstWhere(
          (q) => q.text == 'Select subcategory for $selectedOption',
        );
        // Found sub-question -> Show it
        setState(() {
          _selectedCategory = selectedOption; // Store main category
          _activeQuestion = subQ;
          _messages.add(_Message(sender: Sender.bot, text: subQ.text));
          for (var opt in subQ.options) {
            _messages.add(
              _Message(sender: Sender.bot, text: opt, isQuickReply: true),
            );
          }
        });
        _scrollToBottom();
        return;
      } catch (e) {
        // No sub-question found -> proceed to description
      }
    }

    // 2. Check if we are in a sub-category selection
    // if (_activeQuestion?.id != null && _activeQuestion!.id!.startsWith('sub_')) {
    if (_activeQuestion?.id != null) {
      _submitGenericRequest(
        selectedOption,
        _activeQuestion!.id!.startsWith('sub_')
            ? 'Complaint under ${_selectedCategory ?? "General"} - $selectedOption'
            : selectedOption,
      );
      setState(() {
        _selectedSubCategory = selectedOption;
        _messages.add(
          _Message(
            sender: Sender.bot,
            text: 'Thanks! Please describe the issue briefly.',
          ),
        );
        _activeQuestion = null;
      });
      _scrollToBottom();
      return;
    }

    // 3. Default behavior (Report Problem or Fallback)
    setState(() {
      _selectedCategory = selectedOption;
      _selectedSubCategory = null;
      _messages.add(
        _Message(
          sender: Sender.bot,
          text: 'Thanks! Please describe the issue briefly.',
        ),
      );
      _activeQuestion = null;
    });
    _scrollToBottom();
  }

  Future<void> _submitComplaint(String description) async {
    final category = _selectedCategory ?? 'General';
    final subCategory = _selectedSubCategory ?? 'General';

    setState(() {
      _selectedCategory = null;
      _selectedSubCategory = null;
      _messages.add(_Message(sender: Sender.bot, text: 'Submitting ticket...'));
    });
    _scrollToBottom();

    try {
      final uri = Uri.parse('$_baseUrl/af/api/raise_complaint.php');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },

        body: jsonEncode({
          'category': category,
          'sub_category': subCategory,
          'description':
              '$description (Selected: $category${subCategory != 'General' ? " - $subCategory" : ""})',
          'ticket_no': generateTicketNo(),
        }),
      );
      if (!mounted) return;

      print(
        "==================_submitComplaint===============\nResponse Status: ${response.statusCode}",
      );

      final responseText =
          response.statusCode == 200
              ? 'Ticket created successfully. An engineer will contact you soon.'
              : 'Failed to create ticket. Please try again later.';

      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: responseText));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: 'Error: $e'));
      });
    }

    setState(() {
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
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF9C27B0),
      //   foregroundColor: Colors.white,
      //   leading: const BackButton(),
      //   title: const Text('Asia Support'),
      // ),
      body: MyBackgroundWidget(
        child: Column(
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
          ],
        ),
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
            icon: const Icon(Icons.send, color: AppColors.primary),
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
        // crossAxisAlignment: CrossAxisAlignment.start,
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
          if (!isBot) ...[
            // const SizedBox(width: 0),
            // const SizedBox(width: 36, height: 36),
          ],
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
        'B',
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
              side: BorderSide(color: AppColors.primary),
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
