import '../../../services/apis/base_api_service.dart';

class FindCustomerDetail {
  final int? id;
  final int? accountId;
  final String? accountType;
  final String? contactName;
  final String? companyName;
  final String? companyLogo;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final int? workphnumber;
  final int? cellphnumber;
  final String? otherphnumber;
  final String? email;
  final String? websiteAddress;
  final String? notes;
  final String? creationDate;
  final String? referralCode;
  final String? referredBy;
  final String? role;
  final String? area;
  final int? plan;
  final String? ipAddress;
  final String? profilePhoto;
  final String? frServiceCode;
  final String? category;
  final String? exchangeCode;
  final String? serviceNumber;
  final String? subServiceType;
  final String? subscriptionPlan;
  final String? planPeriod;
  final String? fmc;
  final String? bbUserId;
  final String? bbActivationDate;
  final String? assignTo;
  final String? status;
  final String? accountStatus;
  final String? deletedAt;
  final String? fcmToken;

  FindCustomerDetail({
    this.id,
    this.accountId,
    this.accountType,
    this.contactName,
    this.companyName,
    this.companyLogo,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.workphnumber,
    this.cellphnumber,
    this.otherphnumber,
    this.email,
    this.websiteAddress,
    this.notes,
    this.creationDate,
    this.referralCode,
    this.referredBy,
    this.role,
    this.area,
    this.plan,
    this.ipAddress,
    this.profilePhoto,
    this.frServiceCode,
    this.category,
    this.exchangeCode,
    this.serviceNumber,
    this.subServiceType,
    this.subscriptionPlan,
    this.planPeriod,
    this.fmc,
    this.bbUserId,
    this.bbActivationDate,
    this.assignTo,
    this.status,
    this.accountStatus,
    this.deletedAt,
    this.fcmToken,
  });

  factory FindCustomerDetail.fromJson(Map<String, dynamic> json) {
    return FindCustomerDetail(
      id: _toInt(json['ID']),
      accountId: _toInt(json['AccountID']),
      accountType: _toString(json['AccountType']),
      contactName: _toString(json['ContactName']),
      companyName: _toString(json['CompanyName']),
      companyLogo: _toString(json['company_logo']),
      address: _toString(json['Address']),
      city: _toString(json['City']),
      state: _toString(json['State']),
      zipCode: _toString(json['ZipCode']),
      workphnumber: _toInt(json['Workphnumber']),
      cellphnumber: _toInt(json['Cellphnumber']),
      otherphnumber: _toString(json['Otherphnumber']),
      email: _toString(json['Email']),
      websiteAddress: _toString(json['WebsiteAddress']),
      notes: _toString(json['Notes']),
      creationDate: _toString(json['CreationDate']),
      referralCode: _toString(json['referral_code']),
      referredBy: _toString(json['referred_by']),
      role: _toString(json['role']),
      area: _toString(json['area']),
      plan: _toInt(json['plan']),
      ipAddress: _toString(json['IpAddress']),
      profilePhoto: _toString(
        "${BaseApiService.api}${(json['profile_photo'] as String?)}",
      ),
      frServiceCode: _toString(json['FR_Service_Code']),
      category: _toString(json['Category']),
      exchangeCode: _toString(json['Exchange_Code']),
      serviceNumber: _toString(json['Service_Number']),
      subServiceType: _toString(json['Sub_Service_Type']),
      subscriptionPlan: _toString(json['Subscription_Plan']),
      planPeriod: _toString(json['Plan_Period']),
      fmc: _toString(json['FMC']),
      bbUserId: _toString(json['BB_USER_ID']),
      bbActivationDate: _toString(json['BB_Activation_Date']),
      assignTo: _toString(json['Assign_To']),
      status: _toString(json['Status']),
      accountStatus: _toString(json['Account_status']),
      deletedAt: _toString(json['deleted_at']),
      fcmToken: _toString(json['fcm_token']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'AccountID': accountId,
      'AccountType': accountType,
      'ContactName': contactName,
      'CompanyName': companyName,
      'company_logo': companyLogo,
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
      'referral_code': referralCode,
      'referred_by': referredBy,
      'role': role,
      'area': area,
      'plan': plan,
      'IpAddress': ipAddress,
      'profile_photo': profilePhoto,
      'FR_Service_Code': frServiceCode,
      'Category': category,
      'Exchange_Code': exchangeCode,
      'Service_Number': serviceNumber,
      'Sub_Service_Type': subServiceType,
      'Subscription_Plan': subscriptionPlan,
      'Plan_Period': planPeriod,
      'FMC': fmc,
      'BB_USER_ID': bbUserId,
      'BB_Activation_Date': bbActivationDate,
      'Assign_To': assignTo,
      'Status': status,
      'Account_status': accountStatus,
      'deleted_at': deletedAt,
      'fcm_token': fcmToken,
    }..removeWhere((key, value) => value == null);
  }

  // --- Helper safe converters ---
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString();
  }
}
