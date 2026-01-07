import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import '../../services/apis/base_api_service.dart';

class NotificationSettingsController extends GetxController {
  // Notification Channels
  final emailNotifications = true.obs;
  final smsNotifications = false.obs;
  // Notification Preferences
  final billingPayments = true.obs;
  final serviceOutages = false.obs;
  final complaintUpdates = true.obs;
  final planExpiry = true.obs;
  final offersAndPromotions = false.obs;

  // --- NEW CODE ---
  final _firebaseMessaging = FirebaseMessaging.instance;
  final pushNotifications = true.obs;

  @override
  void onInit() {
    super.onInit();
    // When the controller is initialized, ensure the push notification
    // state is in sync with the initial value.
    if (pushNotifications.value) {
      subscribeToPushNotifications();
    }
  }

  /// Toggles the push notification setting and subscribes/unsubscribes the user.
  void togglePushNotifications(bool value) {
    pushNotifications.value = value;
    if (value) {
      subscribeToPushNotifications();
      BaseApiService().showSnackbar(
        "Notifications Enabled",
        "You will now receive push notifications.",
      );
    } else {
      unsubscribeFromPushNotifications();
      BaseApiService().showSnackbar(
        "Notifications Disabled",
        "You will no longer receive push notifications.",
      );
    }
    // You could also save this preference to SharedPreferences here
  }

  /// Subscribes the device to the 'all' topic.
  Future<void> subscribeToPushNotifications() async {
    try {
      // You can subscribe to any topic you want. 'all' is a common default.
      await _firebaseMessaging.subscribeToTopic('all');
      print("Subscribed to 'all' topic");
    } catch (e) {
      print("Error subscribing to topic: $e");
    }
  }

  /// Unsubscribes the device from the 'all' topic.
  Future<void> unsubscribeFromPushNotifications() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all');
      print("Unsubscribed from 'all' topic");
    } catch (e) {
      print("Error unsubscribing from topic: $e");
    }
  }
  // --- END OF NEW CODE ---

  void savePreferences() {
    // This function can remain as is for saving other preferences.
    BaseApiService().showSnackbar("Success", "Preferences saved successfully!");
  }
}
