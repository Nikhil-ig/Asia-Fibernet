// // services/apis/attendance_leave_api.dart

// import 'dart:convert';

// import '../../technician/core/models/attendance_and_leave_model.dart';
// import 'base_api_service.dart';

// class AttendanceLeaveAPI {
//   static const String _baseURL = "${BaseApiService.api}techAPI/";
//   final BaseApiService _apiClient = BaseApiService(
//     _baseURL,
//   ); // Instance for tech API
//   // Endpoints
//   static const String _punchIn = "punch_in_tech.php";
//   static const String _punchOut = "punch_out_tech.php";
//   static const String _fetchAttendance = "fetch_attendance_tech.php";
//   static const String _fetchLeaves = "fetch_leaves_tech.php";
//   static const String _cancelLeave = "cancel_leave_tech.php";
//   static const String _fetchTodayAttendance = "fetch_today_attendance_tech.php";
//   static const String _applyLeave = "apply_leave_tech.php";
//   static const String _fetchHolidays = "holiday_calendar_tech.php";

//   /// Punch In with location
//   Future<AttendanceModel?> punchIn({
//     required String inLat,
//     required String inLong,
//   }) async {
//     try {
//       final body = {'in_lat': inLat, 'in_long': inLong};

//       final res = await _apiClient.post(_punchIn, body: body);

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success') {
//           _apiClient.showSnackbar(
//             "Success",
//             json['message'] ?? "Punched in successfully!",
//             isError: false,
//           );
//           return AttendanceModel.fromJson(json['data']);
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "Punch-in failed.",
//           );
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _punchIn,
//         method: 'POST',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to punch in.");
//     }
//     return null;
//   }

//   /// Punch Out with location
//   Future<bool> punchOut({required String inLat, required String inLong}) async {
//     try {
//       final body = {'in_lat': inLat, 'in_long': inLong};

//       final res = await _apiClient.post(_punchOut, body: body);

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success') {
//           _apiClient.showSnackbar(
//             "Success",
//             json['message'] ?? "Punched out successfully!",
//             isError: false,
//           );
//           return true;
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "Punch-out failed.",
//           );
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _punchOut,
//         method: 'POST',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to punch out.");
//     }
//     return false;
//   }

//   /// Fetch attendance for a specific month (YYYY-MM)
//   Future<List<AttendanceModel>?> fetchAttendanceByMonth(String month) async {
//     try {
//       final res = await _apiClient.get(
//         _fetchAttendance,
//         queryParameters: {'month': month},
//       );

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success' && json.containsKey('data')) {
//           final List<dynamic> data = json['data'];
//           return data
//               .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
//               .toList();
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "No attendance data found.",
//           );
//           return [];
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _fetchAttendance,
//         method: 'GET',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to load attendance.");
//     }
//     return null;
//   }

//   /// Fetch today’s attendance record
//   Future<AttendanceModel?> fetchTodayAttendance() async {
//     try {
//       final res = await _apiClient.get(_fetchTodayAttendance);

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success' && json.containsKey('data')) {
//           final data = json['data'];

//           if (data is List) {
//             if (data.isEmpty) return null;
//             // Take first item if list
//             return AttendanceModel.fromJson(data[0] as Map<String, dynamic>);
//           } else if (data is Map<String, dynamic>) {
//             return AttendanceModel.fromJson(data);
//           } else {
//             _apiClient.showSnackbar("Error", "Invalid data format.");
//             return null;
//           }
//         } else {
//           _apiClient.showSnackbar(
//             "Info",
//             json['message'] ?? "No attendance for today.",
//           );
//           return null;
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _fetchTodayAttendance,
//         method: 'GET',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to load today's attendance.");
//     }
//     return null;
//   }

//   /// Apply for a new leave
//   Future<bool> applyLeave({
//     required String leaveType,
//     required String startDate,
//     required String endDate,
//     required String reason,
//   }) async {
//     try {
//       final body = {
//         'leave_type': leaveType,
//         'start_date': startDate,
//         'end_date': endDate,
//         'reason': reason,
//       };

