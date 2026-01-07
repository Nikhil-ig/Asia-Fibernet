// models/leave_model.dart

class LeaveModel {
  final int id;
  final int technicianId;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status; // e.g., "pending", "approved", "rejected"
  final String requestedAt;
  final String updatedAt;

  LeaveModel({
    required this.id,
    required this.technicianId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] as int,
      technicianId: json['technician_id'] as int,
      leaveType: json['leave_type'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      totalDays: json['total_days'] as int,
      reason: json['reason'] as String,
      status: json['status'] as String,
      requestedAt: json['requested_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'total_days': totalDays,
      'reason': reason,
      'status': status,
      'requested_at': requestedAt,
      'updated_at': updatedAt,
    };
  }
}