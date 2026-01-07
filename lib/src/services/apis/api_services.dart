// services/api_services.dart
import 'dart:convert';
import 'dart:io';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
// Models
import '../../auth/core/model/customer_details_model.dart';
import '../../auth/core/model/verify_mobile_model.dart';
import '../../auth/ui/scaffold_screen.dart';
import '../../customer/ui/screen/pages/home_page.dart';
import '../../customer/core/models/bsnl_plan_model.dart';
import '../../customer/core/models/customer_view_complaint_model.dart';
import '../../customer/core/models/login_history_model.dart';
import '../../customer/core/models/plan_request_status_model.dart';
import '../../customer/core/models/referral_data_model.dart';
import '../../customer/core/models/technician_model.dart';
import '../../customer/core/models/ticket_category_model.dart';
import '../../customer/core/models/unregistered_kyc_status_model.dart';
import '../../theme/colors.dart';
import '../routes.dart';
import '../sharedpref.dart';
import 'base_api_service.dart';

class ApiServices {
  late final BaseApiService _apiClient;
  late final AppSharedPref _sharedPref;

  ApiServices({BaseApiService? apiClient, AppSharedPref? sharedPref}) {
    _apiClient = apiClient ?? BaseApiService(BaseApiService.api);
    _sharedPref = sharedPref ?? AppSharedPref.instance;
  }

  // Endpoints
  static const String _verifyMobile = "verify_mobile.php";
  static const String _generateOTP = "generate_otp.php";
  static const String _registerCustomer = "register_customer.php";
  static const String _getCustomerDetails = "get_customer_details.php";
  static const String _viewComplaint = "view_complaint.php";
  static const String _raiseComplaint = "raise_complaint.php";
  static const String _closeComplaint = "close_complaint.php";
  static const String _fetchBsnlPlan = "fetch_bsnl_plan.php";
  static const String _generateReferralCode = "generate_referral_code.php";
  static const String _getReferralData = "get_referral_data.php";
  static const String _editCustomerDetails = "edit_customer_details.php";
  static const String _rateComplaint = "rate_complaint.php";
  static const String _updatePlanRequest = "update_plan_request.php";
  static const String _getTicketCategory = "get_ticket_categroy.php";
  static const String _uploadProfilePhoto = "upload_profile_photo.php";
  static const String _getLoginHistory = "get_login_history.php";
  static const String _fetchTechnicianDetails = "fetch_technician_details.php";
  static const String _fcmToken = "update_fcm_token.php";

  static const String _getPlanRequestStatus =
      "customer_plan_request_status.php";
  static const String _getReferralMessage = "get_referral_message.php";
  static const String _kycVerifyStatusCheck = "kyc_verify_status_check.php";
  static const String _uploadNewCustomerDoc = "upload_new_customer_doc.php";
  static const String _reUploadKyc = "reUpload_kyc.php";
  static const String _relocationRequest = "relocation_request.php";
  static const String _relocationStatusCheck = "relocation_status_check.php";
  static const String _userConfirmation = "user_confirmation.php";
  static const String _logout = "logout.php";
  static const String _switchAcc = "verify_ftthno.php";
  // Add these with other endpoint constants
  static const String _requestDisconnection = "request_disconnection.php";
  static const String _deleteCustomerAccount = "delete_customer_account.php";
  static const String _fetchCustomerTicketDashboardToday =
      "fetch_customer_ticket_dashboard_today.php";

  // ————————————————————————
  // 🔹 Customer APIs
  // ————————————————————————

