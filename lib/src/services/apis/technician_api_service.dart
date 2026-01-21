// services/apis/technician_api.dart
import 'dart:async';
import 'dart:convert';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/technician/core/models/find_customer_detail_model.dart';
import 'package:flutter/material.dart' show debugPrint;

import '../../technician/core/models/customer_model.dart';
// import '../../technician/core/models/relocation_ticket_model.dart';
import '../../technician/core/models/technician_profile_model.dart';
import '../../technician/core/models/tickets_model.dart';
import '../../technician/core/models/tech_dashboard_model.dart';
import '../../technician/ui/screens/notifications_screen.dart';
// import '../utils/plugin/device_info_utils.dart';
import 'base_api_service.dart';

class TechnicianAPI extends BaseApiService {
  final BaseApiService _apiClient = BaseApiService(BaseApiService.apiTech);

  // Endpoints
  static const String _dashboard = "my_dashboard_tech.php";
  static const String _fetchAllTickets = "fetch_ticket_tech.php";
  static const String _fetchRelocationTicket =
      "fetch_relocation_ticket_tech.php";
  static const String _fetchDisconnectionTicket =
      "fetch_disconnection_ticket_tech.php";

  static const String _fetchTicketByTicketNo =
      "fetch_ticket_by_ticketNo_tech.php";
  static const String _fetchAllCustomers = "fetch_all_customer_tech.php";
  static const String _fetchWireInstallationCustomers =
      "fetch_instlationCusts_tech.php";
  static const String _fetchWireInstallationCustomersDetails =
      "fetch_instlationCust_details_tech.php";

  static const String _fetchModemInstallationCustomers =
      "fetch_modem_instlationCusts_tech.php";
  static const String _fetchModemInstallationCustomersDetails =
      "fetch_instlationCust_details_tech.php";

  static const String _fetchCustomerSingle = "fetch_customer_single_tech.php";
  static const String _complaintClose = "complaint_close_by_tech.php";
  static const String _trackLocation = "track_location_tech.php";
  static const String _updateProfile = "update_my_profile_tech.php";
  static const String _getNotifications = "my_notification_tech.php";
  static const String _fetchProfile = "fetch_my_profile_tech.php";
  static const String _fetchKyc = "kyc_doc_tech.php";
  static const String _fetchCustomerByMobOrName =
      "fetch_customer_By_mobOrName_tech.php";
  static const String _createTicket = "create_tkt_for_customer.php";
  static const String _fetchOltIpList = "fetch_OLT_IP_List_tech.php";
  static const String _updateWireInstallation =
      "update_wire_installation_tech.php";
  static const String _technicianWorkLiveStatusUpdate =
      "technician_work_live_status.php";

  // Expense
  static const String _addExpense = "add_expenses_tech.php";
  static const String _fetchExpenses = "fetch_expenses_tech.php";
  static const String _fetchExpenseDetails = "fetch_expenses_details.php";

  // Attendance
  static const String _punchIn = "punch_in_tech.php";
  static const String _punchOut = "punch_out_tech.php";
  static const String _fetchAttendance = "fetch_attendance_tech.php";
  static const String _fetchTodayAttendance = "fetch_today_attendance_tech.php";
  static const String _attendanceDashboard = "attandance_dashboard.php";

  // Leave
  static const String _applyLeave = "apply_leave_tech.php";
  static const String _fetchLeaves = "fetch_leaves_tech.php";
  static const String _cancelLeave = "cancel_leave_tech.php";

  // Other
  static const String _fetchMyRating = "fetch_my_rating_tech.php";
  static const String _fetchMyReferral = "fetch_my_referral_tech.php";
  static const String _fetchWorkArea = "fetch_work_area_tech.php";
  static const String _getLoginHistory = "get_login_history_tech.php";

  // ————————————————————————
  // 🔹 Dashboard & Profile
  // ————————————————————————

