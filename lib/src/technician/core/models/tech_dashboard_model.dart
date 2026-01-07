// tech_dashboard_model.dart

class TechDashboardModel {
  final String status;
  final String message;
  final Data data;

  TechDashboardModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TechDashboardModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return TechDashboardModel(
      status: json['status'] as String? ?? 'error',
      message: json['message'] as String? ?? 'Unknown error',
      data: Data.fromJson(json['data'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.toJson(),
  };

  @override
  String toString() =>
      'TechDashboardModel(status: $status, message: $message, data: $data)';
}

class Data {
  final int id;
  final int? accountId;
  final String role;
  final String? accountType;
  final String contactName;
  final String? companyName;
  final String? address;
  final String city;
  final String state;
  final String? zipCode;
  final String? workphnumber;
  final String? cellphnumber;
  final String? otherphnumber;
  final String? email;
  final String? websiteAddress;
  final String notes;
  final String creationDate;
  final Ratings ratings;
  final Notifications notifications;
  final Tickets tickets;

  Data({
    required this.id,
    this.accountId,
    required this.role,
    this.accountType,
    required this.contactName,
    this.companyName,
    this.address,
    required this.city,
    required this.state,
    this.zipCode,
    this.workphnumber,
    this.cellphnumber,
    this.otherphnumber,
    this.email,
    this.websiteAddress,
    this.notes = '',
    required this.creationDate,
    required this.ratings,
    required this.notifications,
    required this.tickets,
  });

  factory Data.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Data(
      id: _toInt(json['ID']) ?? -1,
      accountId: _toInt(json['AccountID']),
      role: json['role'] as String? ?? 'unknown',
      accountType: json['AccountType'] as String?,
      contactName: json['ContactName'] as String? ?? 'N/A',
      companyName: (json['CompanyName'] as String?)?.trim(),
      address: (json['Address'] as String?)?.trim(),
      city: json['City'] as String? ?? 'N/A',
      state: json['State'] as String? ?? 'N/A',
      zipCode: json['ZipCode'] as String?,
      workphnumber: _toPhoneString(json['Workphnumber']),
      cellphnumber: _toPhoneString(json['Cellphnumber']),
      otherphnumber: _toPhoneString(json['Otherphnumber']),
      email: json['Email'] as String?,
      websiteAddress: (json['WebsiteAddress'] as String?)?.trim(),
      notes: json['Notes'] as String? ?? '',
      creationDate: json['CreationDate'] as String? ?? 'N/A',
      ratings: Ratings.fromJson(json['ratings'] as Map<String, dynamic>?),
      notifications: Notifications.fromJson(
        json['notifications'] as Map<String, dynamic>?,
      ),
      tickets: Tickets.fromJson(json['tickets'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
    'ID': id,
    'AccountID': accountId,
    'role': role,
    'AccountType': accountType,
    'ContactName': contactName,
    'CompanyName': companyName,
    'Address': address,
    'City': city,
    'State': state,
    'ZipCode': zipCode,
    'Workphnumber': workphnumber,
    'Cellphnumber': cellphnumber,
    'Otherphnumber': otherphnumber,
    'Email': email,
    'WebsiteAddress': websiteAddress,
    'Notes': notes,
    'CreationDate': creationDate,
    'ratings': ratings.toJson(),
    'notifications': notifications.toJson(),
    'tickets': tickets.toJson(),
  };

  @override
  String toString() {
    return 'Data(id: $id, contactName: $contactName, email: $email, phone: $workphnumber)';
  }

  // Helper to safely convert dynamic → int?
  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {}
    }
    return null;
  }

  // Helper to safely convert phone numbers to String
  static String? _toPhoneString(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toString();
    if (value is String) return value.trim().isNotEmpty ? value.trim() : null;
    return null;
  }
}

class Ratings {
  final String? avgRating;
  final int totalRatings;

  Ratings({this.avgRating, required this.totalRatings});

  factory Ratings.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Ratings(
      avgRating: json['avg_rating'] as String?,
      totalRatings: _toInt(json['total_ratings']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'avg_rating': avgRating,
    'total_ratings': totalRatings,
  };

  @override
  String toString() =>
      'Ratings(avgRating: $avgRating, totalRatings: $totalRatings)';

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {}
    }
    return null;
  }
}

class Notifications {
  final int totalNotifications;

  Notifications({required this.totalNotifications});

  factory Notifications.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Notifications(
      totalNotifications: _toInt(json['total_notifications']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'total_notifications': totalNotifications};

  @override
  String toString() => 'Notifications(totalNotifications: $totalNotifications)';

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {}
    }
    return null;
  }
}

class Tickets {
  final String? openTickets;
  final String? closedTickets;
  final String? resolvedTickets;
  final int totalTickets;

  Tickets({
    this.openTickets,
    this.closedTickets,
    this.resolvedTickets,
    required this.totalTickets,
  });

  factory Tickets.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return Tickets(
      openTickets: json['open_tickets'] as String?,
      closedTickets: json['closed_tickets'] as String?,
      resolvedTickets: json['resolved_tickets'] as String?,
      totalTickets: _toInt(json['total_tickets']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'open_tickets': openTickets,
    'closed_tickets': closedTickets,
    'resolved_tickets': resolvedTickets,
    'total_tickets': totalTickets,
  };

  @override
  String toString() =>
      'Tickets(open: $openTickets, closed: $closedTickets, resolved: $resolvedTickets, total: $totalTickets)';

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {}
    }
    return null;
  }
}
