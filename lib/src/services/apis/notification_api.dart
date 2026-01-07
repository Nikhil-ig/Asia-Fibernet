import 'dart:convert';
import 'package:get/get.dart';
import 'base_api_service.dart';

/// Model for Notification
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? image;
  final String? action;
  final String? actionUrl;
  final String type; // 'info', 'warning', 'error', 'success'
  final String status; // 'read', 'unread'
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.image,
    this.action,
    this.actionUrl,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      image: json['image'],
      action: json['action'],
      actionUrl: json['action_url'],
      type: json['type'] ?? 'info',
      status: json['status'] ?? 'unread',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'image': image,
    'action': action,
    'action_url': actionUrl,
    'type': type,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Notification API Service
class NotificationAPI {
  final BaseApiService _baseApiService = Get.find<BaseApiService>();

  // API Endpoints
  static const String _fetchNotifications = 'techAPI/get_notifications.php';
  static const String _markAsRead = 'techAPI/mark_notification_read.php';
  static const String _deleteNotification = 'techAPI/delete_notification.php';
  static const String _getUnreadCount = 'techAPI/get_unread_count.php';

  /// Fetch all notifications for the logged-in technician
  Future<List<NotificationModel>> fetchNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _baseApiService.get(
        _fetchNotifications,
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is Map && jsonData['success'] == true) {
          final notificationsList = jsonData['data'] as List?;
          if (notificationsList != null) {
            return notificationsList
                .map((item) => NotificationModel.fromJson(item))
                .toList();
          }
        } else if (jsonData is List) {
          // Direct array response
          return jsonData
              .map((item) => NotificationModel.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      _baseApiService.showSnackbar(
        '❌ Error',
        'Failed to load notifications',
        isError: true,
      );
      return [];
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _baseApiService.post(
        _markAsRead,
        body: {'notification_id': notificationId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _baseApiService.post(
        _markAsRead,
        body: {'mark_all': true},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await _baseApiService.post(
        _deleteNotification,
        body: {'notification_id': notificationId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      print('Error deleting notification: $e');
      _baseApiService.showSnackbar(
        '❌ Error',
        'Failed to delete notification',
        isError: true,
      );
      return false;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _baseApiService.get(_getUnreadCount);

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data is Map && data['success'] == true) {
          return data['unread_count'] ?? 0;
        }
      }

      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }
}
