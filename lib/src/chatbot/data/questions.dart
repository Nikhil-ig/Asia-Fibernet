// lib/data/questions.dart
import '../models/question.dart';

const List<Question> questions = [
  // Initial quick-replies (from JSON)
  Question(
    id: 'initial_check_internet',
    text: 'Check Internet Status',
    options: [],
    correctIndex: -1,
    answer: '',
  ),
  
  Question(
    id: 'initial_view_bill',
    text: 'View My Bill',
    options: [],
    correctIndex: -1,
    answer: '',
  ),
  Question(
    id: 'initial_upgrade_plan',
    text: 'Upgrade/Downgrade Plan',
    options: [],
    correctIndex: -1,
    answer: '',
  ),
  Question(
    id: 'initial_report_problem',
    text: 'Report a Problem',
    options: [],
    correctIndex: -1,
    answer: '',
  ),
  Question(
    id: 'initial_talk_agent',
    text: 'Talk to Agent',
    options: [],
    correctIndex: -1,
    answer: '',
  ),
  Question(
    id: 'initial_raise_complaint',
    text: 'Raise a Complaint',
    options: [],
    correctIndex: -1,
    answer: '',
  ),

   // Upgrade or Downgrade Plan
  Question(
    id: 'initial_upgrade_plan',
    text: 'Upgrade/Downgrade Plan',
    options: [
      'No Internet',
      'Slow Speed',
      'Frequent Disconnections',
      'Router Not Working',
    ],
    correctIndex: -1,
    answer: 'Please describe the issue briefly.',
  ),
  // Report a Problem
  Question(
    id: 'problem_type',
    text: 'What issue are you facing?',
    options: [
      'No Internet',
      'Slow Speed',
      'Frequent Disconnections',
      'Router Not Working',
    ],
    correctIndex: -1,
    answer: 'Please describe the issue briefly.',
  ),

  // Raise a Complaint
  Question(
    id: 'complaint_category',
    text: 'What is your complaint about?',
    options: [
      'Billing Issue',
      'Poor Service',
      'Rude Staff',
      'Installation Delay',
      'Other',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  // Agent unavailable
  Question(
    id: 'agent_unavailable',
    text:
        'All agents are busy. Would you like to leave a message or get a callback?',
    options: ['Leave Message', 'Request Callback'],
    correctIndex: -1,
    answer: 'We will get back to you shortly.',
  ),

  // Fallback
  Question(
    id: 'fallback_help',
    text: 'I need more help',
    options: [],
    correctIndex: -1,
    answer: 'We will get back to you shortly.',
    
  ),
];
