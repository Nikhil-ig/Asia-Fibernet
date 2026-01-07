import 'package:get/get.dart';
import '../../services/apis/notification_api.dart';

class NotificationController extends GetxController {
  final NotificationAPI _api = NotificationAPI();

  // Reactive variables
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchUnreadCount();
    // Optional: refresh periodically
    ever(notifications, (_) => updateUnreadCount());
  }

  /// Fetch all notifications
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final result = await _api.fetchNotifications();
      notifications.value = result;
      updateUnreadCount();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      print('Error in fetchNotifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch unread count
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _api.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      print('Error fetching unread count: $e');
    }
  }

  /// Update unread count based on notifications list
  void updateUnreadCount() {
    unreadCount.value = notifications.where((n) => n.status == 'unread').length;
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _api.markAsRead(notificationId);
      if (success) {
        // Update local notification
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = notifications[index];
          notifications[index] = NotificationModel(
            id: notification.id,
            title: notification.title,
            body: notification.body,
            image: notification.image,
            action: notification.action,
            actionUrl: notification.actionUrl,
            type: notification.type,
            status: 'read',
            createdAt: notification.createdAt,
          );
          notifications.refresh();
          updateUnreadCount();
        }
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _api.markAllAsRead();
      if (success) {
        // Update all notifications to read
        notifications.value =
            notifications.map((n) {
              return NotificationModel(
                id: n.id,
                title: n.title,
                body: n.body,
                image: n.image,
                action: n.action,
                actionUrl: n.actionUrl,
                type: n.type,
                status: 'read',
                createdAt: n.createdAt,
              );
            }).toList();
        updateUnreadCount();
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final success = await _api.deleteNotification(notificationId);
      if (success) {
        notifications.removeWhere((n) => n.id == notificationId);
        updateUnreadCount();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Retry loading notifications
  void retry() {
    fetchNotifications();
  }
}
