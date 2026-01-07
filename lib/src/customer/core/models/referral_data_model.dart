// lib/models/referral_data_model.dart

class ReferralDataModel {
  final String? fullName;
  final String? mobileNumber;
  final String? alternateNumber;
  final String? email;
  final String? idProofType;
  final String? idProofNumber;
  final String? houseNo;
  final String? streetAddress;
  final String? area;
  final String? city;
  final String? state;
  final String? pincode;
  final String? landmark;
  final String? connectionType;
  final String? desiredPlan;
  final String? preferredInstallationDate;
  final String? referralCode;
  final String? additionalNotes;
  final String? deviceBrand;
  final String? deviceModel;
  final String? ipAddress;
  final String? wifiName;
  final String? wifiGateway;
  final String? wifiBssid;
  final String? gpsLatitude;
  final String? gpsLongitude;
  final String? createdAt;
  final String? updatedAt;
  final int? referralBy; // The ID of the person who referred this user

  ReferralDataModel({
    this.fullName,
    this.mobileNumber,
    this.alternateNumber,
    this.email,
    this.idProofType,
    this.idProofNumber,
    this.houseNo,
    this.streetAddress,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.landmark,
    this.connectionType,
    this.desiredPlan,
    this.preferredInstallationDate,
    this.referralCode,
    this.additionalNotes,
    this.deviceBrand,
    this.deviceModel,
    this.ipAddress,
    this.wifiName,
    this.wifiGateway,
    this.wifiBssid,
    this.gpsLatitude,
    this.gpsLongitude,
    this.createdAt,
    this.updatedAt,
    this.referralBy,
  });

  factory ReferralDataModel.fromJson(Map<String, dynamic> json) {
    return ReferralDataModel(
      fullName: json['full_name'] as String?,
      mobileNumber: json['mobile_number'] as String?,
      alternateNumber: json['alternate_number'] as String?,
      email: json['email'] as String?,
      idProofType: json['id_proof_type'] as String?,
      idProofNumber: json['id_proof_number'] as String?,
      houseNo: json['house_no'] as String?,
      streetAddress: json['street_address'] as String?,
      area: json['area'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      landmark: json['landmark'] as String?,
      connectionType: json['connection_type'] as String?,
      desiredPlan: json['desired_plan'] as String?,
      preferredInstallationDate: json['preferred_installation_date'] as String?,
      referralCode: json['referral_code'] as String?,
      additionalNotes: json['additional_notes'] as String?,
      deviceBrand: json['device_brand'] as String?,
      deviceModel: json['device_model'] as String?,
      ipAddress: json['ip_address'] as String?,
      wifiName: json['wifi_name'] as String?,
      wifiGateway: json['wifi_gateway'] as String?,
      wifiBssid: json['wifi_bssid'] as String?,
      gpsLatitude: json['gps_latitude'] as String?,
      gpsLongitude: json['gps_longitude'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      referralBy: json['referral_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'alternate_number': alternateNumber,
      'email': email,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'house_no': houseNo,
      'street_address': streetAddress,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'connection_type': connectionType,
      'desired_plan': desiredPlan,
      'preferred_installation_date': preferredInstallationDate,
      'referral_code': referralCode,
      'additional_notes': additionalNotes,
      'device_brand': deviceBrand,
      'device_model': deviceModel,
      'ip_address': ipAddress,
      'wifi_name': wifiName,
      'wifi_gateway': wifiGateway,
      'wifi_bssid': wifiBssid,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'referral_by': referralBy,
    };
  }
}

// We can also create a model for the generateReferralCode response if needed,
// but for simplicity, we'll use Map<String, dynamic> for now.

// models/referral_step_model.dart
class ReferralStep {
  final String stepTitle;
  final String stepDescription;
  final int stepOrder;

  ReferralStep({
    required this.stepTitle,
    required this.stepDescription,
    required this.stepOrder,
  });

  factory ReferralStep.fromJson(Map<String, dynamic> json) {
    return ReferralStep(
      stepTitle: json['step_title'] ?? '',
      stepDescription: json['step_description'] ?? '',
      stepOrder: json['step_order'] ?? 0,
    );
  }
}

class ReferralMessageResponse {
  final String status;
  final String message;
  final List<ReferralStep> steps;

  ReferralMessageResponse({
    required this.status,
    required this.message,
    required this.steps,
  });

  factory ReferralMessageResponse.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List;
    final steps = stepsJson.map((e) => ReferralStep.fromJson(e)).toList();

    return ReferralMessageResponse(
      status: json['status'] ?? 'error',
      message: json['message'] ?? '',
      steps: steps,
    );
  }
}