//       final res = await _apiClient.post(_applyLeave, body: body);

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success') {
//           _apiClient.showSnackbar(
//             "Success",
//             json['message'] ?? "Leave applied successfully!",
//             isError: false,
//           );
//           return true;
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "Failed to apply leave.",
//           );
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _applyLeave,
//         method: 'POST',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to submit leave request.");
//     }
//     return false;
//   }

//   /// Fetch leaves for a specific month (YYYY-MM)
//   Future<List<LeaveModel>?> fetchLeavesByMonth(String month) async {
//     try {
//       final res = await _apiClient.get(
//         _fetchLeaves,
//         queryParameters: {'month': month},
//       );

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success' && json.containsKey('data')) {
//           final List<dynamic> data = json['data'];
//           return data
//               .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
//               .toList();
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "No leave data found.",
//           );
//           return [];
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _fetchLeaves,
//         method: 'GET',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to load leaves.");
//     }
//     return null;
//   }

//   /// Cancel a leave request by ID
//   Future<bool> cancelLeave(int leaveId) async {
//     try {
//       final body = {'leave_id': leaveId};

//       final res = await _apiClient.put(_cancelLeave, body: body);

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success') {
//           _apiClient.showSnackbar(
//             "Success",
//             json['message'] ?? "Leave cancelled successfully!",
//             isError: false,
//           );
//           return true;
//         } else {
//           _apiClient.showSnackbar(
//             "Error",
//             json['message'] ?? "Failed to cancel leave.",
//           );
//         }
//       } else {
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       _apiClient.logApiDebug(
//         endpoint: _cancelLeave,
//         method: 'PUT',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to cancel leave.");
//     }
//     return false;
//   }

//   /// Fetch holidays for a specific month (YYYY-MM)
//   Future<List<HolidayModel>?> fetchHolidaysByMonth(String month) async {
//     try {
//       // Assuming the endpoint expects a 'month' query parameter like the others
//       final res = await _apiClient.post(
//         _fetchHolidays,
//         // body: {'month': month}, // Pass month parameter
//       );

//       if (res.statusCode == 200) {
//         final json = jsonDecode(res.body) as Map<String, dynamic>;
//         if (json['status'] == 'success' && json.containsKey('data')) {
//           final List<dynamic> data = json['data'];
//           // Map the JSON list to HolidayModel objects
//           return data
//               .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
//               .toList();
//         } else {
//           // Handle API response indicating no data or an error message
//           // _apiClient.showSnackbar(
//           //   "Info", // Use Info level if it's just no holidays
//           //   json['message'] ?? "No holidays found for this month.",
//           // );
//           return []; // Return empty list if no holidays, not null
//         }
//       } else {
//         // Handle HTTP errors (e.g., 404, 500)
//         _apiClient.handleHttpError(res.statusCode);
//       }
//     } catch (e, s) {
//       // Log the error and show a user-friendly message
//       _apiClient.logApiDebug(
//         endpoint: _fetchHolidays,
//         method: 'POST',
//         error: e,
//         stackTrace: s,
//       );
//       _apiClient.showSnackbar("Error", "Failed to load holidays.");
//     }
//     // Return null if the request failed unexpectedly
//     return null;
//   }
// }

// services/apis/attendance_leave_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:asia_fibernet/src/services/utils/plugin/device_info_utils.dart';

import '../../technician/core/models/attendance_and_leave_model.dart';
import 'base_api_service.dart';

class AttendanceLeaveAPI {
  // static const String _baseURL = "${BaseApiService.api}techAPI/";
  final BaseApiService _apiClient = BaseApiService(BaseApiService.apiTech);

  // Endpoints
  static const String _punchIn = "punch_in_tech.php";
  static const String _punchOut = "punch_out_tech.php";
  static const String _fetchAttendance = "fetch_attendance_tech.php";
  static const String _fetchLeaves = "fetch_leaves_tech.php";
  static const String _cancelLeave = "cancel_leave_tech.php";
  static const String _fetchTodayAttendance = "fetch_today_attendance_tech.php";
  static const String _applyLeave = "apply_leave_tech.php";
  static const String _fetchHolidays = "holiday_calendar_tech.php";
  static const String _fetchAbsentData = "fetch_absent_data_tech.php";

  // ————————————————————————
  // 🔹 Attendance
  // ————————————————————————

  Future<AttendanceModel?> punchIn({File? image}) async {
    String? inLat;
    String? inLong;
    String? loginImageBase64 = await _apiClient.fileToBase64(image!);
    await DeviceInfoUtils.getLocation().then((value) {
      inLat = value!.latitude.toString();
      inLong = value.longitude.toString();
    });
    final body = {
      'in_lat': inLat,
      'in_long': inLong,
      'login_image': loginImageBase64, // ✅ SEND IMAGE
    };
    try {
      final res = await _apiClient.post(_punchIn, body: body);
      return _apiClient.handleResponse(
        res,
        (json) => AttendanceModel.fromJson(json['data']),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<bool> punchOut({File? image}) async {
    String? inLat;
    String? inLong;
    String? logoutImageBase64 = await _apiClient.fileToBase64(image!);
    await DeviceInfoUtils.getLocation().then((value) {
      inLat = value!.latitude.toString();
      inLong = value.longitude.toString();
    });
    final body = {
      'in_lat': inLat,
      'in_long': inLong,
      'logout_image': logoutImageBase64,
    };
    try {
      final res = await _apiClient.post(_punchOut, body: body);
      return _apiClient.handleSuccessResponse(res, "Punched out successfully!");
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return false;
      return false;
    }
  }

  Future<List<AttendanceModel>?> fetchAttendanceByMonth(String month) async {
    try {
      final res = await _apiClient.get(
        _fetchAttendance,
        queryParameters: {'month': month},
      );
      return _apiClient.handleListResponse(
        res,
        (item) => AttendanceModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

  Future<AttendanceModel?> fetchTodayAttendance() async {
    try {
      final res = await _apiClient.get(_fetchTodayAttendance);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          final data = json['data'];
          if (data == null) return null;
          if (data is List && data.isNotEmpty) {
            return AttendanceModel.fromJson(data[0] as Map<String, dynamic>);
          } else if (data is Map<String, dynamic>) {
            return AttendanceModel.fromJson(data);
          }
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

  Future<bool> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    final body = {
      'leave_type': leaveType,
      'start_date': startDate,
      'end_date': endDate,
      'reason': reason,
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

  Future<List<LeaveModel>?> fetchLeavesByMonth(String month) async {
    try {
      final res = await _apiClient.get(
        _fetchLeaves,
        queryParameters: {'month': month},
      );
      return _apiClient.handleListResponse(
        res,
        (item) => LeaveModel.fromJson(item),
      );
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
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

  Future<List<LeaveModel>> fetchAllLeaves() async {
    try {
      final res = await _apiClient.get(_fetchLeaves);
      return _apiClient.handleListResponse(
            res,
            (item) => LeaveModel.fromJson(item),
          ) ??
          [];
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return [];
      return [];
    }
  }

  // ————————————————————————
  // 🔹 Holidays
  // ————————————————————————

  Future<List<HolidayModel>?> fetchHolidaysByMonth(String month) async {
    try {
      // Assuming the API expects month in body (as per original)
      final res = await _apiClient.post(_fetchHolidays, body: {'month': month});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success' && json.containsKey('data')) {
          final List data = json['data'];
          return data
              .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }

  // ————————————————————————
  // 🔹 Absent Data
  // ————————————————————————

  /// Fetches absent data for a specific month (YYYY-MM)
  Future<AbsentData?> fetchAbsentData(String month) async {
    try {
      final res = await _apiClient.get(
        _fetchAbsentData,
        queryParameters: {'month': month},
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'success') {
          return AbsentData.fromJson(json);
        } else {
          _apiClient.showSnackbar(
            "Info",
            json['message'] ?? "No absent data found for this month.",
          );
        }
      } else {
        _apiClient.handleHttpError(res.statusCode);
      }
    } catch (e) {
      _apiClient.showSnackbar("Error", "Failed to load absent data.");
      if (e.toString().contains('Unauthorized: No token')) return null;
    }
    return null;
  }
}
