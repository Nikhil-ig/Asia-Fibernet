/// Model for ticket closure with category and subcategory
class TicketClosureModel {
  final String category;
  final String subcategory;
  final String remark;
  final bool isSolved;

  TicketClosureModel({
    required this.category,
    required this.subcategory,
    required this.remark,
    required this.isSolved,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'subcategory': subcategory,
    'remark': remark,
    'is_solved': isSolved,
  };
}

/// Categories and subcategories for ticket closure
class TicketClosureOptions {
  static const Map<String, List<String>> categories = {
    'Technical Issue': [
      'Connection Problem',
      'Speed Issue',
      'Equipment Malfunction',
      'Network Interruption',
      'Configuration Error',
    ],
    'Hardware': [
      'Modem Not Working',
      'Router Failure',
      'Cable Damage',
      'Splitter Issue',
      'Connector Problem',
    ],
    'Service': [
      'Plan Upgrade',
      'Bill Query',
      'Service Upgrade',
      'Service Downgrade',
      'Account Issue',
    ],
    'Installation': [
      'Installation Complete',
      'Reinstallation Done',
      'Cable Laid',
      'Equipment Installed',
      'Testing Completed',
    ],
    'Other': [
      'Customer Request',
      'Self Resolution',
      'Transferred to Support',
      'Escalated',
      'Pending Investigation',
    ],
  };

  static List<String> getSubcategories(String category) {
    return categories[category] ?? [];
  }
}

/// API Response for work live status update
class WorkLiveStatusResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? data;

  WorkLiveStatusResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory WorkLiveStatusResponse.fromJson(Map<String, dynamic> json) {
    return WorkLiveStatusResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  bool get isSuccess => status == 'success';
}
