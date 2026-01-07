// models/technician_model.dart (or consider renaming to customer_model.dart if it represents customer data)
import '../../../services/apis/base_api_service.dart';

class TechnicianModel {
  // Consider renaming if this represents customer data fetched by technician
  final int id;
  final int accountId;
  final String accountType;
  final String name; // Maps to ContactName
  final String companyName;
  final String? companyLogo; // Added: from 'company_logo'
  final String? address;
  final String city;
  final String state;
  final String? zipCode;
  final int? workPhone; // Changed type: from 'Workphnumber'
  final int?
  cellPhone; // Changed type: from 'Cellphnumber' - Consider renaming to mobile
  final int?
  otherPhone; // Changed type: from 'Otherphnumber' - Consider renaming to alternatePhone
  final String? email;
  final String? website;
  final String? notes; // Added: from 'Notes'
  final String creationDate;
  final String? referralCode; // Added: from 'referral_code'
  final dynamic referredBy; // Added: from 'referred_by' (could be int or null)
  final String? role; // Added: from 'role'
  final dynamic area; // Added: from 'area' (could be string or null)
  final dynamic plan; // Added: from 'plan' (could be string or null)
  final dynamic ipAddress; // Added: from 'IpAddress' (could be string or null)
  final String? profilePhoto; // Added: from 'profile_photo'
  final dynamic
  frServiceCode; // Added: from 'FR_Service_Code' (could be string or null)
  final dynamic category; // Added: from 'Category' (could be string or null)
  final dynamic
  exchangeCode; // Added: from 'Exchange_Code' (could be string or null)
  final dynamic
  serviceNumber; // Added: from 'Service_Number' (could be string or null)
  final dynamic
  subServiceType; // Added: from 'Sub_Service_Type' (could be string or null)
  final dynamic
  subscriptionPlan; // Added: from 'Subscription_Plan' (could be string or null)
  final dynamic
  planPeriod; // Added: from 'Plan_Period' (could be string or null)
  final dynamic fmc; // Added: from 'FMC' (could be string or null)
  final dynamic bbUserId; // Added: from 'BB_USER_ID' (could be string or null)
  final dynamic
  bbActivationDate; // Added: from 'BB_Activation_Date' (could be string or null)
  final dynamic assignTo; // Added: from 'Assign_To' (could be string or null)
  final dynamic status; // Added: from 'Status' (could be string or null)

  TechnicianModel({
    required this.id,
    required this.accountId,
    required this.accountType,
    required this.name,
    required this.companyName,
    this.companyLogo,
    this.address,
    required this.city,
    required this.state,
    this.zipCode,
    this.workPhone,
    this.cellPhone, // Consider renaming parameter
    this.otherPhone, // Consider renaming parameter
    this.email,
    this.website,
    required this.creationDate,
    this.notes,
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
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['ID'] as int? ?? 0,
      accountId: json['AccountID'] as int? ?? 0,
      accountType: json['AccountType'] as String? ?? '',
      name: json['ContactName'] as String? ?? '', // Maps from ContactName
      companyName: json['CompanyName'] as String? ?? '',
      companyLogo: json['company_logo'] as String?, // Added
      address: json['Address'] as String?,
      city: json['City'] as String? ?? '',
      state: json['State'] as String? ?? '',
      zipCode: json['ZipCode'] as String?,
      workPhone: (json['Workphnumber'] as num?)?.toInt(), // Changed parsing
      cellPhone:
          (json['Cellphnumber'] as num?)
              ?.toInt(), // Changed parsing - Consider renaming
      otherPhone:
          (json['Otherphnumber'] as num?)
              ?.toInt(), // Changed parsing - Consider renaming
      email: json['Email'] as String?,
      website: json['WebsiteAddress'] as String?,
      creationDate: json['CreationDate'] as String? ?? '',
      notes: json['Notes'] as String?, // Added
      referralCode: json['referral_code'] as String?, // Added
      referredBy: json['referred_by'], // Added
      role: json['role'] as String?, // Added
      area: json['area'], // Added
      plan: json['plan'], // Added
      ipAddress: json['IpAddress'], // Added
      profilePhoto: json['profile_photo'] as String?, // Added
      frServiceCode: json['FR_Service_Code'], // Added
      category: json['Category'], // Added
      exchangeCode: json['Exchange_Code'], // Added
      serviceNumber: json['Service_Number'], // Added
      subServiceType: json['Sub_Service_Type'], // Added
      subscriptionPlan: json['Subscription_Plan'], // Added
      planPeriod: json['Plan_Period'], // Added
      fmc: json['FMC'], // Added
      bbUserId: json['BB_USER_ID'], // Added
      bbActivationDate: json['BB_Activation_Date'], // Added
      assignTo: json['Assign_To'], // Added
      status: json['Status'], // Added
    );
  }

  String get profileImageUrl {
    // Use the fetched profile photo if available, otherwise use a default
    if (profilePhoto != null && profilePhoto!.isNotEmpty) {
      // Prepend base URL if it's just a path
      if (!profilePhoto!.startsWith('http://') &&
          !profilePhoto!.startsWith('https://')) {
        return '${BaseApiService.api}$profilePhoto'; // Use correct base URL
      }
      return profilePhoto!; // Return the full URL if it already is one
    }
    return 'https://asiafibernet.com/assets/images/technician.png'; // Default fallback
  }
}
