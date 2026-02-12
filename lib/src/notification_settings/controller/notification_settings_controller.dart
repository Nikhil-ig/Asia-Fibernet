import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/apis/base_api_service.dart';
import '../../services/sharedpref.dart';

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

  // Language and Notification Status
  final userPrefLanguage = 'en'.obs; // 'en' or 'ka'
  final notificationStatus = true.obs; // true (on) or false (off)
  final isLoading = false.obs;

  final _firebaseMessaging = FirebaseMessaging.instance;
  final pushNotifications = true.obs;

  // final String _baseUrl = 'https://asiafibernet.in';
  final String? _token = AppSharedPref.instance.getToken();

  @override
  void onInit() {
    super.onInit();
    _loadUserPreferences();
    if (pushNotifications.value) {
      subscribeToPushNotifications();
    }
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    try {
      final savedLanguage = AppSharedPref.instance.getLanguage();
      if (savedLanguage.isNotEmpty) {
        userPrefLanguage.value = savedLanguage;
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user preferences: $e');
    }
  }

  /// Update user language preference and notification status
  Future<void> updateUserPreference({
    required String language,
    required bool notifStatus,
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse(
        '${BaseApiService.api}update_user_pref_language.php',
      );

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'user_pref_language': language,
          'notification_status': notifStatus ? 1 : 0,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print(jsonResponse);

        if (jsonResponse['status'] == 'success' || response.statusCode == 200) {
          userPrefLanguage.value = language;
          notificationStatus.value = notifStatus;

          // Save to local storage
          await AppSharedPref.instance.setLanguage(language);

          BaseApiService().showSnackbar(
            'Success',
            'Preferences updated successfully!',
          );

          if (kDebugMode) {
            print(
              'User preference updated: Language=$language, Notifications=$notifStatus',
            );
          }
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to update preferences',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        'Error',
        'Failed to update preferences: ${e.toString()}',
      );
      if (kDebugMode) print('Error updating user preference: $e');
    } finally {
      isLoading.value = false;
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
  }

  /// Subscribes the device to the 'all' topic.
  Future<void> subscribeToPushNotifications() async {
    try {
      await _firebaseMessaging.subscribeToTopic('all');
      if (kDebugMode) print("Subscribed to 'all' topic");
    } catch (e) {
      if (kDebugMode) print("Error subscribing to topic: $e");
    }
  }

  /// Unsubscribes the device from the 'all' topic.
  Future<void> unsubscribeFromPushNotifications() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all');
      if (kDebugMode) print("Unsubscribed from 'all' topic");
    } catch (e) {
      if (kDebugMode) print("Error unsubscribing from topic: $e");
    }
  }

  void savePreferences() {
    BaseApiService().showSnackbar("Success", "Preferences saved successfully!");
  }
}
