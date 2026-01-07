// lib/screens/attendance/attendance_controller.dart
import 'dart:io';
import 'dart:ui';
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/sharedpref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:table_calendar/table_calendar.dart'; // Not used in CustomCalendar
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/models/attendance_and_leave_model.dart';
import '../ui/widgets/custom_calendar.dart';
// ✅ STEP 1: Import the REAL API and Models
import '../../services/apis/attendance_leave_api.dart';
import 'holidays_list_screen.dart';
import 'leaves_list_screen.dart';

// Model to represent events in the calendar UI
class AttendanceEvent {
  final String type; // 'attendance', 'leave', 'holiday'
  final String
  status; // e.g., 'Present', 'Absent', 'Pending', 'Approved', 'Rejected', 'Holiday'
  final String? punchIn;
  final String? punchOut;
  final String? leaveType;
  final String? remark; // For leave reason or holiday name
  final int? leaveId;

  AttendanceEvent({
    required this.type,
    required this.status,
    this.punchIn,
    this.punchOut,
    this.leaveType,
    this.remark,
    this.leaveId,
  });

  @override
  String toString() {
    return 'AttendanceEvent{type: $type, status: $status, punchIn: $punchIn, punchOut: $punchOut, leaveType: $leaveType, remark: $remark, leaveId: $leaveId}';
  }
}

class AttendanceController extends GetxController {
  final AttendanceLeaveAPI _api = AttendanceLeaveAPI();
  final BaseApiService _baseApiService = Get.find<BaseApiService>();
  final AppSharedPref _prefs = AppSharedPref.instance;
  String get technicianId => _prefs.getUserID().toString();

  // Calendar State
  var calendarFormat = CalendarFormat.month.obs;
  var focusedDay = DateTime.now().obs;
  var selectedDay = DateTime.now().obs;
  // Track the currently focused month for fetching data
  var focusedMonth = DateTime.now().obs;

  // Events Map: DateTime -> List<AttendanceEvent>
  // Key: DateTime.utc(year, month, day) for consistency
  var events = <DateTime, List<AttendanceEvent>>{}.obs;
  // Holidays Map: DateTime -> HolidayModel (for direct access if needed by UI)
  // Key: DateTime.utc(year, month, day) for consistency
  var holidays = <DateTime, HolidayModel>{}.obs;
  var isLoadingHolidays = false.obs; // Loading state for holidays

  // UI State
  var selectedEvents = <AttendanceEvent>[].obs;
  var isLoading = true.obs;
  var isPunching = false.obs;

  // Text Editing Controllers for Leave Request
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final remarkController = TextEditingController();
  String? leaveType = "sick";