  Future<VerifyMobileResponse?> mobileVerification(String phoneNumber) async {
    final body = {'mobile': phoneNumber};
    try {
      final res = await _apiClient.post(
        _verifyMobile,
        body: body,
        ignoreToken: true,
      );
      return _apiClient.handleResponse(
        res,
        (json) => VerifyMobileResponse.fromJson(json),
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getOTP(String phoneNumber) async {
    final body = {"mobile": phoneNumber, "action": "send", "gateway": "text"};
    try {
      final res = await _apiClient.post(
        _generateOTP,
        body: body,
        ignoreToken: true,
      );
      final r = jsonDecode(res.body);
      if (r['status'] == 'success') {
        return r['data']['otp'].toString();
      }
      // _apiClient.handleResponse(
      // res,
      // (json) => VerifyMobileResponse.fromJson(json),
      // );
    } catch (e) {
      return 'N/A';
    }
  }

  Future<bool> registerCustomer({
    required String fullName,
    required String mobileNumber,
    required String connectionType,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String referralCode,
    required String wifiName,
    required String wifiBssid,
    required String wifiGateway,
    required String gpsLatitude,
    required String gpsLongitude,
  }) async {
    final body = {
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'connection_type': connectionType,
      'email': email,
      'city': city,
      'street_address': address,
      'state': state,
      'pincode': pinCode,
      'referral_code': referralCode,
      'wifi_name': wifiName,
      'wifi_bssid': wifiBssid,
      'wifi_gateway': wifiGateway,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
    };

    try {
      final res = await _apiClient.post(
        _registerCustomer,
        body: body,
        ignoreToken: true,
      );
      return _apiClient.handleSuccessResponse(
        res,
        "Customer registered successfully!",
      );
    } catch (e) {
      return false;
    }
  }

  Future<CustomerDetails?> fetchCustomer() async {
    try {
      final res = await _apiClient.post(_getCustomerDetails);
      final result = _apiClient.handleResponse(res, (json) {
        if (json['data'] != null) {
          return CustomerDetails.fromJson(json['data']);
        } else {
          developer.log(
            'API Error: data not found in response',
            name: 'fetchCustomer',
          );
          return null;
        }
      });

      // Safely update the shared preferences only if the phone number exists
      if (result?.cellPhone != null) {
        _sharedPref.setMobileNumber(result!.cellPhone!);
      }
      return result;
    } catch (e) {
      developer.log(
        'Exception in fetchCustomer',
        error: e,
        name: 'fetchCustomer',
      );
      if (e.toString().contains('Unauthorized: No token')) {
        print('$e \nUnauthorized: No token');
      }
      return null;
    }
  }

  Future<List<ComplaintViewModel>?> viewComplaint(int customerId) async {
    final body = {'id': customerId};
    try {
      final res = await _apiClient.post(_viewComplaint, body: body);
      return _apiClient.handleListResponse(
        res,
        (item) => ComplaintViewModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<TechnicianModel?> fetchTechnicianById(int techId) async {
    final body = {'tech_id': techId};
    try {
      final res = await _apiClient.post(_fetchTechnicianDetails, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          return TechnicianModel.fromJson(json['data']);
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<bool> raiseComplaint({
    required String mobile,
    required String title,
    required String subCategory,
    String? description,
    File? image,
    int assignBy = 1,
    int? assignTo,
    String status = "Open",
  }) async {
    final customerId = _sharedPref.getUserID();
    if (customerId == null) {
      _apiClient.unauthorized();
      return false;
    }

    final imageBase64 = await _apiClient.fileToBase64(image);
    final ticketNo = _apiClient.generateTicketNo();

    final body = {
      'id': customerId,
      'registered_mobile': mobile,
      'ticket_no': ticketNo,
      'category': title,
      'sub_category': subCategory,
      'description': description ?? "N/A",
      'image_base64': imageBase64 ?? "",
      'status': status,
      'customer_id': customerId,
      'technician': 'Rahul Patil (Dummy)',
    };

    try {
      final res = await _apiClient.post(_raiseComplaint, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Complaint $ticketNo raised successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<TicketCategoryResponse?> getTicketCategory() async {
    try {
      final res = await _apiClient.get(_getTicketCategory);
      return _apiClient.handleResponse(
        res,
        (json) => TicketCategoryResponse.fromJson(json),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<bool> closeComplaint({
    required int customerId,
    required String ticketNo,
    required String closedRemark,
    required String mobile,
    required int rating,
  }) async {
    final body = {
      'customer_id': customerId,
      'ticket_no': ticketNo,
      'closed_remark': closedRemark,
      'status': 'closed',
      'registered_mobile': mobile,
      'rating': rating,
    };
    try {
      final res = await _apiClient.post(_closeComplaint, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Complaint closed successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<bool> rateComplaint({
    required String ticketNo,
    required int star,
    required String insertedOn,
    required int technicianId,
    String? rateDescription,
  }) async {
    final body = {
      'ticket_no': ticketNo,
      'star': star,
      'inserted_on': insertedOn,
      'rate_description': rateDescription,
      'technician_id': technicianId,
    };
    try {
      final res = await _apiClient.post(_rateComplaint, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Thank you for your feedback!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<List<BsnlPlan>?> fetchBsnlPlan() async {
    try {
      final url = _apiClient.buildUrl(_fetchBsnlPlan);
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      return _apiClient.handleListResponse(
        res,
        (item) => BsnlPlan.fromJson(item),
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> updatePlanRequest({
    required int id,
    required int requestPlanId,
    required int customerId,
    required int registerMobileNo,
  }) async {
    final body = {
      'id': id,
      'request_plan_id': requestPlanId,
      'customer_id': customerId,
      'register_mobile_no': registerMobileNo,
    };
    try {
      final res = await _apiClient.post(_updatePlanRequest, body: body);
      return _apiClient.handleSuccessResponse(res, "Plan update requested!");
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateReferralCode() async {
    try {
      final res = await _apiClient.post(_generateReferralCode);
      return _apiClient.handleResponse(res, (json) => json);
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<List<ReferralDataModel>?> getReferralData(int customerId) async {
    final body = {'id': customerId};
    try {
      final res = await _apiClient.post(_getReferralData, body: body);
      final json = jsonDecode(res.body);
      if (res.statusCode == 200 &&
          json['status'] == 'success' &&
          json.containsKey('referrals')) {
        final data = json['referrals'] as List;
        return data.map((e) => ReferralDataModel.fromJson(e)).toList();
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<List?> fetchCustomerTicketDashboardToday() async {
    try {
      final res = await _apiClient.get(_fetchCustomerTicketDashboardToday);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          print('>>>>>>>>>>>>>>>>>>>>>>>>>>>${json['status']}');
          print('>>>>>>>>>>>>>>>>>>>>>>>>>>>${json['data']}');
          print('>>>>>>>>>>>>>>>>>>>>>>>>>>>${json['status']}');
          // _apiClient.showSnackbar(
          //   "Success",
          //   json['message'] ?? "Request submitted!",
          //   isError: false,
          // );
          return json['data'];
        }
      }
    } catch (e) {
      // _apiClient.showSnackbar("Error", "Network error. Please try again.");
      developer.log("Catch: $e");
    }
    return null;
  }

  Future<bool> editCustomerDetails({
    required int id,
    required int customerId,
    required String accountID,
    required String accountType,
    required String contactName,
    required String address,
    required String cellphnumber,
    required String email,
  }) async {
    final body = {
      'id': id,
      'customer_id': customerId,
      'AccountID': accountID,
      'AccountType': accountType,
      'ContactName': contactName,
      'Address': address,
      'Cellphnumber': cellphnumber,
      'Email': email,
    };
    try {
      final res = await _apiClient.post(_editCustomerDetails, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Profile updated successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<bool> uploadProfilePhoto(File imageFile) async {
    // final base64Image = await _apiClient.fileToBase64(imageFile);
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    // if (base64Image == null) return false;

    final body = {'profile_photo': base64Image};
    try {
      final res = await _apiClient.post(_uploadProfilePhoto, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Photo uploaded successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<List<LoginHistoryModel>?> getLoginHistory(int customerId) async {
    final body = {'customer_id': customerId};
    try {
      final res = await _apiClient.post(_getLoginHistory, body: body);
      return _apiClient.handleListResponse(
        res,
        (item) => LoginHistoryModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<PlanRequestStatusModel?> getPlanRequestStatus(int customerId) async {
    final body = {'customer_id': customerId};
    try {
      final res = await _apiClient.post(_getPlanRequestStatus, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return PlanRequestStatusModel.fromJson(json['data']);
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<ReferralMessageResponse?> getReferralMessage() async {
    try {
      final res = await _apiClient.get(_getReferralMessage);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return ReferralMessageResponse.fromJson(json);
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  // ————————————————————————
  // 🔹 NEW Methods
  // ————————————————————————

  Future<int?> uploadNewCustomerDocuments({
    required String mobileNo,
    required String fullName,
    required String idNo,
    required String address,
    required File profileImage,
    required File idFrontImage,
    File? idBackImage,
    required File addressProofImage,
    required String desiredPlan,
    required String idType,
    File? addressRentProofImage,
  }) async {
    // final profileBase64 = await _apiClient.fileToBase64(profileImage);
    final profilebytes = await profileImage.readAsBytes();
    final profileBase64Image = base64Encode(profilebytes);
    final idFrontBase64 = await _apiClient.fileToBase64(idFrontImage);
    final idBackBase64 = await _apiClient.fileToBase64(idBackImage);
    final idAddressProofBase64 = await _apiClient.fileToBase64(
      addressProofImage,
    );
    final idAddressRentProofBase64 = await _apiClient.fileToBase64(
      addressRentProofImage,
    );

    // if (profileBase64 == null || idFrontBase64 == null) return null;
    if (idFrontBase64 == null) return null;

    final body = {
      'customer': {
        'mobile_no': mobileNo,
        'full_name': fullName,
        'id_no': idNo,
        'address': address,
        'profile_image': profileBase64Image,
      },
      'documents': [
        {
          'document_type': idType,
          'proof_front': idFrontBase64,
          'proof_back': idBackBase64 ?? "",
          'address_proof_img': idAddressProofBase64,
          'address_proof_img_back': idAddressRentProofBase64 ?? "",
        },
      ],
      'plan': {'desired_plan': desiredPlan},
    };

    // {
    //   'document_type': idType,
    //   'document_front': idFrontBase64,
    //   if (idBackImage != null) 'document_back': idBackBase64,
    //   'address_proof_img': idAddressProofBase64,
    //   if (addressRentProofImage != null)
    //     'address_proof_img_back': idAddressRentProofBase64,
    // },

    // if (idAddressProofBackBase64 != null)
    //   {
    //     // 'document_type': 'Address Proof',
    //     // 'proof_front': idFrontBase64,
    //     // 'proof_back': '',
    //     // 'address_proof_img': idAddressProofBase64,
    //     'document_type': idType,
    //     'document_front': idFrontBase64,
    //     'document_back': idBackBase64 ?? '',
    //     'address_proof_img': idAddressProofBase64,
    //     'address_proof_img_back': idAddressProofBackBase64,
    //   },

    try {
      // print(profileBase64Image);
      final res = await _apiClient.post(_uploadNewCustomerDoc, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          _apiClient.showSnackbar(
            "Success",
            json['message'] ?? "Customer and documents saved successfully!",
            isError: false,
          );
          return json['registration_id'] is int
              ? json['registration_id']
              : int.tryParse(json['registration_id'].toString());
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<KycStatusResponse?> checkKycStatus(String mobile) async {
    final body = {'mobile': mobile};
    try {
      final res = await _apiClient.post(_kycVerifyStatusCheck, body: body);
      return _apiClient.handleResponse(
        res,
        (json) => KycStatusResponse.fromJson(json),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<Map<String, dynamic>?> fcmToken() async {
    final body = {'fcm_token': AppSharedPref.instance.getFCMToken()};
    try {
      final res = await _apiClient.post(_fcmToken, body: body);
      return _apiClient.handleResponse(res, (json) => json);
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<bool> reUploadKyc(Map<String, dynamic> body) async {
    try {
      final res = await _apiClient.post(_reUploadKyc, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Document re-uploaded successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitRelocationRequest(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _apiClient.post(_relocationRequest, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          _apiClient.showSnackbar(
            "Success",
            json['message'] ?? "Request submitted!",
            isError: false,
          );
          return json;
        }
      }
    } catch (e) {
      _apiClient.showSnackbar("Error", "Network error. Please try again.");
    }
    return null;
  }

  Future<Map<String, dynamic>?> checkRelocationStatus(String mobile) async {
    final body = {'mobile': mobile};
    try {
      final res = await _apiClient.post(_relocationStatusCheck, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return json;
        }
      }
    } catch (e) {
      _apiClient.showSnackbar("Error", "Failed to fetch relocation status.");
    }
    return null;
  }

  Future<bool> userConfirmation() async {
    try {
      final res = await _apiClient.post(
        _userConfirmation,
        ignoreToken: true,
        body: {
          "mobile_no": _sharedPref.getMobileNumber(),
          "user_remark": "I agree to the Terms and Conditions.",
        },
      );

      if (res.statusCode == 200) {
        final jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;
        if (jsonResponse['status'] == 'success') {
          return true;
        } else {
          _apiClient.showSnackbar(
            "Error",
            jsonResponse['message'] ?? "Something Wrong.",
            isError: true,
          );
        }
      } else {
        // _apiClient.showSnackbar("Error", "Server error: ${res.statusCode}");
      }
    } catch (e, stackTrace) {
      print("Error: $e\n$stackTrace");
      // _apiClient.showSnackbar("Error", "Failed to LogOut. Please try again.");
    }
    return false;
  }

  Future<bool> logOut(String token) async {
    try {
      final res = await _apiClient.get(
        _logout,
        headers: {
          'Authorization': 'Bearer $token', // include token if needed
        },
      );

      if (res.statusCode == 200) {
        final jsonResponse = jsonDecode(res.body) as Map<String, dynamic>;
        if (jsonResponse['status'] == 'success') {
          return true;
        } else {
          // _apiClient.showSnackbar(
          //   "Error",
          //   jsonResponse['message'] ?? "Failed to LogOut.",
          // );
        }
      } else {
        // _apiClient.showSnackbar("Error", "Server error: ${res.statusCode}");
      }
    } catch (e, stackTrace) {
      print("Logout Error: $e\n$stackTrace");
      // _apiClient.showSnackbar("Error", "Failed to LogOut. Please try again.");
    }
    return false;
  }

  /// Submits a disconnection request for the customer.
  ///
  /// [reason] Reason for disconnection (e.g., "Moving to another city").
  /// [disconnectionDate] Date when service should be disconnected (format: "YYYY-MM-DD").
  /// [bankAccountNo] Customer's bank account number.
  /// [ifscCode] IFSC code of the bank branch.
  /// [bankRegisteredName] Name as registered in the bank.
  /// [ftthNo] FTTH number associated with the account.
  ///
  /// Returns `true` on success, `false` otherwise.
  Future<bool> requestDisconnection({
    required String reason,
    required String disconnectionDate,
    required String bankAccountNo,
    required String ifscCode,
    required String bankRegisteredName,
    required String ftthNo,
  }) async {
    final body = {
      'reason': reason,
      'disconnection_date': disconnectionDate,
      'bank_account_no': bankAccountNo,
      'ifsc_code': ifscCode,
      'bank_registered_name': bankRegisteredName,
      'ftth_no': ftthNo,
    };

    try {
      final res = await _apiClient.post(_requestDisconnection, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Disconnection request submitted successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  /// Deletes the customer's account permanently.
  ///
  /// Returns `true` on success, `false` otherwise.
  Future<bool> deleteCustomerAccount() async {
    final body = {'Account_status': 'DeActive'};

    try {
      final res = await _apiClient.post(_deleteCustomerAccount, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          _apiClient.showSnackbar(
            "Success",
            json['message'] ?? "Account deleted successfully.",
            isError: false,
          );
          return true;
        } else {
          _apiClient.showSnackbar(
            "Error",
            json['message'] ?? "Failed to delete account.",
            isError: true,
          );
        }
      } else {
        _apiClient.handleHttpError(res.statusCode);
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      _apiClient.showSnackbar(
        "Error",
        "Failed to delete account. Please try again.",
        isError: true,
      );
    }
    return false;
  }

  Future<void> switchAccount({required int id}) async {
    final body = {'mobile': _sharedPref.getMobileNumber(), 'id': id.toString()};
    try {
      final res = await _apiClient.post(_switchAcc, body: body);
      final json = await _apiClient.handleResponse(res, (json) => json);

      if (json != null && json['status'] == 'success') {
        final token = json['token'] as String?;
        final data = json['data'] as Map<String, dynamic>?;

        if (token != null && data != null) {
          final newId = data['id'] as int?;

          await _sharedPref.setToken(token);
          if (newId != null) {
            await _sharedPref.setUserID(newId);
          }

          // Restart the app by navigating to the dashboard
          // Get.offAll(
          //   () => const DashboardScreen(),
          //   binding: DashboardBinding(),
          // );
          // Refresh the HomeController to update user data in the AppBar
          if (Get.isRegistered<HomeController>()) {
            await Get.find<HomeController>().refreshCustomerData();
          }

          if (!Get.isRegistered<ScaffoldController>()) {
            Get.put(ScaffoldController());
          }

          Get.offAllNamed(AppRoutes.home);
        } else {
          _apiClient.showSnackbar(
            "Error",
            "Invalid response from server.",
            isError: true,
          );
        }
      } else {
        _apiClient.showSnackbar(
          "Error",
          json?['message'] ?? "Failed to switch account.",
          isError: true,
        );
      }
    } catch (e) {
      developer.log(
        'Exception in switchAccount',
        error: e,
        name: 'switchAccount',
      );
      _apiClient.showSnackbar(
        "Error",
        "An error occurred. Please try again.",
        isError: true,
      );
    }
  }

  // ————————————————————————
  // 🔹 Private Helpers (kept for ApiServices-specific logic)
  // ————————————————————————
  logOutDialog() {
    return Get.dialog(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: handleLogout,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  // void logOut() {
  //   handleLogout();
  //   // AppSharedPref.instance.clearAllUserData();
  //   // Get.offAll(() => LoginScreen(), binding: LoginBinding());
  // }

  void handleLogout() async {
    String? token = await _sharedPref.getToken();
    try {
      if (token != null) {
        final success = await logOut(token);
        if (success) {
          final cleared = await _sharedPref.clearAllUserData();
          if (cleared) {
            developer.log("Logout successful and user data cleared.");
          } else {
            developer.log("Logout successful but failed to clear user data.");
            // BaseApiService().showSnackbar("Warning", "Could not clear local data.");
          }
        } else {
          // BaseApiService().showSnackbar("Error", "Failed to log out. Please try again.");
        }
      } else {
        await _sharedPref.clearAllUserData();
      }
    } catch (e) {
      await _sharedPref.clearAllUserData();
    } finally {
      await _sharedPref.clearAllUserData();
    }
  }

  T safeFind<T>(T Function() creator) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    } else {
      return Get.put<T>(creator());
    }
  }
}
