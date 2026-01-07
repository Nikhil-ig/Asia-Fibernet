// models/kyc_status_response.dart
import 'dart:convert';

import 'package:asia_fibernet/src/services/routes.dart';

import '/src/services/apis/base_api_service.dart';
import 'package:get/get.dart';

class KycStatusResponse {
  final String status;
  final String message;
  final String token;
  final KycData data;
  final String action;
  final String serviceStatus;

  KycStatusResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.data,
    required this.action,
    required this.serviceStatus,
  });

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      token: json['token'] as String? ?? '',
      data: KycData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
      action: json['action'] as String? ?? '',
      serviceStatus: json['service_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'token': token,
      'data': data.toJson(),
      'action': action,
      'service_status': serviceStatus,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class KycData {
  final Registration registration;
  final List<KycDocument> documents;
  final String connectionStatus;

  KycData({
    required this.registration,
    required this.documents,
    required this.connectionStatus,
  });

  factory KycData.fromJson(Map<String, dynamic> json) {
    List<KycDocument> documentList = [];
    if (json['documents'] is List) {
      documentList =
          (json['documents'] as List)
              .map((d) => KycDocument.fromJson(d as Map<String, dynamic>))
              .toList();
    }

    return KycData(
      registration: Registration.fromJson(
        json['registration'] as Map<String, dynamic>? ?? {},
      ),
      documents: documentList,
      connectionStatus: json['connection_status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registration': registration.toJson(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'connection_status': connectionStatus,
    };
  }
}

class Registration {
  final int id;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String streetAddress;
  final dynamic pincode; // Can be int or null based on the example
  final String city;
  final String state;
  final String connectionType;
  final String desiredPlan;
  final dynamic referralCode; // Can be String or null
  final int aadharVerified;
  final int pancardVerified;
  final int addressVerified;
  final String createdAt;
  final String updatedAt;
  final dynamic referralBy; // Can be int or null
  final dynamic status; // Can be int or null
  final int serviceFeasibility;
  final int steps; // <--- Added: Present in the JSON

  Registration({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.streetAddress,
    required this.pincode,
    required this.city,
    required this.state,
    required this.connectionType,
    required this.desiredPlan,
    required this.referralCode,
    required this.aadharVerified,
    required this.pancardVerified,
    required this.addressVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.referralBy,
    required this.status,
    required this.serviceFeasibility,
    required this.steps, // <--- Added
  });

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      streetAddress: json['street_address'] as String? ?? '',
      pincode: json['pincode'],
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      connectionType: json['connection_type'] as String? ?? '',
      desiredPlan: json['desired_plan'] as String? ?? '',
      referralCode: json['referral_code'],
      aadharVerified: json['aadhar_verified'] as int? ?? 0,
      pancardVerified: json['pancard_verified'] as int? ?? 0,
      addressVerified: json['address_verified'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      referralBy: json['referral_by'],
      status: json['status'],
      serviceFeasibility: json['service_feasibility'] as int? ?? 0,
      steps: json['steps'] as int? ?? 0, // <--- Added: Parse 'steps'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'email': email,
      'street_address': streetAddress,
      'pincode': pincode,
      'city': city,
      'state': state,
      'connection_type': connectionType,
      'desired_plan': desiredPlan,
      'referral_code': referralCode,
      'aadhar_verified': aadharVerified,
      'pancard_verified': pancardVerified,
      'address_verified': addressVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'referral_by': referralBy,
      'status': status,
      'service_feasibility': serviceFeasibility,
      'steps': steps, // <--- Added: Include 'steps'
    };
  }
}

class KycDocument {
  final int id;
  final String type;
  final String verificationStatus;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String? profileImageUrl;
  final int registrationTableId;
  final String? issue; // <--- Added: Present in the JSON

  KycDocument({
    required this.id,
    required this.type,
    required this.verificationStatus,
    required this.documentFrontUrl,
    required this.documentBackUrl,
    required this.profileImageUrl,
    required this.registrationTableId,
    required this.issue, // <--- Added
  });
  factory KycDocument.fromJson(Map<String, dynamic> json) {
    BaseApiService baseApiService = Get.find();
    return KycDocument(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      verificationStatus: json['verification_status'] as String? ?? '',
      // Prepend base URL if the path is not null and not already a full URL
      documentFrontUrl: baseApiService.prependBaseUrl(
        json['document_front_url'] as String?,
      ),
      documentBackUrl: baseApiService.prependBaseUrl(
        json['document_back_url'] as String?,
      ),
      profileImageUrl: baseApiService.prependBaseUrl(
        json['profile_image_url'] as String?,
      ),
      registrationTableId: json['registration_table_id'] as int? ?? 0,
      issue: json['issue'] as String?, // <--- Added: Parse 'issue'
    );
  }

  // Helper function to prepend the base URL

  Map<String, dynamic> toJson() {
    AppRoutes.signup;
    return {
      'id': id,
      'type': type,
      'verification_status': verificationStatus,
      'document_front_url': documentFrontUrl,
      'document_back_url': documentBackUrl,
      'profile_image_url': profileImageUrl,
      'registration_table_id': registrationTableId,
      'issue': issue, // <--- Added: Include 'issue'
    };
  }

  // Helper getters
  bool get hasFrontImage =>
      documentFrontUrl != null && documentFrontUrl!.isNotEmpty;
  bool get hasBackImage =>
      documentBackUrl != null && documentBackUrl!.isNotEmpty;
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;
}
