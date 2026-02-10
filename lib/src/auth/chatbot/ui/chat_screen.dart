// lib/ui/chat_screen.dart
import 'dart:convert';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/theme/widgets/app_drawer.dart';
import 'package:get/get.dart';

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
  final Map<String, List<String>> _apiCategories = {};
  final String _baseUrl = 'https://asiafibernet.in';
  final String? token = AppSharedPref.instance.getToken();

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

  // Add loading indicator message
  void _addLoadingMessage() {
    // setState(() {
    //   _messages.add(_Message(sender: Sender.bot, isLoading: true, text: ''));
    // });
    _scrollToBottom();
  }

  // Remove last loading message
  void _removeLoadingMessage() {
    if (_messages.isNotEmpty && _messages.last.isLoading) {
      setState(() {
        _messages.removeLast();
      });
    }
  }

  // Navigate to Plan screen
  void _navigateToPlanScreen() {
    Navigator.of(context).pop(); // Close the chatbot first
    Future.delayed(Duration(milliseconds: 300), () {
      Get.toNamed('/bsnl-plans');
    });
  }

  // --------------------------------------------------------------
  // 2. Handle user input
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

    if (text == 'Upgrade/Downgrade Plan') {
      _navigateToPlanScreen();
      return;
    }

    if (text == 'Report a Problem') {
      // _handleReportProblem();
      _handleRaiseComplaint();
      return;
    }

    if (text == 'Raise a Complaint') {
      _handleRaiseComplaint();

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
      // _messages.add(
      //   _Message(sender: Sender.bot, text: 'Leave Message', isQuickReply: true),
      // );
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
    // await _submitGenericRequest(
    //   'Callback Request',
    //   'User requested a callback.',
    // );
    makePhoneCall();
  }

  Future<void> _submitGenericRequest(
    String category,
    String description,
  ) async {
    _addLoadingMessage();

    try {
      final uri = Uri.parse('$_baseUrl/af/api/raise_complaint.php');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ticket_no': '12345',
          'registered_mobile': AppSharedPref.instance.getMobileNumber(),
          'category': category,
          'sub_category': 'General',
          'description': description,
        }),
      );

      if (!mounted) return;

      String msg = 'Something went wrong. Please try again.';
      bool isSuccess = false;
      String ticketNo = '';

      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('API Response: $jsonResponse');

        // Check if response has status == success
        if (jsonResponse['status'] == 'success') {
          isSuccess = true;
          // Try to get ticket_no if available (for array format)
          if (jsonResponse is List && jsonResponse.isNotEmpty) {
            ticketNo = jsonResponse[0]['ticket_no'] ?? '';
          } else if (jsonResponse['ticket_no'] != null) {
            ticketNo = jsonResponse['ticket_no'].toString();
          } else if (jsonResponse['complaint_id'] != null) {
            // Use complaint_id as fallback
            ticketNo = jsonResponse['complaint_id'].toString();
          }
          debugPrint('Extracted Ticket/Complaint ID: $ticketNo');
        } else if (jsonResponse['status'] == 'error') {
          msg =
              '❌ Error: ${jsonResponse['message'] ?? 'Failed to process request'}';
        }
      } catch (e) {
        debugPrint('Error parsing response: $e');
        // If response code is 200, try to parse
        if (response.statusCode == 200) {
          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['status'] == 'success') {
              isSuccess = true;
              if (jsonResponse['complaint_id'] != null) {
                ticketNo = jsonResponse['complaint_id'].toString();
              }
            }
          } catch (parseError) {
            debugPrint('Secondary parse error: $parseError');
          }
        }
      }

      if (isSuccess && ticketNo.isNotEmpty) {
        if (category == 'Callback Request') {
          final agentNum =
              (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
                  .toString();
          msg =
              '✅ Success!\n\nYour Ticket: #$ticketNo\nAgent #$agentNum will call you shortly.\n\nThank you for contacting us!';
        } else {
          msg =
              '✅ Success!\n\nYour Ticket: #$ticketNo\n\nThank you for reaching out!';
        }
      }

      // Replace the loading message with the actual response
      _removeLoadingMessage();
      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: msg));
      });

      // If successful, show follow-up options after a delay
      if (isSuccess && ticketNo.isNotEmpty) {
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _messages.add(
                _Message(
                  sender: Sender.bot,
                  text: 'Is there anything else I can help with?',
                ),
              );
              // _messages.add(
              // _Message(
              //   sender: Sender.bot,
              //   text: 'Check Internet Status',
              //   isQuickReply: true,
              // ),
              // );
              _messages.add(
                _Message(
                  sender: Sender.bot,
                  text: 'Talk to Agent',
                  isQuickReply: true,
                ),
              );
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      _removeLoadingMessage();
      setState(() {
        _messages.add(
          _Message(
            sender: Sender.bot,
            text: '❌ Error: ${e.toString()}\n\nPlease try again later.',
          ),
        );
      });
    }
    _scrollToBottom();
  } // --------------------------------------------------------------

  // 6. Fallback "I need more help"
  // --------------------------------------------------------------
  void _handleFallbackHelp() {
    setState(() {
      _messages.add(
        _Message(sender: Sender.bot, text: 'We will get back to you shortly.'),
      );
      // Show all initial options again
      const options = [
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
    _addLoadingMessage();
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
    _removeLoadingMessage();
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
    });
    _addLoadingMessage();
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
          'ticket_no': '12345',
          'registered_mobile': AppSharedPref.instance.getMobileNumber(),
          'category': category,
          'sub_category': subCategory,
          'description':
              '$description (Selected: $category${subCategory != 'General' ? " - $subCategory" : ""})',
        }),
      );
      if (!mounted) return;

      String responseText = 'Failed to create ticket. Please try again later.';
      bool isSuccess = false;
      String ticketNo = '';

      try {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('API Response: $jsonResponse');

        // Check if response has status == success
        if (jsonResponse['status'] == 'success') {
          isSuccess = true;
          // Try to get ticket_no if available (for array format)
          if (jsonResponse is List && jsonResponse.isNotEmpty) {
            ticketNo = jsonResponse[0]['ticket_no'] ?? '';
          } else if (jsonResponse['ticket_no'] != null) {
            ticketNo = jsonResponse['ticket_no'].toString();
          } else if (jsonResponse['complaint_id'] != null) {
            // Use complaint_id as fallback
            ticketNo = jsonResponse['complaint_id'].toString();
          }
          debugPrint('Extracted Ticket/Complaint ID: $ticketNo');
        } else if (jsonResponse['status'] == 'error') {
          responseText =
              '❌ Error: ${jsonResponse['message'] ?? 'Failed to create ticket'}';
        }
      } catch (e) {
        debugPrint('Error parsing response: $e');
        // If response code is 200, try to parse
        if (response.statusCode == 200) {
          try {
            final jsonResponse = jsonDecode(response.body);
            if (jsonResponse['status'] == 'success') {
              isSuccess = true;
              if (jsonResponse['complaint_id'] != null) {
                ticketNo = jsonResponse['complaint_id'].toString();
              }
            }
          } catch (parseError) {
            debugPrint('Secondary parse error: $parseError');
          }
        }
      }

      if (isSuccess && ticketNo.isNotEmpty) {
        responseText =
            '✅ Success!\n\nYour Ticket: #$ticketNo\n\nAn engineer will contact you shortly.\n\nThank you for reporting this issue!';
      }

      // Replace loading message with actual response
      _removeLoadingMessage();
      setState(() {
        _messages.add(_Message(sender: Sender.bot, text: responseText));
      });

      // If successful, show follow-up options after a delay
      if (isSuccess && ticketNo.isNotEmpty) {
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _messages.add(
                _Message(sender: Sender.bot, text: 'Anything else?'),
              );
              _messages.add(
                _Message(
                  sender: Sender.bot,
                  text: 'Check Internet Status',
                  isQuickReply: true,
                ),
              );
              _messages.add(
                _Message(
                  sender: Sender.bot,
                  text: 'Talk to Agent',
                  isQuickReply: true,
                ),
              );
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      _removeLoadingMessage();
      setState(() {
        _messages.add(
          _Message(
            sender: Sender.bot,
            text: '❌ Error: ${e.toString()}\n\nPlease try again later.',
          ),
        );
      });
    }
  }

  // --------------------------------------------------------------
  // UI
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyBackgroundWidget(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  // if (m.isLoading) {
                  //   return const _LoadingBubble();
                  // }
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
          ],
        ),
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
  final bool isLoading;

  const _Message({
    required this.sender,
    required this.text,
    this.isQuickReply = false,
    this.isLoading = false,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isBot) ...[_BotAvatar(), const SizedBox(width: 10)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                    isBot
                        ? LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        )
                        : LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isBot ? Colors.grey : Colors.blue).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isBot ? Colors.black87 : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// Loading Bubble
// -----------------------------------------------------------------
class _LoadingBubble extends StatefulWidget {
  const _LoadingBubble();

  @override
  State<_LoadingBubble> createState() => _LoadingBubbleState();
}

class _LoadingBubbleState extends State<_LoadingBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _BotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              width: 40,
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (index) {
                  return ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                          index * 0.2,
                          1.0,
                          curve: Curves.easeInOut,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
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
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
