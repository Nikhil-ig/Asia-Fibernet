import 'package:asia_fibernet/src/services/apis/technician_api_service.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../services/apis/api_services.dart';

// Model class
class NotificationResponse {
  final String status;
  final List<NotificationData> data;

  NotificationResponse({required this.status, required this.data});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    List<NotificationData> notificationList = [];
    if (json['data'] is List) {
      notificationList =
          (json['data'] as List)
              .map((d) => NotificationData.fromJson(d as Map<String, dynamic>))
              .toList();
    }

    return NotificationResponse(
      status: json['status'] as String? ?? '',
      data: notificationList,
    );
  }
}

class NotificationData {
  final int id;
  final String message;
  final int isRead;
  final String createdAt;
  final String title;
  final int customerId;

  NotificationData({
    required this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.title,
    required this.customerId,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      title: json['title'] as String? ?? '',
      customerId: json['customer_id'] as int? ?? 0,
    );
  }

  // Helper method to format date
  String get formattedDate {
    try {
      final DateTime date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return createdAt;
    }
  }

  // Helper method to get icon based on title
  IconData get icon {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('ticket')) {
      return Icons.confirmation_number;
    } else if (titleLower.contains('plan')) {
      return Icons.speed;
    } else if (titleLower.contains('close')) {
      return Icons.check_circle;
    } else if (titleLower.contains('call') || titleLower.contains('drop')) {
      return Icons.call;
    } else {
      return Icons.notifications;
    }
  }

  // Helper method to get color based on title
  Color get color {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('ticket')) {
      return Colors.blue;
    } else if (titleLower.contains('plan')) {
      return Colors.green;
    } else if (titleLower.contains('close')) {
      return Colors.purple;
    } else if (titleLower.contains('call') || titleLower.contains('drop')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
}

// Notification Screen
class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationData> notifications = [];
  bool isLoading = true;
  String errorMessage = '';
  List<NotificationData>? response = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final fetched = await TechnicianAPI().getNotifications();

      setState(() {
        notifications = fetched ?? []; // if null, use empty list
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load notifications.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.backgroundLight),
        // actions: [
        //   if (notifications.isNotEmpty)
        //     Padding(
        //       padding: EdgeInsets.all(16.w),
        //       child: Text(
        //         '${notifications.length}',
        //         style: TextStyle(
        //           fontSize: 16.sp,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.white,
        //         ),
        //       ),
        //     ),
        // ],
      ),
      body:
          isLoading
              ? _buildLoadingIndicator()
              : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading notifications...',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: fetchNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2196F3),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You\'ll see all your notifications here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: fetchNotifications,
      child: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: notifications.length + 1,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          final notification = notifications[index - 1];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Notifications',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '${notifications.length} items',
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    final bool isRead = notification.isRead == 1;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border:
            isRead
                ? null
                : Border.all(
                  color: Color(0xFF2196F3).withOpacity(0.3),
                  width: 1.w,
                ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 24.sp,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.formattedDate,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                ),
                if (!isRead)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Handle notification tap
          _showNotificationDetail(notification);
        },
      ),
    );
  }

  void _showNotificationDetail(NotificationData notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 24.sp),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: notification.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              notification.icon,
                              color: notification.color,
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildDetailRow('Date', notification.createdAt),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        'Status',
                        notification.isRead == 1 ? 'Read' : 'Unread',
                      ),
                      SizedBox(height: 12.h),
                      _buildDetailRow(
                        'Notification ID',
                        notification.id.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              // Action button
              Padding(
                padding: EdgeInsets.all(20.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