  Future<TechDashboardModel?> getDashboard() async {
    try {
      final res = await _apiClient.post(_dashboard);
      return _apiClient.handleResponse(
        res,
        (json) => TechDashboardModel.fromJson(json),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final res = await _apiClient.post(_fetchProfile);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return json['data'];
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<TechnicianKycModel?> fetchKycDetails() async {
    try {
      final res = await _apiClient.post(_fetchKyc);
      return _apiClient.handleResponse(
        res,
        (json) => TechnicianKycModel.fromJson(json['data']),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<TechnicianProfileModel?> fetchUnifiedProfile() async {
    try {
      final profileData = await fetchProfile();
      if (profileData == null) return null;

      final baseProfile = TechnicianProfileModel.fromProfileData(profileData);
      final kycData = await fetchKycDetails();
      return kycData != null ? baseProfile.mergeWithKyc(kycData) : baseProfile;
    } catch (e, s) {
      _apiClient.logApiDebug(
        endpoint: 'fetchUnifiedProfile',
        method: 'COMBINED',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> body) async {
    try {
      final res = await _apiClient.post(_updateProfile, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Profile updated successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
      return false;
    }
  }

  // ————————————————————————
  // 🔹 Tickets
  // ————————————————————————

  Future<List<TicketModel>?> fetchAllTicketsWithFilter({
    String filter = 'all',
    String? startDate,
    String? endDate,
  }) async {
    final body = <String, dynamic>{'filter': filter, 'limit': 50};
    if (startDate != null) body['startDate'] = startDate;
    if (endDate != null) body['endDate'] = endDate;

    try {
      final res = await _apiClient.post(_fetchAllTickets, body: body);
      return _apiClient.handleListResponse(
        res,
        (item) => TicketModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<List<TicketModel>?> fetchRelocationTicket() async {
    try {
      final res = await _apiClient.get(_fetchRelocationTicket);
      return _apiClient.handleListResponse(
        res,
        (item) => TicketModel.fromRelocationJson(item), // ✅ CORRECT FACTORY
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<List<TicketModel>?> fetchDisconnectionTickets() async {
    // final body = <String, dynamic>{'filter': filter, 'limit': 50};
    // if (startDate != null) body['startDate'] = startDate;
    // if (endDate != null) body['endDate'] = endDate;

    try {
      final res = await _apiClient.get(_fetchDisconnectionTicket);
      // print(res.body);
      return _apiClient.handleListResponse(
        res,
        (item) => TicketModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<TicketModel?> fetchTicketByTicketNo(String ticketNo) async {
    final body = {'ticket_no': ticketNo};
    try {
      final res = await _apiClient.post(_fetchTicketByTicketNo, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return TicketModel.fromJson(json['data']);
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<bool> closeComplaint({
    required String ticketNo,
    required String closedRemark,
  }) async {
    final body = {'ticket_no': ticketNo, 'closed_remark': closedRemark};
    try {
      final res = await _apiClient.post(_complaintClose, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Ticket closed successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<bool> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final res = await _apiClient.post(_createTicket, body: ticketData);
      return _apiClient.handleSuccessResponse(
        res,
        "Ticket created successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
      return false;
    }
  }

  // ————————————————————————
  // 🔹 Customers
  // ————————————————————————

  Future<List<CustomerModel>?> fetchAllCustomers() async {
    try {
      final res = await _apiClient.get(_fetchAllCustomers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('history')) {
          final List data = json['history'];
          return data.map((e) => CustomerModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  Future<FindCustomerDetail?> fetchCustomerById(int findCustomerId) async {
    final body = {'find_customer_id': findCustomerId};
    try {
      final res = await _apiClient.post(_fetchCustomerSingle, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          final data = json['data'] as Map<String, dynamic>?;
          // if (data != null && data.containsKey('customer_details')) {
          //   final customerJson =
          //       data['customer_details'] as Map<String, dynamic>;
          return FindCustomerDetail.fromJson(data!);
          // }
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      // Optionally log other errors
      debugPrint('fetchCustomerById error: $e');
    }
    return null;
  }

  Future<List<CustomerModel>?> searchCustomers(String query) async {
    try {
      final res = await _apiClient.post(
        _fetchCustomerByMobOrName,
        body: {"customer_mobOrName": query},
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' &&
            json.containsKey('data') &&
            json['data'] is List) {
          final List data = json['data'];
          return data
              .where((item) => item is Map<String, dynamic>)
              .map((e) => CustomerModel.fromJson(e))
              .toList();
        }
        return [];
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  // ————————————————————————
  // 🔹 Installation Customers
  // ————————————————————————

  Future<List<Map<String, dynamic>>?> fetchWireInstallationCustomers() async {
    try {
      final res = await _apiClient.get(_fetchWireInstallationCustomers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;

        print("WireInstallationCustomersController result: $json");
        final List data = json['data'];
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
    // return ;
  }

  Future<Map<String, dynamic>?> fetchWireInstallationCustomersDetails(
    int findCustomerId,
  ) async {
    final body = {'registration_id': findCustomerId};
    try {
      final res = await _apiClient.post(
        _fetchWireInstallationCustomersDetails,
        body: body,
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == true) {
          return json; // Return full response: { "status": true, "customer": {...}, "wire_installation": {...} }
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchOltIpList() async {
    try {
      final res = await _apiClient.get(_fetchOltIpList);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        // The API returns status:true and the lists at the top level
        if (json['status'] == true) {
          return json; // Return the full map
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<bool> updateWireInstallation(Map<String, dynamic> body) async {
    try {
      final res = await _apiClient.post(_updateWireInstallation, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Wire installation updated successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchModemInstallationCustomers() async {
    try {
      final res = await _apiClient.get(_fetchModemInstallationCustomers);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          // final List data = json['history'];
          return json;
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchModemInstallationCustomersDetails(
    int findCustomerId,
  ) async {
    final body = {'find_customer_id': findCustomerId};
    try {
      final res = await _apiClient.post(
        _fetchModemInstallationCustomersDetails,
        body: body,
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          // final List data = json['history'];
          return json;
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  // ————————————————————————
  // 🔹 Attendance
  // ————————————————————————

  // ————————————————————————
  // 🔹 Attendance (UPDATED)
  // ————————————————————————

  Future<bool> punchIn({
    // required String technicianId,
    // required String locationName,
    required String lat,
    required String lng,
    required String loginImageBase64, // ✅ ADD THIS
  }) async {
    // final deviceInfo = await DeviceInfoUtils.getAllDeviceInfo();
    final body = {
      'in_lat': lat, 'in_long': lng,
      'login_image': loginImageBase64, // ✅ SEND IMAGE
      // ...deviceInfo,
    };
    try {
      final res = await _apiClient.post(_punchIn, body: body);
      return _apiClient.handleSuccessResponse(res, "Punched in successfully!");
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<bool> punchOut({
    // required String technicianId,
    // required String locationName,
    required String lat,
    required String lng,
    required String logoutImageBase64, // ✅ ADD THIS
  }) async {
    // final deviceInfo = await DeviceInfoUtils.getAllDeviceInfo();
    final body = {
      'in_lat': lat, 'in_long': lng,
      'logout_image': logoutImageBase64, // ✅ SEND IMAGE
      // ...deviceInfo,
    };
    try {
      final res = await _apiClient.post(_punchOut, body: body);
      return _apiClient.handleSuccessResponse(res, "Punched out successfully!");
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchAttendance() async {
    try {
      final res = await _apiClient.post(_fetchAttendance);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchTodayAttendance() async {
    try {
      final res = await _apiClient.post(_fetchTodayAttendance);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return json['data'];
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchAttendanceDashboard() async {
    try {
      final res = await _apiClient.post(_attendanceDashboard);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return json['data'];
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  // ————————————————————————
  // 🔹 Leave
  // ————————————————————————

  Future<bool> applyForLeave({
    required String startDate,
    required String endDate,
    required String leaveType,
    required String reason,
    String? attachments,
  }) async {
    final body = {
      'start_date': startDate,
      'end_date': endDate,
      'leave_type': leaveType,
      'reason': reason,
      if (attachments != null) 'attachments': attachments,
    };
    try {
      final res = await _apiClient.post(_applyLeave, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Leave applied successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchLeaves() async {
    try {
      final res = await _apiClient.post(_fetchLeaves);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  Future<bool> cancelLeave(int leaveId) async {
    final body = {'leave_id': leaveId};
    try {
      final res = await _apiClient.post(_cancelLeave, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Leave cancelled successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  // ————————————————————————
  // 🔹 Expenses
  // ————————————————————————

  Future<bool> addExpense({
    required String expenseTitle,
    required double amount,
    required String expenseDate,
    required String image, // base64
    required String paymentMode,
    required String expenseCategory,
    String? description,
    String? remark,
  }) async {
    final body = {
      'expense_title': expenseTitle,
      'amount': amount,
      'expense_date': expenseDate,
      'image': image,
      'payment_mode': paymentMode,
      'status': 'Pending',
      'expense_category': expenseCategory,
      if (description != null) 'description': description,
      if (remark != null) 'remark': remark,
    };
    try {
      final res = await _apiClient.post(_addExpense, body: body);
      return _apiClient.handleSuccessResponse(
        res,
        "Expense added successfully!",
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchExpenses() async {
    try {
      final res = await _apiClient.post(_fetchExpenses);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchExpenseDetails(int expenseId) async {
    final body = {'id': expenseId};
    try {
      final res = await _apiClient.post(_fetchExpenseDetails, body: body);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return json['data'];
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  // ————————————————————————
  // 🔹 Others
  // ————————————————————————

  Future<Map<String, dynamic>?> fetchMyRating() async {
    try {
      final res = await _apiClient.post(_fetchMyRating);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') return json['data'];
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchMyReferral() async {
    try {
      final res = await _apiClient.post(_fetchMyReferral);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') return json['data'];
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchWorkArea() async {
    try {
      final res = await _apiClient.post(_fetchWorkArea);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') return json['data'];
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getLoginHistory() async {
    try {
      final res = await _apiClient.post(_getLoginHistory);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          return (json['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return [];
  }

  Future<List<NotificationData>?> getNotifications() async {
    try {
      final res = await _apiClient.get(_getNotifications);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          final List data = json['data'];
          return data
              .where((item) => item is Map<String, dynamic>)
              .map((e) => NotificationData.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
      }
    }
    return [];
  }

  // ————————————————————————
  // 🔹 Location Tracking
  // ————————————————————————

  /// Track technician real-time location
  ///
  /// API Format:
  /// Request:
  /// {
  ///   "technician_id": "1223",
  ///   "date": "2025-08-22",
  ///   "session_datetime": "2025-08-20 13:30:54",
  ///   "location": {
  ///     "location_name": "10:34",  // time in HH:MM format
  ///     "lat": "34.7128",
  ///     "lng": "-34.0060"
  ///   }
  /// }
  ///
  /// Response:
  /// {
  ///   "status": "success",
  ///   "message": "Location stored successfully"
  /// }
  Future<bool> trackLocation({
    required String date, // YYYY-MM-DD format
    required String sessionDateTime, // YYYY-MM-DD HH:MM:SS format
    required String latitude,
    required String longitude,
    required String locationName, // HH:MM time format
  }) async {
    final body = {
      'technician_id': AppSharedPref.instance.getUserID().toString(),
      'date': date,
      'session_datetime': sessionDateTime,
      'location': {
        'location_name': locationName,
        'lat': latitude,
        'lng': longitude,
      },
    };

    try {
      final res = await _apiClient.post(_trackLocation, body: body);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;

        if (json['status'] == 'success') {
          print('✅ Location tracked: ${json['message']}');
          return true;
        } else {
          print('❌ Location tracking failed: ${json['message']}');
          return false;
        }
      }

      return false;
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) {
        _apiClient.unauthorized();
        return false;
      }
      print('Error tracking location: $e');
      return false;
    }
  }

  /// Track location with current date-time (convenience method)
  ///
  /// Usage:
  /// ```dart
  /// await _techAPI.trackLocationNow(
  ///   latitude: '34.7128',
  ///   longitude: '-34.0060',
  ///   locationName: '10:34', // Current time
  /// );
  /// ```
  Future<bool> trackLocationNow({
    required String latitude,
    required String longitude,
    required String locationName, // Time in HH:MM format
  }) async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final sessionDateTime =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return trackLocation(
      date: date,
      sessionDateTime: sessionDateTime,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
    );
  }

  /// Track location for ticket with context
  ///
  /// Usage:
  /// ```dart
  /// await _techAPI.trackLocationForTicket(
  ///   latitude: '34.7128',
  ///   longitude: '-34.0060',
  ///   date: '2025-08-22',
  ///   time: '10:34', // Current time HH:MM
  /// );
  /// ```
  Future<bool> trackLocationForTicket({
    required String latitude,
    required String longitude,
    required String date,
    required String time, // HH:MM format
  }) async {
    final now = DateTime.now();
    final sessionDateTime =
        '$date ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return trackLocation(
      date: date,
      sessionDateTime: sessionDateTime,
      latitude: latitude,
      longitude: longitude,
      locationName: time,
    );
  }

  // ————————————————————————
  // 🔹 Work Status Update
  // ————————————————————————
  //   final body = {
  //     {
  //       "current_stage":
  //           4, //0-assigned, 1 Accept Job, 2. On the way, 3. Reached customer location4. Work in progress,5.Completed
  //       // "customer_id":customer_id,
  //       "ticket_no": "TKT-D-251208-162440-140",
  //       "status": "Work in progress",
  //       "lat": "12.888",
  //       "long": "16.6767",
  //     },
  //   };
  //   // ...deviceInfo,

  //   try {
  //     final res = await _apiClient.post(
  //       _technicianWorkLiveStatusUpdate,
  //       body: body,
  //     );
  //     if (res.statusCode == 200) {
  //       final json = jsonDecode(res.body);
  //       return json['status'] == 'success';
  //     }
  //   } catch (e) {
  //     if (e.toString().contains('Unauthorized: No token')) return false;
  //   }
  //   return false;
  // }
  Future<Map<String, dynamic>?> fetchTodayTickets() async {
    final response = await _apiClient.get('fetch_ticket_dashboard_today.php');
    return jsonDecode(response.body);
  }

  Future<bool> updateLiveTicketStatus({
    required String ticketNo,
    required int customerId,
    required int currentStage,
    required String status,
    required String lat,
    required String long,
  }) async {
    try {
      final response = await _apiClient.post(
        'technician_work_live_status.php',
        body: {
          'ticket_no': ticketNo,
          'customer_id': customerId,
          'technician_id': AppSharedPref.instance.getUserID(),
          'current_stage': currentStage,
          'status': status,
          'lat': lat,
          'long': long,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ Update ticket status with closure remarks (Category, Subcategory, Remark)
  ///
  /// Stages:
  /// 0 = Assigned
  /// 1 = Accept Job
  /// 2 = On the way
  /// 3 = Reached customer location
  /// 4 = Work in progress
  /// 5 = Completed
  Future<dynamic> updateTicketWorkStatus({
    required String ticketNo,
    required int customerId,
    required int currentStage,
    required String status,
    required String lat,
    required String long,
    String? closureCategory,
    String? closureSubcategory,
    String? closureRemark,
  }) async {
    try {
      final body = {
        'current_stage': currentStage,
        'customer_id': customerId,
        'ticket_no': ticketNo,
        'status': status,
        'lat': lat,
        'long': long,
      };

      // ✅ Add closure details if provided
      if (closureRemark != null && closureRemark.isNotEmpty) {
        body['closed_remark'] = closureRemark;
      }
      if (closureCategory != null) {
        body['closure_category'] = closureCategory;
      }
      if (closureSubcategory != null) {
        body['closure_subcategory'] = closureSubcategory;
      }

      debugPrint('🔵 UPDATE TICKET STATUS');
      debugPrint('Endpoint: technician_work_live_status.php');
      debugPrint('Body: $body');

      final res = await _apiClient.post(
        _technicianWorkLiveStatusUpdate,
        body: body,
      );

      debugPrint('Response Status: ${res.statusCode}');
      debugPrint('Response Body: ${res.body}');

      return _apiClient.handleResponse(res, (json) => json);
    } catch (e) {
      debugPrint('❌ Error updating ticket status: $e');
      rethrow;
    }
  }
}
