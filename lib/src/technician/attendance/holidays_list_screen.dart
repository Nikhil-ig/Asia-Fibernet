// lib/screens/attendance/holidays_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/apis/attendance_leave_api.dart';
import '../../theme/colors.dart';
import '../core/models/attendance_and_leave_model.dart';
import 'package:intl/intl.dart';

class HolidaysListScreen extends StatelessWidget {
  HolidaysListScreen({super.key});

  final AttendanceLeaveAPI _api = AttendanceLeaveAPI();
  final RxList<HolidayModel> holidays = <HolidayModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  Widget build(BuildContext context) {
    // Fetch holidays on first build
    ever(holidays, (_) => isLoading.value = false);
    if (holidays.isEmpty) {
      _fetchHolidays();
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: Text(
          "Holiday Calendar",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHolidays,
        child: Obx(
          () =>
              isLoading.value
                  ? _buildLoadingShimmer()
                  : error.isNotEmpty
                  ? _buildErrorState()
                  : holidays.isEmpty
                  ? _buildEmptyState()
                  : _buildHolidayList(),
        ),
      ),
    );
  }

  Future<void> _fetchHolidays() async {
    error.value = '';
    isLoading.value = true;
    try {
      // Note: Your API doesn't accept month param for holidays (based on logs)
      // So we fetch all and let backend handle it
      final result = await _api.fetchHolidaysByMonth('');
      if (result != null) {
        // Sort by date (ascending)
        result.sort((a, b) {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        holidays.assignAll(result);
      } else {
        error.value = "No holiday data received.";
      }
    } catch (e) {
      error.value = "Failed to load holidays.";
      debugPrint("Holiday fetch error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 6,
      itemBuilder:
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              height: 90.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.info_circle, size: 48.w, color: Colors.red),
          SizedBox(height: 16.h),
          Text(
            "Oops! Something went wrong",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _fetchHolidays,
            icon: Icon(Icons.refresh, size: 18.w),
            label: Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.cake, size: 48.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            "No Holidays Found",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "There are no upcoming holidays in the system.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayList() {
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: holidays.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        final holidayDate = DateTime.tryParse(holiday.date);
        final formattedDate =
            holidayDate != null
                ? "${_getDayName(holidayDate)} • ${_formatDate(holidayDate)}"
                : holiday.date;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.cake, color: Color(0xFF8B5CF6), size: 24.w),
            ),
            title: Text(
              holiday.title.trim(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textColorPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textColorSecondary,
                  ),
                ),
                if (holiday.description?.isNotEmpty == true) ...[
                  SizedBox(height: 6.h),
                  Text(
                    holiday.description!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textColorHint,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                holidayDate != null ? _getMonthAbbrev(holidayDate) : "??",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _getMonthAbbrev(DateTime date) {
    return DateFormat('MMM').format(date).toUpperCase();
  }
}
