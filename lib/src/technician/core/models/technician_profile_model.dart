// models/technician_profile_model.dart

import 'package:asia_fibernet/src/services/apis/base_api_service.dart';

/// Unified model for Technician Profile + KYC Details
/// All image fields (profilePhoto, aadharFront, aadharBack) are Base64 strings.
class TechnicianProfileModel {
  // From fetch_my_profile_tech.php
  final int id;
  final int accountId;
  final String accountType;
  final String contactName;
  final String companyName;

  /// Base64-encoded profile photo (e.g., "data:image/jpeg;base64,/9j/4AAQSkZ...")
  final String? profilePhoto; // ✅ Base64
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String?
  workPhoneNumber; // ⚠️ Changed to String — phone numbers should be strings
  final String? cellPhoneNumber; // ⚠️ Same
  final String? otherPhoneNumber; // ⚠️ Same
  final String? email;
  final String? websiteAddress;
  final String? notes;
  final String creationDate;

  // From kyc_doc_tech.php
  final int? technicianId;
  final String? aadharcardNo;

  /// Base64-encoded Aadhaar front image
  final String? aadharFront; // ✅ Base64
  /// Base64-encoded Aadhaar back image
  final String? aadharBack; // ✅ Base64
  final String? pancardNo;
  final String? bankName;
  final String? branchName;
  final String? ifscCode;
  final String? accountNo;
  final String? technicianName;
  final String? dateOfJoining;
  final String? dateOfBirth;

  TechnicianProfileModel({
    required this.id,
    required this.accountId,
    required this.accountType,
    required this.contactName,
    required this.companyName,
    this.profilePhoto,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.workPhoneNumber,
    this.cellPhoneNumber,
    this.otherPhoneNumber,
    this.email,
    this.websiteAddress,
    this.notes,
    required this.creationDate,
    this.technicianId,
    this.aadharcardNo,
    this.aadharFront,
    this.aadharBack,
    this.pancardNo,
    this.bankName,
    this.branchName,
    this.ifscCode,
    this.accountNo,
    this.technicianName,
    this.dateOfJoining,
    this.dateOfBirth,
  });

  // Factory to create from profile data (without KYC)
  factory TechnicianProfileModel.fromProfileData(Map<String, dynamic> json) {
    return TechnicianProfileModel(
      id: _toInt(json['ID']) ?? -1,
      accountId: _toInt(json['AccountID']) ?? 0,
      accountType: json['AccountType'] as String? ?? 'N/A',
      contactName: json['ContactName'] as String? ?? 'Unknown',
      companyName: json['CompanyName'] as String? ?? 'N/A',
      profilePhoto:
          "${BaseApiService.api}${(json['profile_photo'] as String?)}",
      address: (json['Address'] as String?)?.trim(),
      city: (json['City'] as String?)?.trim() ?? 'N/A',
      state: (json['State'] as String?)?.trim() ?? 'N/A',
      zipCode: (json['ZipCode'] as String?)?.trim(),
      workPhoneNumber: _toPhoneString(json['Workphnumber']),
      cellPhoneNumber: _toPhoneString(json['Cellphnumber']),
      otherPhoneNumber: _toPhoneString(json['Otherphnumber']),
      email: (json['Email'] as String?)?.trim(),
      websiteAddress: (json['WebsiteAddress'] as String?)?.trim(),
      notes: (json['Notes'] as String?)?.trim(),
      creationDate: json['CreationDate'] as String? ?? 'N/A',
      // Default KYC values
      technicianId: _toInt(json['ID']),
      aadharcardNo: null,
      aadharFront: null,
      aadharBack: null,
      pancardNo: null,
      bankName: null,
      branchName: null,
      ifscCode: null,
      accountNo: null,
      technicianName: null,
      dateOfJoining: null,
      dateOfBirth: null,
    );
  }

