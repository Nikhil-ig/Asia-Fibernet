import '../../../services/apis/base_api_service.dart';

class AccountInfo {
  final int? id;
  final String? ladlineno;

  AccountInfo({this.id, this.ladlineno});

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      id: json['ID'] as int?,
      ladlineno: json['ladlineno'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountInfo && other.id == id && other.ladlineno == ladlineno;

  @override
  int get hashCode => Object.hash(id, ladlineno);

  @override
  String toString() => 'AccountInfo(id: $id, ladlineno: $ladlineno)';
}

class CustomerDetails {
  final int? id;
  final int? accountId;
  final String? accountType;
  final String? contactName;
  final String? companyName;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? workPhone;
  final String? cellPhone;
  final String? otherPhone;
  final String? email;
  final String? websiteAddress;
  final String? notes;
  final String? creationDate;
  final String? referralCode;
  final String? referredBy;
  final String? role;
  final String? area;
  final String? plan;
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
  final String? companyLogo;
  final List<AccountInfo>? moreAccount;

  String? get ftthNo => serviceNumber;

  CustomerDetails({
    this.id,
    this.accountId,
    this.accountType,
    this.contactName,
    this.companyName,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.workPhone,
    this.cellPhone,
    this.otherPhone,
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
    this.companyLogo,
    this.moreAccount,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    bool isNested = json.containsKey('customer_details');
    Map<String, dynamic>? customerJson;
    List<dynamic>? moreAccountJson;

    if (isNested) {
      customerJson = json['customer_details'] as Map<String, dynamic>?;
      moreAccountJson = json['more_account'] as List<dynamic>?;
    } else {
      if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
        customerJson = json['data'] as Map<String, dynamic>;
      } else {
        customerJson = json;
      }
    }

    List<AccountInfo>? parsedMoreAccount;
    if (moreAccountJson != null) {
      parsedMoreAccount =
          moreAccountJson
              .where((item) => item != null)
              .map((item) => AccountInfo.fromJson(item as Map<String, dynamic>))
              .toList();
    }

    return CustomerDetails(
      id: _parseToInt(customerJson?['ID']),
      accountId: _parseToInt(customerJson?['AccountID']),
      accountType: customerJson?['AccountType'] as String?,
      contactName: customerJson?['ContactName'] as String?,
      companyName: customerJson?['CompanyName'] as String?,
      address: customerJson?['Address'] as String?,
      city: customerJson?['City'] as String?,
      state: customerJson?['State'] as String?,
      zipCode: customerJson?['ZipCode'] as String?,
      workPhone: _parseToString(customerJson?['Workphnumber']),
      cellPhone: _parseToString(customerJson?['Cellphnumber']),
      otherPhone: _parseToString(customerJson?['Otherphnumber']),
      email: customerJson?['Email'] as String?,
      websiteAddress: customerJson?['WebsiteAddress'] as String?,
      notes: customerJson?['Notes'] as String?,
      creationDate: customerJson?['CreationDate'] as String?,
      referralCode: customerJson?['referral_code'] as String?,
      referredBy: customerJson?['referred_by'] as String?,
      role: customerJson?['role'] as String?,
      area: customerJson?['area'] as String?,
      plan: _parseToString(customerJson?['plan']),
      ipAddress: customerJson?['IpAddress'] as String?,
      profilePhoto: _parseToString(customerJson?['profile_photo']),
      frServiceCode: customerJson?['FR_Service_Code'] as String?,
      category: customerJson?['Category'] as String?,
      exchangeCode: customerJson?['Exchange_Code'] as String?,
      serviceNumber:
          (customerJson?['Service_Number'] ?? customerJson?['ftth_no'])
              as String?,
      subServiceType: customerJson?['Sub_Service_Type'] as String?,
      subscriptionPlan: customerJson?['Subscription_Plan'] as String?,
      planPeriod: customerJson?['Plan_Period'] as String?,
      fmc: customerJson?['FMC'] as String?,
      bbUserId: customerJson?['BB_USER_ID'] as String?,
      bbActivationDate: customerJson?['BB_Activation_Date'] as String?,
      assignTo: customerJson?['Assign_To'] as String?,
      status: customerJson?['Status'] as String?,
      accountStatus: customerJson?['Account_status'] as String?,
      deletedAt: customerJson?['deleted_at'] as String?,
      fcmToken: customerJson?['fcm_token'] as String?,
      companyLogo: customerJson?['company_logo'] as String?,
      moreAccount: parsedMoreAccount,
    );
  }

  static String? _parseToString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  String? get fullProfileImageUrl {
    if (profilePhoto == null || profilePhoto!.isEmpty) return null;
    if (profilePhoto!.startsWith('http')) return profilePhoto;
    return '${BaseApiService.api}$profilePhoto';
  }

  @override
  bool operator ==(covariant CustomerDetails other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.accountId == accountId &&
        other.accountType == accountType &&
        other.contactName == contactName &&
        other.companyName == companyName &&
        other.address == address &&
        other.city == city &&
        other.state == state &&
        other.zipCode == zipCode &&
        other.workPhone == workPhone &&
        other.cellPhone == cellPhone &&
        other.otherPhone == otherPhone &&
        other.email == email &&
        other.websiteAddress == websiteAddress &&
        other.notes == notes &&
        other.creationDate == creationDate &&
        other.referralCode == referralCode &&
        other.referredBy == referredBy &&
        other.role == role &&
        other.area == area &&
        other.plan == plan &&
        other.ipAddress == ipAddress &&
        other.profilePhoto == profilePhoto &&
        other.frServiceCode == frServiceCode &&
        other.category == category &&
        other.exchangeCode == exchangeCode &&
        other.serviceNumber == serviceNumber &&
        other.subServiceType == subServiceType &&
        other.subscriptionPlan == subscriptionPlan &&
        other.planPeriod == planPeriod &&
        other.fmc == fmc &&
        other.bbUserId == bbUserId &&
        other.bbActivationDate == bbActivationDate &&
        other.assignTo == assignTo &&
        other.status == status &&
        other.accountStatus == accountStatus &&
        other.deletedAt == deletedAt &&
        other.fcmToken == fcmToken &&
        other.companyLogo == companyLogo &&
        listEquals(other.moreAccount, moreAccount);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      accountId,
      accountType,
      contactName,
      companyName,
      address,
      city,
      state,
      zipCode,
      workPhone,
      cellPhone,
      otherPhone,
      email,
      websiteAddress,
      notes,
      creationDate,
      referralCode,
      referredBy,
      role,
      area,
    );
  }

  @override
  String toString() {
    return 'CustomerDetails(contactName: $contactName, email: $email, serviceNumber: $serviceNumber, moreAccount: $moreAccount)';
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
