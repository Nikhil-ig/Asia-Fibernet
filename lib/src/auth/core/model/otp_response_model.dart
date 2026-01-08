// models/otp_response_model.dart

/// Response model for OTP generation
class GenerateOTPResponse {
  final String status;
  final String message;
  final String gateway;

  GenerateOTPResponse({
    required this.status,
    required this.message,
    required this.gateway,
  });

  factory GenerateOTPResponse.fromJson(Map<String, dynamic> json) {
    return GenerateOTPResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      gateway: json['gateway'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'gateway': gateway,
  };
}

/// User data from OTP verification
class VerifyOTPUserData {
  final int id;
  final String role;
  final String accountStatus;

  VerifyOTPUserData({
    required this.id,
    required this.role,
    required this.accountStatus,
  });

  factory VerifyOTPUserData.fromJson(Map<String, dynamic> json) {
    return VerifyOTPUserData(
      id: json['id'] as int? ?? 0,
      role: json['role'] as String? ?? '',
      accountStatus: json['Account_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'Account_status': accountStatus,
  };
}

/// Response model for OTP verification
class VerifyOTPResponse {
  final String status;
  final String message;
  final String token;
  final VerifyOTPUserData data;
  final String action;
  final String serviceStatus;

  VerifyOTPResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.data,
    required this.action,
    required this.serviceStatus,
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      token: json['token'] as String? ?? '',
      data: VerifyOTPUserData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
      action: json['action'] as String? ?? '',
      serviceStatus: json['service_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'token': token,
    'data': data.toJson(),
    'action': action,
    'service_status': serviceStatus,
  };

  // Helper getters
  bool get isValid => status == 'success' && token.isNotEmpty;
  bool get isActiveCustomer => data.accountStatus == 'Active';
  bool get isCustomer => data.role == 'customer';
}