  // Method to merge with KYC data
  TechnicianProfileModel mergeWithKyc(TechnicianKycModel kyc) {
    return TechnicianProfileModel(
      id: id,
      accountId: accountId,
      accountType: accountType,
      contactName: contactName,
      companyName: companyName,
      profilePhoto: profilePhoto,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      workPhoneNumber: workPhoneNumber,
      cellPhoneNumber: cellPhoneNumber,
      otherPhoneNumber: otherPhoneNumber,
      email: email,
      websiteAddress: websiteAddress,
      notes: notes,
      creationDate: creationDate,
      technicianId: kyc.technicianId,
      aadharcardNo: kyc.aadharcardNo,
      aadharFront: kyc.aadharFront,
      aadharBack: kyc.aadharBack,
      pancardNo: kyc.pancardNo,
      bankName: kyc.bankName,
      branchName: kyc.branchName,
      ifscCode: kyc.ifscCode,
      accountNo: kyc.accountNo,
      technicianName: kyc.technicianName,
      dateOfJoining: kyc.dateOfJoining,
      dateOfBirth: kyc.dateOfBirth,
    );
  }

  // Helper: Check if KYC is complete
  bool get isKycComplete {
    return (aadharcardNo?.isNotEmpty ?? false) &&
        (aadharFront?.isNotEmpty ?? false) &&
        (aadharBack?.isNotEmpty ?? false) &&
        (pancardNo?.isNotEmpty ?? false) &&
        (bankName?.isNotEmpty ?? false) &&
        (branchName?.isNotEmpty ?? false) &&
        (ifscCode?.isNotEmpty ?? false) &&
        (accountNo?.isNotEmpty ?? false);
  }

  // Helper: Get display name
  String get displayName =>
      contactName.isNotEmpty ? contactName : 'Unnamed Technician';

  // Helper: Safe phone number for UI
  String get displayPhone => cellPhoneNumber ?? workPhoneNumber ?? 'No phone';

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

/// KYC Model
/// All image fields are Base64-encoded strings.
class TechnicianKycModel {
  final int technicianId;
  final String? aadharcardNo;

  /// Base64-encoded Aadhaar front image
  final String? aadharFront;

  /// Base64-encoded Aadhaar back image
  final String? aadharBack;
  final String? pancardNo;
  final String? bankName;
  final String? branchName;
  final String? ifscCode;
  final String? accountNo;
  final String? technicianName;
  final String? dateOfJoining;
  final String? dateOfBirth;

  TechnicianKycModel({
    required this.technicianId,
    this.aadharcardNo,
    this.aadharFront,
    this.aadharBack,
    this.pancardNo,
    this.bankName,
    this.branchName,
    this.ifscCode,
    this.accountNo,
    this.technicianName,
    this.dateOfJoining,
    this.dateOfBirth,
  });

  factory TechnicianKycModel.fromJson(Map<String, dynamic> json) {
    return TechnicianKycModel(
      technicianId: _toInt(json['technician_id']) ?? -1,
      aadharcardNo: (json['aadharcard_no'] as String?)?.trim(),
      aadharFront: json['aadhar_front'] as String?,
      aadharBack: json['aadhar_back'] as String?,
      pancardNo: (json['pancard_no'] as String?)?.trim(),
      bankName: (json['bank_name'] as String?)?.trim(),
      branchName: (json['branchname'] as String?)?.trim(),
      ifscCode: (json['ifsccode'] as String?)?.trim().toUpperCase(),
      accountNo: (json['account_no'] as String?)?.trim(),
      technicianName: (json['technician_name'] as String?)?.trim(),
      dateOfJoining: json['dateof_joining'] as String?,
      dateOfBirth:
          json['dateog_birth'] as String?, // ⚠️ Typo in API? "dateog_birth"
    );
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

  // Helper: Validate IFSC (basic)
  bool get isIfscValid =>
      ifscCode?.length == 11 && ifscCode?.isNotEmpty == true;

  // Helper: Validate Account No (basic)
  bool get isAccountNoValid =>
      accountNo?.length != null && accountNo!.length >= 9;
}
