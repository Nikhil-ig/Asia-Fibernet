// lib/data/questions.dart
import '../models/question.dart';

const List<Question> questions = [
  // Initial quick replies
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

  // -----------------------------
  // Raise a Complaint (UPDATED)
  // -----------------------------
  Question(
    id: 'complaint_category',
    text: 'Select complaint category',
    options: [
      'No Dial Tone',
      'Call Drops Frequently',
      'Cross Connection / Disturbance',
      'Caller ID Not Working',
      'Billing / Recharge Issue',
      'Slow Dial / Delay in Connection',
      'No Internet Connectivity',
      'Slow Internet Speed',
      'Intermittent Disconnection',
      'Router Not Powering On',
      'WiFi Range / Coverage Issue',
      'Device Connection Problem',
      'Other',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  // -----------------------------
  // Subcategories Added as New Questions
  // -----------------------------
  Question(
    id: 'sub_no_dial_tone',
    text: 'Select subcategory for No Dial Tone',
    options: [
      'Complete Line Dead',
      'Partial Line Dead', 
      'Wiring Issue',
      'Exchange Fault',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_call_drops',
    text: 'Select subcategory for Call Drops Frequently',
    options: [
      'Network Fluctuation',
      'Signal Weak',
      'Device Compatibility Issue',
      'External Interference',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_cross_connection',
    text: 'Select subcategory for Cross Connection / Disturbance',
    options: [
      'Hearing Other Calls',
      'Voice Distortion',
      'Background Noise',
      'Line Interference',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_caller_id',
    text: 'Select subcategory for Caller ID Not Working',
    options: [
      'Caller ID Display Blank',
      'Wrong Number Displayed',
      'Intermittent Caller ID',
      'Device Not Supporting Caller ID',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_billing',
    text: 'Select subcategory for Billing / Recharge Issue',
    options: [
      'Wrong Bill Amount',
      'Recharge Not Reflecting',
      'Double Deduction',
      'Late Payment Update',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_slow_dial',
    text: 'Select subcategory for Slow Dial / Delay in Connection',
    options: [
      'Long Delay Before Ring',
      'Frequent Timeout',
      'Dial Tone Delayed',
      'Switching Issue',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_no_internet',
    text: 'Select subcategory for No Internet Connectivity',
    options: [
      'Fiber Cut',
      'Router Issue',
      'Configuration Problem',
      'Service Down at Exchange',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_slow_internet',
    text: 'Select subcategory for Slow Internet Speed',
    options: [
      'Speed Drop at Night',
      'Speed Below Plan',
      'WiFi Speed Low',
      'Multiple Device Load',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_disconnection',
    text: 'Select subcategory for Intermittent Disconnection',
    options: [
      'Frequent Disconnection',
      'DSL Light Blinking',
      'Loose Connection',
      'Faulty Modem',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_router_power',
    text: 'Select subcategory for Router Not Powering On',
    options: [
      'Power Adapter Faulty',
      'Router Hardware Issue',
      'Loose Power Cable',
      'Burnt Circuit',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_wifi_range',
    text: 'Select subcategory for WiFi Range / Coverage Issue',
    options: [
      'Weak WiFi Signal',
      'Coverage Not Reaching Room',
      'Interference from Other Devices',
      'Antenna Problem',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  Question(
    id: 'sub_device_connection',
    text: 'Select subcategory for Device Connection Problem',
    options: [
      'Unable to Connect Devices',
      'Authentication Failure',
      'Limited Connectivity',
      'Driver/Software Issue',
    ],
    correctIndex: -1,
    answer: 'Please describe your complaint in detail.',
  ),

  // Research publications
  Question(
    id: 'research_publications',
    text: 'Research publications',
    options: ['Select Year', 'Search by Name,Title'],
    correctIndex: -1,
    answer: 'Enter Paper Title',
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
