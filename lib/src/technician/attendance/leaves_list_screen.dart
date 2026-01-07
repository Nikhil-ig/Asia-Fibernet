import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/models/attendance_and_leave_model.dart';
import 'attendance_screen.dart';

class LeavesListScreen extends StatelessWidget {
  LeavesListScreen({super.key});

  final AttendanceController _controller = Get.find<AttendanceController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "All Leave Requests",
                style: AppText.headingSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left_2, size: 24.w, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Iconsax.refresh, size: 22.w, color: Colors.white),
                onPressed: () => Get.forceAppUpdate(),
                tooltip: "Refresh",
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: FutureBuilder<List<LeaveModel>>(
              future: _controller.fetchAllLeaves(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildLeaveShimmer(),
                      childCount: 5,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.warning_2,
                            size: 48.w,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "Failed to load leaves",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          ElevatedButton.icon(
                            onPressed: () => Get.forceAppUpdate(),
                            icon: Icon(Iconsax.refresh, size: 18.w),
                            label: Text("Retry"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final leaves = snapshot.data ?? [];

                if (leaves.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.note_remove,
                            size: 64.w,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "No Leave Requests",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "You haven't applied for any leaves yet",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _controller.showLeaveRequestDialog();
                            },
                            icon: Icon(Iconsax.calendar_add, size: 18.w),
                            label: Text("Apply for Leave"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6366F1),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group leaves by year and month
                final groupedLeaves = _groupLeavesByMonth(leaves);

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final monthKey = groupedLeaves.keys.elementAt(index);
                    final monthLeaves = groupedLeaves[monthKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Header
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Iconsax.calendar,
                                  size: 20.w,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                monthKey,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),
                              Spacer(),
                              Chip(
                                label: Text(
                                  "${monthLeaves.length} leave${monthLeaves.length > 1 ? 's' : ''}",
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                                backgroundColor: Color(
                                  0xFF6366F1,
                                ).withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),

                        // Leaves for this month
                        ...monthLeaves.map((leave) => _buildLeaveCard(leave)),
                        SizedBox(height: 24.h),
                      ],
                    );
                  }, childCount: groupedLeaves.length),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<LeaveModel>> _groupLeavesByMonth(List<LeaveModel> leaves) {
    final Map<String, List<LeaveModel>> grouped = {};

    for (final leave in leaves) {
      final startDate = DateTime.parse(leave.startDate);
      final monthKey = "${_getMonthName(startDate.month)} ${startDate.year}";

      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(leave);
    }

    // Sort months in reverse chronological order
    final sortedKeys =
        grouped.keys.toList()
          ..sort((a, b) => _parseMonthKey(b).compareTo(_parseMonthKey(a)));

    final sortedMap = <String, List<LeaveModel>>{};
    for (final key in sortedKeys) {
      // Sort leaves within each month by start date (newest first)
      grouped[key]!.sort(
        (a, b) =>
            DateTime.parse(b.startDate).compareTo(DateTime.parse(a.startDate)),
      );
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _getMonthName(int month) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }

  DateTime _parseMonthKey(String key) {
    final parts = key.split(' ');
    final monthName = parts[0];
    final year = int.parse(parts[1]);

    final monthIndex =
        [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ].indexOf(monthName) +
        1;

    return DateTime(year, monthIndex);
  }

  Widget _buildLeaveCard(LeaveModel leave) {
    final startDate = DateTime.parse(leave.startDate);
    final endDate = DateTime.parse(leave.endDate);
    final isSingleDay = startDate.difference(endDate).inDays == 0;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        statusColor = Color(0xFF10B981);
        statusIcon = Iconsax.tick_circle;
        statusText = "Approved";
        break;
      case 'rejected':
        statusColor = Color(0xFFEF4444);
        statusIcon = Iconsax.close_circle;
        statusText = "Rejected";
        break;
      default:
        statusColor = Color(0xFFF59E0B);
        statusIcon = Iconsax.clock;
        statusText = "Pending";
    }

    final leaveTypeColors = {
      'sick': Color(0xFFEF4444),
      'casual': Color(0xFF3B82F6),
      'paid': Color(0xFF10B981),
      'unpaid': Color(0xFF8B5CF6),
    };

    final leaveTypeIcon = {
      'sick': Iconsax.health,
      'casual': Iconsax.calendar_1,
      'paid': Iconsax.money,
      'unpaid': Iconsax.calendar_remove,
    };

    final typeColor =
        leaveTypeColors[leave.leaveType.toLowerCase()] ?? Color(0xFF6366F1);
    final typeIcon =
        leaveTypeIcon[leave.leaveType.toLowerCase()] ?? Iconsax.calendar;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, size: 20.w, color: typeColor),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${leave.leaveType[0].toUpperCase()}${leave.leaveType.substring(1)} Leave",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isSingleDay
                                ? DateFormat('MMM dd, yyyy').format(startDate)
                                : '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14.w, color: statusColor),
                          SizedBox(width: 6.w),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Details section
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_2,
                          size: 16.w,
                          color: AppColors.textColorSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Duration:",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isSingleDay
                              ? "1 day"
                              : "${endDate.difference(startDate).inDays + 1} days",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textColorPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Applied on
                    Row(
                      children: [
                        Icon(
                          Iconsax.calendar_tick,
                          size: 16.w,
                          color: AppColors.textColorSecondary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Applied on:",
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(DateTime.parse(leave.requestedAt)),
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Reason
                    if (leave.reason.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Iconsax.note_1,
                                size: 16.w,
                                color: AppColors.textColorSecondary,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Reason:",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textColorSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      leave.reason,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.textColorPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),

                    // Withdraw button for pending leaves
                    if (leave.status.toLowerCase() == 'pending')
                      Align(
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
                            onPressed: () => _showWithdrawDialog(leave),
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
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
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
    );
  }

  void _showWithdrawDialog(LeaveModel leave) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.red),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Withdraw Leave Request",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to withdraw this leave request?",
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textColorSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Leave Details:",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${leave.leaveType} Leave (${DateFormat('MMM dd').format(DateTime.parse(leave.startDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(leave.endDate))})",
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  if (leave.reason.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      "Reason: ${leave.reason}",
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppColors.textColorSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(Get.context!);
              await _controller.cancelLeave(leave.id);
              Get.forceAppUpdate(); // Refresh the list
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Withdraw"),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveShimmer() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Card(
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120.w,
                          height: 16.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 80.w,
                          height: 14.h,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                height: 14.h,
                color: Colors.grey[300],
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                height: 14.h,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