  File? _capturedImage;

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _capturedImage = File(pickedFile.path);
    } else {
      // User cancelled
      _baseApiService.showSnackbar(
        "⚠️ Warning",
        "No image captured. Punch action cancelled.",
      );
      _capturedImage = null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadEvents(); // Load initial data for the current month
    // Listen to changes in focusedMonth to load data for that month
    ever(focusedMonth, (_) => loadEventsForMonth(focusedMonth.value));
  }

  // Load events (attendance, leaves, holidays) for a specific month
  // Inside AttendanceController class

  // Load events (attendance, leaves, holidays) for a specific month
  Future<void> loadEvents({DateTime? forMonth}) async {
    final targetMonth = forMonth ?? focusedMonth.value;
    final String monthString = DateFormat('yyyy-MM').format(targetMonth);
    isLoading.value = true;
    isLoadingHolidays.value = true; // Start loading holidays too

    try {
      // Fetch Attendance, Leaves, Holidays, and Absent Data in parallel for efficiency
      final attendanceFuture = _api.fetchAttendanceByMonth(monthString);
      final leavesFuture = _api.fetchLeavesByMonth(monthString);
      final holidaysFuture = _api.fetchHolidaysByMonth(monthString);
      final absentDataFuture = _api.fetchAbsentData(monthString);

      final results = await Future.wait([
        attendanceFuture,
        leavesFuture,
        holidaysFuture,
        absentDataFuture,
      ], eagerError: false);

      final attendanceList = results[0] as List<AttendanceModel>?;
      final leaveList = results[1] as List<LeaveModel>?;
      final holidayList = results[2] as List<HolidayModel>?;
      final absentData = results[3] as AbsentData?;
      // Use UTC DateTime keys consistently for all events
      final newEvents = <DateTime, List<AttendanceEvent>>{};
      final newHolidays = <DateTime, HolidayModel>{};

      // Create a set of absent days for quick lookup. Use UTC keys.
      final Set<DateTime> absentDaysSet = {};
      if (absentData != null) {
        for (var absentDay in absentData.absentDays) {
          absentDaysSet.add(
            DateTime.utc(absentDay.year, absentDay.month, absentDay.day),
          );
        }
      }

      // Process Absences FIRST to establish them as the source of truth
      for (final absentDayKey in absentDaysSet) {
        if (!newEvents.containsKey(absentDayKey)) {
          newEvents[absentDayKey] = [];
        }
        newEvents[absentDayKey]!.add(
          AttendanceEvent(type: 'attendance', status: 'Absent'),
        );
      }

      // Process Attendance Records - Use UTC keys
      if (attendanceList != null) {
        for (var record in attendanceList) {
          final parsedDate = DateTime.parse(
            record.date,
          ); // Parse to local DateTime
          // Create consistent UTC key
          final dateKey = DateTime.utc(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
          );

          // If the day is explicitly marked as absent, skip this attendance record
          // to avoid conflicts (e.g., creating a 'Present' event on an absent day).
          if (absentDaysSet.contains(dateKey)) {
            continue;
          }

          if (!newEvents.containsKey(dateKey)) {
            newEvents[dateKey] = [];
          }

          // Since we've handled absent days, any record from this API implies presence.
          const status = 'Present';

          newEvents[dateKey]!.add(
            AttendanceEvent(
              type: 'attendance',
              status: status,
              punchIn: record.intime,
              punchOut: record.outtime,
            ),
          );
        }
      }

      // Process Leave Records - Use UTC keys
      if (leaveList != null) {
        for (var leave in leaveList) {
          final startDate = DateTime.parse(leave.startDate);
          final endDate = DateTime.parse(leave.endDate);
          for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
            final leaveDate = startDate.add(Duration(days: i));
            // Create consistent UTC key
            final leaveDateKey = DateTime.utc(
              leaveDate.year,
              leaveDate.month,
              leaveDate.day,
            );

            if (!newEvents.containsKey(leaveDateKey)) {
              newEvents[leaveDateKey] = [];
            }
            newEvents[leaveDateKey]!.add(
              AttendanceEvent(
                type: 'leave',
                status: leave.status.toUpperCase(),
                punchIn: null,
                punchOut: null,
                leaveType: leave.leaveType,
                remark: leave.reason,
                leaveId: leave.id,
              ),
            );
          }
        }
      }

      // Process Holiday Records - Use UTC keys (already correct)
      if (holidayList != null) {
        for (var holiday in holidayList) {
          try {
            if (holiday.date.trim().isEmpty) {
              print(
                "Warning: Skipping holiday '${holiday.title}' (ID: ${holiday.id}) due to missing or empty date string.",
              );
              continue;
            }
            final DateTime? holidayDate = DateFormat(
              'yyyy-MM-dd',
            ).parseStrict(holiday.date.trim());
            if (holidayDate != null) {
              // Create consistent UTC key
              final DateTime holidayDateKey = DateTime.utc(
                holidayDate.year,
                holidayDate.month,
                holidayDate.day,
              );
              newHolidays[holidayDateKey] = holiday;
              // Add holidays as events for display consistency
              if (!newEvents.containsKey(holidayDateKey)) {
                newEvents[holidayDateKey] = [];
              }
              newEvents[holidayDateKey]!.add(
                AttendanceEvent(
                  type: 'holiday',
                  status: 'Holiday', // Ensure status is 'Holiday'
                  punchIn: null,
                  punchOut: null,
                  leaveType: null,
                  remark: holiday.title,
                  leaveId: null,
                ),
              );
              print(
                "Warning: DateFormat.parseStrict returned null for date '${holiday.date}' (Holiday: ${holiday.title})",
              );
            }
          } catch (e) {
            print(
              "Error parsing holiday date ${holiday.date} for '${holiday.title}': $e",
            );
          }
        }
        print(
          "Finished processing holidays. newHolidays map size: ${newHolidays.length}",
        );
      } else {
        print("holidayList was null, no holidays to process.");
      }

      // Update the observable maps
      events.assignAll(newEvents);
      holidays.assignAll(newHolidays);
      print(
        "Controller maps updated. events size: ${events.length}, holidays size: ${holidays.length}",
      );

      updateSelectedDayEvents(); // This also needs to use UTC keys
    } catch (e) {
      print("Error loading calendar data: $e");
      BaseApiService().showSnackbar("❌ Error", "Failed to load calendar data.");
    } finally {
      isLoading.value = false;
      isLoadingHolidays.value = false;
    }
  }

  // Update updateSelectedDayEvents to also use UTC keys for lookup
  // void updateSelectedDayEvents() {
  //   // Create consistent UTC key for lookup
  //   final dayKey = DateTime.utc(
  //     selectedDay.value.year,
  //     selectedDay.value.month,
  //     selectedDay.value.day,
  //   );
  //   selectedEvents.value = events[dayKey] ?? [];
  //   print(
  //     "Selected day events updated for $dayKey (UTC): ${selectedEvents.length} events",
  //   );
  // }

  // Update helper methods to use UTC keys for consistency
  bool isHoliday(DateTime date) {
    // Create consistent UTC key for lookup
    final key = DateTime.utc(date.year, date.month, date.day);
    return holidays.containsKey(key);
  }

  HolidayModel? getHoliday(DateTime date) {
    // Create consistent UTC key for lookup
    final key = DateTime.utc(date.year, date.month, date.day);
    return holidays[key];
  }

  // Simplified method to load data specifically for a given month (used by the listener)
  Future<void> loadEventsForMonth(DateTime month) async {
    await loadEvents(forMonth: month);
  }

  // Fetch all leaves for the leaves list screen
  Future<List<LeaveModel>> fetchAllLeaves() async {
    try {
      return await _api.fetchAllLeaves();
    } catch (e) {
      print("Error fetching all leaves: $e");
      _baseApiService.showSnackbar(
        "❌ Error",
        "Failed to load leaves",
        isError: true,
      );
      return [];
    }
  }

  void onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    selectedDay.value = selectedDate;
    focusedDay.value = focusedDate;
    updateSelectedDayEvents();
  }

  void updateSelectedDayEvents() {
    // Get events for the selected day using a consistent UTC key
    final dayKey = DateTime.utc(
      selectedDay.value.year,
      selectedDay.value.month,
      selectedDay.value.day,
    );
    selectedEvents.value = events[dayKey] ?? [];
  }

  void onFormatChanged(CalendarFormat format) {
    calendarFormat.value = format;
  }

  // Modify punchInOut to require image
  Future<void> punchInOut() async {
    if (isPunching.value) return;

    // Capture image first
    await _captureImage();
    if (_capturedImage == null) return; // User cancelled or failed

    isPunching.value = true;
    try {
      final todayAttendance = await _api.fetchTodayAttendance();
      final isPunchedIn =
          todayAttendance != null && todayAttendance.outtime == null;

      bool success;
      if (isPunchedIn) {
        // Punch Out with image
        success = await _api.punchOut(
          image: _capturedImage!, // Pass image
        );
        if (success) {
          _baseApiService.showSnackbar(
            "✅ Success",
            "Punched out successfully!",
          );
        }
      } else {
        // Punch In with image
        final attendanceModel = await _api.punchIn(
          image: _capturedImage!, // Pass image
        );
        success = attendanceModel != null;
        if (success) {
          _baseApiService.showSnackbar("✅ Success", "Punched in successfully!");
        }
      }

      if (success) {
        await loadEvents();
        _capturedImage = null; // Clear after use
      }
    } catch (e) {
      print("Error during punch in/out: $e");
      _baseApiService.showSnackbar(
        "❌ Error",
        "Something went wrong. Please try again.",
        isError: true,
      );
    } finally {
      isPunching.value = false;
    }
  }

  void showLeaveRequestDialog() {
    startDateController.clear();
    endDateController.clear();
    remarkController.clear();
    final formKey = GlobalKey<FormState>();
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF8A65), // Deep Orange Light
                        Color(0xFFE64A19), // Deep Orange Dark
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.calendar_add, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        "Request Leave",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Form Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Leave Type Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Leave Type",
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors.textColorSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Iconsax.category,
                              color: Color(0xFFE64A19),
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Color(0xFFE64A19),
                                width: 2,
                              ),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: "casual",
                              child: Text("Casual Leave"),
                            ),
                            DropdownMenuItem(
                              value: "sick",
                              child: Text("Sick Leave"),
                            ),
                            DropdownMenuItem(
                              value: "paid",
                              child: Text("Paid Leave"),
                            ),
                            DropdownMenuItem(
                              value: "unpaid",
                              child: Text("UnPaid Leave"),
                            ),
                          ],
                          onChanged: (value) {
                            // Handle leave type change if needed
                            leaveType = value;
                          },
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? "Select leave type"
                                      : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Start Date
                      TextFormField(
                        controller: startDateController,
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Iconsax.calendar,
                            color: Color(0xFFE64A19),
                            size: 20,
                          ),
                          suffixIcon: Icon(
                            Iconsax.arrow_down_2,
                            color: AppColors.textColorSecondary,
                            size: 16,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE64A19),
                              width: 2,
                            ),
                          ),
                        ),
                        readOnly: true,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? "Select start date"
                                    : null,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: Get.context!,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            startDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      // End Date
                      TextFormField(
                        controller: endDateController,
                        decoration: InputDecoration(
                          labelText: "End Date",
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Iconsax.calendar,
                            color: Color(0xFFE64A19),
                            size: 20,
                          ),
                          suffixIcon: Icon(
                            Iconsax.arrow_down_2,
                            color: AppColors.textColorSecondary,
                            size: 16,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE64A19),
                              width: 2,
                            ),
                          ),
                        ),
                        readOnly: true,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? "Select end date"
                                    : null,
                        onTap: () async {
                          // Parse start date if available, otherwise use today
                          DateTime firstDateForPicker = DateTime.now();
                          if (startDateController.text.isNotEmpty) {
                            try {
                              firstDateForPicker = DateFormat(
                                'yyyy-MM-dd',
                              ).parse(startDateController.text);
                            } catch (e) {
                              // If parsing fails, use today's date
                              firstDateForPicker = DateTime.now();
                            }
                          }

                          DateTime? pickedDate = await showDatePicker(
                            context: Get.context!,
                            initialDate: firstDateForPicker,
                            firstDate: firstDateForPicker,
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            endDateController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                          }
                        },
                      ),
                      SizedBox(height: 20),
                      // Remark
                      TextFormField(
                        controller: remarkController,
                        decoration: InputDecoration(
                          labelText: "Remark (Optional)",
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Iconsax.note_1,
                            color: Color(0xFFE64A19),
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Color(0xFFE64A19),
                              width: 2,
                            ),
                          ),
                          hintText: "Why are you taking leave?",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorHint,
                          ),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
                // Action Buttons
                Padding(
                  padding: EdgeInsets.only(bottom: 24, left: 24, right: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(Get.context!).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                await submitLeaveRequest();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE64A19),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.all(0),
                              shadowColor: Colors.transparent,
                              side: BorderSide.none,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              height: double.infinity,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF8A65), // Deep Orange Light
                                    Color(0xFFE64A19), // Deep Orange Dark
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                "Submit Request",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> submitLeaveRequest() async {
    // Note: This logic for getting leaveType from startDateController.text seems incorrect.
    // You should get it from the DropdownButtonFormField.
    // This is left as is from the original code but is likely a bug.

    final startDate = startDateController.text;
    final endDate = endDateController.text;
    final reason = remarkController.text;
    print("leaveType: $leaveType");
    try {
      final success = await _api.applyLeave(
        leaveType: leaveType!,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      if (success) {
        _baseApiService.showSnackbar(
          "✅ Success",
          "Leave request submitted successfully!",
        );
        Navigator.pop(Get.context!);
        await loadEvents(); // Refresh calendar to show pending leave
      }
      // Error snackbar is handled inside _api.applyLeave
    } catch (e) {
      print("Error submitting leave request: $e");
      _baseApiService.showSnackbar(
        "❌ Error",
        "Something went wrong. Please try again.",
        isError: true,
      );
    }
  }

  Future<void> cancelLeave(int leaveId) async {
    try {
      final success = await _api.cancelLeave(leaveId);
      if (success) {
        _baseApiService.showSnackbar(
          "✅ Success",
          "Leave request cancelled successfully!",
        );
        await loadEvents(); // Refresh calendar
      }
      // Error snackbar is handled inside _api.cancelLeave
    } catch (e) {
      print("Error cancelling leave: $e");
      _baseApiService.showSnackbar(
        "❌ Error",
        "Something went wrong. Please try again.",
        isError: true,
      );
    }
  }

  // Add methods to navigate months and update focusedMonth
  void previousMonth() {
    focusedMonth.value = DateTime(
      focusedMonth.value.year,
      focusedMonth.value.month - 1,
      1,
    );
    focusedDay.value = focusedMonth.value; // Optionally update focused day
    // loadEventsForMonth is called automatically by the ever() listener
  }

  void nextMonth() {
    focusedMonth.value = DateTime(
      focusedMonth.value.year,
      focusedMonth.value.month + 1,
      1,
    );
    focusedDay.value = focusedMonth.value; // Optionally update focused day
    // loadEventsForMonth is called automatically by the ever() listener
  }

  // // Add a helper to check if a specific date is a holiday
  // bool isHoliday(DateTime date) {
  //   final key = DateTime.utc(date.year, date.month, date.day);
  //   return holidays.containsKey(key);
  // }

  // // Add a helper to get the holiday model for a specific date
  // HolidayModel? getHoliday(DateTime date) {
  //   final key = DateTime.utc(date.year, date.month, date.day);
  //   return holidays[key];
  // }

  @override
  void onClose() {
    startDateController.dispose();
    endDateController.dispose();
    remarkController.dispose();
    super.onClose();
  }
}

