// lib/services/apis/dummy_models.dart

// Response for Punch IN/OUT
class PunchResponse {
  final bool success;
  final String message;
  final String? punchTime;
  final String? status; // e.g., "Clocked In", "Clocked Out"

  PunchResponse({
    required this.success,
    required this.message,
    this.punchTime,
    this.status,
  });

  factory PunchResponse.fromJson(Map<String, dynamic> json) {
    return PunchResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      punchTime: json['punch_time'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'punch_time': punchTime,
      'status': status,
    };
  }
}

// Response for Leave Request
class LeaveRequestResponse {
  final bool success;
  final String message;
  final int? leaveId;

  LeaveRequestResponse({
    required this.success,
    required this.message,
    this.leaveId,
  });

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      leaveId: json['leave_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'leave_id': leaveId};
  }
}

// Model for Calendar Event (used in UI)
class CalendarEvent {
  final String type; // 'attendance' or 'leave'
  final String status; // 'Present', 'Absent', 'Approved', 'Pending'
  final String? punchIn;
  final String? punchOut;
  final String? leaveType;
  final String? remark;
  final DateTime date;

  CalendarEvent({
    required this.type,
    required this.status,
    this.punchIn,
    this.punchOut,
    this.leaveType,
    this.remark,
    required this.date,
  });

  // Factory to create from mock JSON
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      type: json['type'] ?? 'attendance',
      status: json['status'] ?? 'Unknown',
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      leaveType: json['leave_type'],
      remark: json['remark'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'punch_in': punchIn,
      'punch_out': punchOut,
      'leave_type': leaveType,
      'remark': remark,
      'date': date.toIso8601String(),
    };
  }
}

// Response for Calendar Data API
class CalendarDataResponse {
  final bool success;
  final String message;
  final List<CalendarEvent> events;

  CalendarDataResponse({
    required this.success,
    required this.message,
    required this.events,
  });

  factory CalendarDataResponse.fromJson(Map<String, dynamic> json) {
    List<CalendarEvent> eventList = [];
    if (json['events'] != null) {
      eventList = List<CalendarEvent>.from(
        (json['events'] as List).map((e) => CalendarEvent.fromJson(e)),
      );
    }

    return CalendarDataResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      events: eventList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}
