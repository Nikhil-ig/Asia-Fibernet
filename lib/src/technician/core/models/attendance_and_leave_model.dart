// models/attendance_model.dart

class AttendanceModel {
  final int? id;
  final String? intime;
  final String? outtime;
  final String inLat;
  final String inLong;
  final String? outLat;
  final String? outLong;
  final String date;
  final int technicianId;
  final String createdAt;
  final String updatedAt;

  AttendanceModel({
    this.id = -1, // default instead of required,
    this.intime,
    this.outtime,
    required this.inLat,
    required this.inLong,
    this.outLat,
    this.outLong,
    required this.date,
    required this.technicianId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] is int ? json['id'] as int : -1,
      intime: json['intime'] as String?,
      outtime: json['outtime'] as String?,
      inLat: json['in_lat'] as String? ?? '',
      inLong: json['in_long'] as String? ?? '',
      outLat: json['out_lat'] as String?,
      outLong: json['out_long'] as String?,
      date: json['date'] as String? ?? '',
      technicianId:
          json['technician_id'] is int ? json['technician_id'] as int : 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intime': intime,
      'outtime': outtime,
      'in_lat': inLat,
      'in_long': inLong,
      'out_lat': outLat,
      'out_long': outLong,
      'date': date,
      'technician_id': technicianId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

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

// lib/technician/core/models/holiday_model.dart

// lib/technician/core/models/holiday_model.dart

class HolidayModel {
  final int id;
  final String date; // Date string from API
  final String title;
  final String? description;

  HolidayModel({
    required this.id,
    required this.date,
    required this.title,
    this.description,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    // Handle potential type issues gracefully
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'] as int;
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id']) ?? 0;
    }

    // Ensure date and name are not null or empty
    final String parsedDate = json['holiday_date'] as String? ?? '';
    final String parsedName = json['title'] as String? ?? 'Unknown Holiday';

    return HolidayModel(
      id: parsedId,
      date: parsedDate,
      title: parsedName,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'holiday_date': date,
      'title': title,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'HolidayModel(id: $id, holiday_date: "$date", title: "$title", description: $description)';
  }
}

class AbsentData {
  final String status;
  final String month;
  final int technicianId;
  final List<DateTime> absentDays;
  final int absentCount;

  AbsentData({
    required this.status,
    required this.month,
    required this.technicianId,
    required this.absentDays,
    required this.absentCount,
  });

  factory AbsentData.fromJson(Map<String, dynamic> json) => AbsentData(
    status: json["status"],
    month: json["month"],
    technicianId: json["technician_id"],
    absentDays: List<DateTime>.from(
      json["absent_days"].map((x) => DateTime.parse(x)),
    ),
    absentCount: json["absent_count"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "month": month,
    "technician_id": technicianId,
    "absent_days": List<dynamic>.from(
      absentDays.map(
        (x) =>
            "${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}",
      ),
    ),
    "absent_count": absentCount,
  };
}