// lib/screens/attendance/attendance_screen.dart
class AttendanceScreen extends StatelessWidget {
  AttendanceScreen({super.key});

  final controller = Get.put(AttendanceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140.h,
              floating: false,
              pinned: true,
              // backgroundColor: AppColors.primary,
              backgroundColor: Color(0xFF6366F1),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Attendance & Leave",
                  style: AppText.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Iconsax.calendar_add, size: 26.w),
                  onPressed: controller.showLeaveRequestDialog,
                  tooltip: "Request Leave",
                ),
              ],
              iconTheme: IconThemeData(color: AppColors.backgroundLight),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Stats Overview (Reactive)
              _buildStatsOverview(),
              SizedBox(height: 20.h),
              // Punch Card (Reactive)
              _buildPunchCard(),
              SizedBox(height: 20.h),
              // Calendar Section
              _buildCalendarSection(),
              SizedBox(height: 16.h),
              // Legend
              _buildLegend(),
              // Selected Day Events
              _buildSelectedEvents(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Obx(() {
      int present = 0, absent = 0, leave = 0;

      // Calculate stats from events
      controller.events.forEach((date, events) {
        for (var event in events) {
          if (event.type == 'attendance') {
            if (event.status == 'Present') present++;
            if (event.status == 'Absent') absent++;
            if (event.status == 'Weekend' || event.status == 'Holiday')
              continue; // Don't count
          } else if (event.type == 'leave') {
            leave++;
          }
        }
      });

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              present.toString(),
              "Present",
              Iconsax.calendar_tick,
            ),
            _buildStatItem(leave.toString(), "Leaves", Iconsax.bezier),
            _buildStatItem(
              absent.toString(),
              "Absent",
              Iconsax.calendar_remove,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20.w, color: Colors.white),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // Inside attendance_screen.dart

  Widget _buildPunchCard() {
    return Obx(() {
      // Find today's events using a UTC DateTime key for consistency
      final today = DateTime.now();
      // Create the key using UTC, matching how events are stored in the controller
      final todayKey = DateTime.utc(today.year, today.month, today.day);
      // Use the UTC key to look up events
      final todayEvents = controller.events[todayKey] ?? [];

      // Find the first attendance event for today (if any)
      // Default to 'Not Punched' if no attendance event is found for today
      final todayAttendance = todayEvents.firstWhere(
        (e) => e.type == 'attendance',
        orElse:
            () => AttendanceEvent(
              type: 'attendance',
              status: 'Not Punched',
              // You might want to initialize other fields like punchIn/punchOut to null explicitly
              punchIn: null,
              punchOut: null,
            ),
      );

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "Today's Status",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPunchStatus(
                        "Punch In",
                        todayAttendance.punchIn ?? "--:--",
                        Iconsax.login_1,
                        todayAttendance.punchIn != null
                            ? Color(0xFF10B981) // Green if punched in
                            : AppColors.textColorSecondary, // Grey if not
                      ),
                      Container(
                        width: 1.w,
                        height: 40.h,
                        color: Colors.grey[200],
                      ),
                      _buildPunchStatus(
                        "Punch Out",
                        todayAttendance.punchOut ?? "--:--",
                        Iconsax.logout,
                        todayAttendance.punchOut != null &&
                                todayAttendance.punchOut != 'On Duty'
                            ? Color(0xFF10B981) // Green if punched out (normal)
                            : todayAttendance.punchOut == 'On Duty'
                            ? Color(0xFF3B82F6) // Blue if 'On Duty'
                            : Color(0xFFEF4444), // Red if not punched out
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (todayAttendance.punchIn == null)
                        _buildPunchButton(
                          "Punch IN",
                          Iconsax.login_1,
                          Color(0xFF10B981),
                          () => controller.punchInOut(),
                          "Start your day",
                        )
                      else if (todayAttendance.punchOut == null)
                        _buildPunchButton(
                          "Punch OUT",
                          Iconsax.logout,
                          Color(0xFFEF4444),
                          () => controller.punchInOut(),
                          "End your day",
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPunchButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Obx(
      () => Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: controller.isPunching.value ? null : onPressed,
            icon: Icon(icon, size: 20.w, color: Colors.white),
            label: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPunchStatus(
    String label,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 24.w, color: color),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.textColorSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          time,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorPrimary,
          ),
        ),
      ],
    );
  }

  // Widget _buildPunchButton(
  //   String label,
  //   IconData icon,
  //   Color color,
  //   VoidCallback onPressed,
  //   String tooltip,
  // ) {
  //   return Obx(
  //     () => Tooltip(
  //       message: tooltip,
  //       child: ElevatedButton.icon(
  //         onPressed: controller.isPunching.value ? null : onPressed,
  //         icon: Icon(icon, size: 20.w, color: AppColors.backgroundLight),
  //         label: Text(
  //           label,
  //           style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
  //         ),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: color,
  //           foregroundColor: Colors.white,
  //           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(12.r),
  //           ),
  //           elevation: 3,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.r),
              bottom: Radius.circular(0.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.r),
              bottom: Radius.circular(0.r),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attendance Calendar",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Iconsax.refresh, size: 20.w),
                            onPressed: controller.loadEvents,
                            tooltip: "Refresh Calendar",
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Obx(
                      () =>
                          controller.isLoading.value
                              ? _buildCalendarShimmer()
                              : CustomCalendar(
                                events: controller.events,
                                selectedDay: controller.selectedDay.value,
                                focusedMonth: controller.focusedMonth.value,
                                onDaySelected: (date) {
                                  controller.onDaySelected(date, date);
                                },
                                onPreviousMonth: controller.previousMonth,
                                onNextMonth: controller.nextMonth,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Get.to(() => HolidaysListScreen());

            /// TODO Add All Hoildays
          },
          child: Container(
            alignment: Alignment.center,
            height: 60,
            margin: EdgeInsets.only(top: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                // colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              "Hoilday's List",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundLight,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () {
            Get.to(() => LeavesListScreen());
          },
          child: Container(
            alignment: Alignment.center,
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 205, 209, 90),
                  Color.fromARGB(255, 157, 202, 11),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              "My Leaves",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 400.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  Widget _buildSelectedEvents() {
    return Obx(() {
      if (controller.selectedEvents.isEmpty) {
        return SizedBox.shrink();
      }

      return Column(
        children: [
          SizedBox(height: 20.h),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'EEEE, MMMM d, yyyy',
                    ).format(controller.selectedDay.value),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...controller.selectedEvents.map((event) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildEventCard(event),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLegend() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Legend",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 8.h,
              children: [
                _buildLegendItem(
                  Iconsax.tick_circle,
                  AppColors.success,
                  "Present",
                ),
                _buildLegendItem(Iconsax.close_circle, Colors.red, "Absent"),
                _buildLegendItem(Iconsax.calendar, Colors.blueGrey, "Weekend"),
                _buildLegendItem(Iconsax.cake, Colors.purple, "Holiday"),
                _buildLegendItem(Iconsax.bezier, AppColors.warning, "Leave"),
                // ✅ New Legend Items
                // _buildLegendItem(
                //   Iconsax.warning_2,
                //   Colors.orange,
                //   "Late Arrival",
                // ),
                // _buildLegendItem(Iconsax.timer, Colors.blue, "Half Day"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.w, color: color),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(AttendanceEvent event) {
    if (event.type == 'leave') {
      Color statusColor;
      IconData statusIcon;

      switch (event.status?.toLowerCase()) {
        case 'approved':
          statusColor = Color(0xFF10B981);
          statusIcon = Iconsax.tick_circle;
          break;
        case 'rejected':
          statusColor = Color(0xFFEF4444);
          statusIcon = Iconsax.close_circle;
          break;
        default:
          statusColor = Color(0xFFF59E0B);
          statusIcon = Iconsax.clock;
      }

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.bezier, color: statusColor, size: 18.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "${event.leaveType} Leave",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14.w, color: statusColor),
                      SizedBox(width: 4.w),
                      Text(
                        event.status ?? 'Pending',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (event.remark?.isNotEmpty ?? false)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Iconsax.note_1,
                      size: 16.w,
                      color: AppColors.textColorSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        event.remark!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textColorSecondary,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            // Withdraw Button for Pending Leaves
            if (event.status?.toLowerCase() == 'pending')
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _showWithdrawConfirmationDialog(event),
                      icon: Icon(
                        Iconsax.close_circle,
                        size: 16.w,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Withdraw Request",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Attendance event
      Color statusColor;
      IconData statusIcon;
      String statusText;

      if (event.status == 'Present') {
        statusColor = Color(0xFF10B981);
        statusIcon = Iconsax.tick_circle;
        statusText = "Present";
      } else if (event.status == 'Absent') {
        statusColor = Color(0xFFEF4444);
        statusIcon = Iconsax.close_circle;
        statusText = "Absent";
      } else if (event.status == 'Weekend') {
        statusColor = AppColors.textColorSecondary;
        statusIcon = Iconsax.calendar;
        statusText = "Weekend";
      } else if (event.status == 'Holiday') {
        statusColor = Color(0xFF8B5CF6);
        statusIcon = Iconsax.cake;
        statusText = "Holiday";
      } else {
        statusColor = AppColors.textColorSecondary;
        statusIcon = Iconsax.clock;
        statusText = "Not Recorded";
      }

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.calendar, color: statusColor, size: 18.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    "Attendance",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14.w, color: statusColor),
                      SizedBox(width: 4.w),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (event.punchIn != null || event.punchOut != null)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    if (event.punchIn != null)
                      Row(
                        children: [
                          Icon(
                            Iconsax.login_1,
                            size: 16.w,
                            color: AppColors.textColorSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Punch In: ${event.punchIn}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    if (event.punchOut != null) SizedBox(height: 8.h),
                    if (event.punchOut != null)
                      Row(
                        children: [
                          Icon(
                            Iconsax.logout,
                            size: 16.w,
                            color: AppColors.textColorSecondary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "Punch Out: ${event.punchOut}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
  }

  void _showWithdrawConfirmationDialog(AttendanceEvent event) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Container(
          width: Get.width * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.white, size: 28.w),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Confirm Withdrawal",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: Color(0xFFFFA726),
                      size: 48.w,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Are you sure?",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "You're about to withdraw your ${event.leaveType?.toLowerCase() ?? 'leave'} request. This action cannot be undone.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textColorSecondary,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (event.remark?.isNotEmpty ?? false)
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.orange[100]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Iconsax.note_1,
                              size: 16.w,
                              color: Colors.orange[700],
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                "Reason: ${event.remark!}",
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Buttons
              Padding(
                padding: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textColorPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back(); // Close dialog

                            if (event.leaveId == null) {
                              _showErrorSnackbar(
                                "Error",
                                "Leave ID not available. Cannot withdraw.",
                              );
                              return;
                            }

                            controller.cancelLeave(event.leaveId!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD32F2F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.close_circle,
                                size: 20.w,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Withdraw",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    BaseApiService().showSnackbar(title, message);
  }
}
