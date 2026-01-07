// enum UserRole {
//   customer,
//   technician,
//   admin,
//   unknown;

//   // Helper to convert string to enum safely
//   static UserRole fromString(String? role) {
//     if (role == null) return unknown;
//     return switch (role.toLowerCase()) {
//       'customer' => customer,
//       'technician' => technician,
//       'admin' => admin,
//       _ => unknown,
//     };
//   }
// }

// class VerifyMobileResponse {
//   final String status; // Can be "success" or "error"
//   final String message;
//   final String token; // Now always String (even if empty)
//   final Data? data; // Optional: null if data is {} or absent
//   final String? action; // Present in some cases
//   final String? serviceStatus; // NEW: optional service_status field

//   VerifyMobileResponse({
//     required this.status,
//     required this.message,
//     required this.token, // No longer optional — empty string if not present
//     this.data,
//     this.action,
//     this.serviceStatus,
//   });

//   factory VerifyMobileResponse.fromJson(Map<String, dynamic> json) {
//     final rawData = json['data'];
//     Data? parsedData;

//     // Only parse data if it's a non-empty map with expected keys
//     if (rawData is Map<String, dynamic> && rawData.isNotEmpty) {
//       parsedData = Data.fromJson(rawData);
//     }
//     // else leave as null — indicates no meaningful data

//     return VerifyMobileResponse(
//       status: json['status'] as String? ?? 'unknown',
//       message: json['message'] as String? ?? '',
//       token: json['token'] as String? ?? '',
//       action: json['action'] as String?,
//       serviceStatus: json['service_status'] as String?,
//       data: parsedData,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'status': status,
//       'message': message,
//       'token': token,
//       'action': action,
//       'service_status': serviceStatus,
//       'data': data?.toJson() ?? {}, // Serialize as {} if null
//     };
//   }

//   @override
//   String toString() {
//     return 'VerifyMobileResponse(status: $status, message: $message, token: $token, data: $data, action: $action, serviceStatus: $serviceStatus)';
//   }
// }

// class Data {
//   final int id;
//   final UserRole userRole;

//   Data({required this.id, required this.userRole});

//   factory Data.fromJson(Map<String, dynamic> json) {
//     // If keys are missing, use fallbacks
//     final id = json['id'] as int? ?? -1;
//     final roleStr = json['role'] as String?;
//     final userRole = UserRole.fromString(roleStr);

//     return Data(id: id, userRole: userRole);
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'role': userRole.name, // Dart 3+ `.name` gives string value
//     };
//   }

//   @override
//   String toString() => 'Data(id: $id, userRole: $userRole)';
// }

// lib/src/core/models/user_role.dart
enum UserRole {
  customer,
  technician,
  admin,
  unknown;

  static UserRole fromString(String? role) {
    if (role == null) return unknown;
    return switch (role.toLowerCase()) {
      'customer' => customer,
      'technician' => technician,
      'admin' => admin,
      _ => unknown,
    };
  }
}

// lib/src/core/models/verify_data.dart

class VerifyData {
  // For registered users (has 'role')
  final int? userId;
  final UserRole userRole;
  final String? accountStatus;

  // For unregistered customers (has 'full_name', 'street_address', etc.)
  final int? customerId;
  final int serviceFeasibility;
  final String fullName;
  final String streetAddress;
  final String mobileNumber;

  // Private constructor
  const VerifyData._({
    this.userId,
    this.userRole = UserRole.unknown,
    this.accountStatus,
    this.customerId,
    this.serviceFeasibility = 0,
    this.fullName = '',
    this.streetAddress = '',
    this.mobileNumber = '',
  });

  // Factory for registered users
  factory VerifyData.registered({
    required int userId,
    required UserRole userRole,
    String? accountStatus,
  }) = VerifyData._;

  // Factory for unregistered customers
  factory VerifyData.unregistered({
    required int customerId,
    required int serviceFeasibility,
    required String fullName,
    required String streetAddress,
    required String mobileNumber,
  }) = VerifyData._;

  // Empty constructor
  factory VerifyData.empty() = VerifyData._;

  // Parse from JSON
  factory VerifyData.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return VerifyData.empty();

    // Registered user (has 'role')
    if (json.containsKey('role')) {
      return VerifyData.registered(
        userId: json['id'] as int? ?? -1,
        userRole: UserRole.fromString(json['role'] as String?),
        accountStatus: json['Account_status'] as String?,
      );
    }

    // Unregistered customer (has 'full_name')
    if (json.containsKey('full_name')) {
      return VerifyData.unregistered(
        customerId: json['id'] as int? ?? -1,
        serviceFeasibility: json['service_feasibility'] as int? ?? 0,
        fullName: json['full_name'] as String? ?? '',
        streetAddress: json['street_address'] as String? ?? '',
        mobileNumber: json['mobile_number'] as String? ?? '',
      );
    }

    return VerifyData.empty();
  }

  // Helper getters
  bool get isRegisteredUser => userId != null && userRole != UserRole.unknown;
  bool get isUnregisteredCustomer => customerId != null && fullName.isNotEmpty;
  bool get isEmpty => !isRegisteredUser && !isUnregisteredCustomer;
}

// lib/src/core/models/verify_mobile_response.dart

class VerifyMobileResponse {
  final String status;
  final String message;
  final String token;
  final VerifyData data;
  final String? action;
  final String? serviceStatus;

  const VerifyMobileResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.data,
    this.action,
    this.serviceStatus,
  });

  factory VerifyMobileResponse.fromJson(Map<String, dynamic> json) {
    return VerifyMobileResponse(
      status: json['status'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      token: json['token'] as String? ?? '',
      data: VerifyData.fromJson(json['data'] as Map<String, dynamic>?),
      action: json['action'] as String?,
      serviceStatus: json['service_status'] as String?,
    );
  }

  // Helper getters
  bool get isSuccess => status == 'success';
  bool get isDeactivated =>
      status == 'error' && message.contains('deactivated');
  bool get isFeasible => serviceStatus == 'feasible';
  bool get isUnderReview => serviceStatus == 'under_review';
}
