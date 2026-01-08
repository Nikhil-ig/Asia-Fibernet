import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

import 'routes.dart';

/// A utility class for managing app-level persistent data using [SharedPreferences].
///
/// This class provides a centralized, singleton-based interface for storing and retrieving
/// sensitive and non-sensitive user data such as authentication tokens, user IDs,
/// mobile numbers, and feature flags like location tracking status.
///
/// It must be initialized before use via [init()] typically during app startup.
///
/// Example:
/// ```dart
/// await AppSharedPref.init();
/// await AppSharedPref.setToken("your_jwt_token");
/// String? token = await AppSharedPref.getToken();
/// ```
class AppSharedPref {
  // 🔑 Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _otp = 'auth_otp';
  static const String _roleKey = 'user_role';
  static const String _userIDKey = 'user_id';
  static const String _mobileNumberKey = 'mobile_number';
  static const String _trackingStatusKey = 'is_tracking_enabled';
  static const String _isVerifyCustomer = 'is_verify_customer';
  static const String _fcmToken = '_fcmToken';

  // 🧩 Singleton instance
  static AppSharedPref? _instance;
  static SharedPreferences? _prefs;

  // 🛠 Prevent external instantiation
  AppSharedPref._();

  /// Returns the singleton instance of [AppSharedPref].
  ///
  /// Throws an error if [init] has not been called first.
  static AppSharedPref get instance {
    if (_instance == null) {
      throw StateError(
        "AppSharedPref is not initialized. Call AppSharedPref.init() first.",
      );
    }
    return _instance!;
  }

  /// Initializes the [AppSharedPref] class.
  ///
  /// This method must be called once before any other method is used.
  /// Typically called during app startup (e.g., in `main()` or app initialization routine).
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AppSharedPref.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    if (_instance != null) {
      developer.log(
        "AppSharedPref already initialized. Skipping re-initialization.",
      );
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _instance = AppSharedPref._();
      developer.log("AppSharedPref initialized successfully.");
    } on Exception catch (e) {
      developer.log("Failed to initialize AppSharedPref: $e");
      throw Exception("Unable to initialize shared preferences: $e");
    }
  }

  /// Checks if the user is logged in by verifying the presence of both token and user ID.
  ///
  /// Returns `true` if both authentication token and user ID exist.
  /// This is a safe way to check login state during app startup or route guarding.
  ///
  /// Example:
  /// ```dart
  /// if (await AppSharedPref.instance.isUserLoggedIn()) {
  ///   // Go to home screen
  /// } else {
  ///   // Redirect to login
  /// }
  /// ```
  /// ✅ Synchronous check for login state (safe to use in middleware)
  bool isUserLoggedIn() {
    _validatePrefs();
    final String? token = _prefs!.getString(_tokenKey);
    final int? userId = _prefs!.getInt(_userIDKey);
    final bool isLoggedIn = token != null && userId != null; // && userId > 0;

    developer.log(
      "Login status check: token=${token != null}, userId=$userId → isLoggedIn=$isLoggedIn",
      name: "AppSharedPref.isUserLoggedIn",
    );

    return isLoggedIn;
  }

  /// Saves the authentication token.
  ///
  /// Returns `true` if the operation succeeded.
  Future<bool> setToken(String token) {
    _validatePrefs();
    if (token.isEmpty) {
      developer.log(
        "Attempted to save empty token.",
        name: "AppSharedPref.setToken",
      );
      return Future.value(false);
    }
    developer.log("Token saved.", name: "AppSharedPref.setToken");
    return _prefs!.setString(_tokenKey, token);
  }

  /// Retrieves the stored authentication token.
  ///
  /// Returns `null` if no token is found or if it has expired.
  String getToken() {
    _validatePrefs();
    final String? token = _prefs!.getString(_tokenKey);
    if (token == null) {
      developer.log("No token found.", name: "AppSharedPref.getToken");
    }
    return token ?? '';
  }

  /// Removes the authentication token from storage.
  ///
  /// Useful during logout.
  Future<bool> removeToken() {
    _validatePrefs();
    developer.log("Token removed.", name: "AppSharedPref.removeToken");
    return _prefs!.remove(_tokenKey);
  }

  Future<bool> setOTP(String token) {
    _validatePrefs();
    if (token.isEmpty) {
      developer.log(
        "Attempted to save empty token.",
        name: "AppSharedPref.setToken",
      );
      return Future.value(false);
    }
    developer.log("Token saved.", name: "AppSharedPref.setToken");
    return _prefs!.setString(_otp, token);
  }

  /// Retrieves the stored authentication token.
  ///
  /// Returns `null` if no token is found or if it has expired.
  Future<String?> getOTP() {
    _validatePrefs();
    final String? token = _prefs!.getString(_otp);
    if (token == null) {
      developer.log("No token found.", name: "AppSharedPref.getToken");
    }
    return Future.value(token);
  }

  /// Removes the authentication token from storage.
  ///
  /// Useful during logout.
  Future<bool> removeOTP() {
    _validatePrefs();
    developer.log("Token removed.", name: "AppSharedPref.removeToken");
    return _prefs!.remove(_otp);
  }

  /// Saves the authentication token.
  ///
  /// Returns `true` if the operation succeeded.
  Future<bool> setfcmToken(String token) {
    _validatePrefs();
    if (token.isEmpty) {
      developer.log(
        "Attempted to save empty token.",
        name: "AppSharedPref.setFCMToken",
      );
      return Future.value(false);
    }
    developer.log("FCM Token saved.", name: "AppSharedPref.setFCMToken");
    return _prefs!.setString(_tokenKey, token);
  }

  /// Retrieves the stored authentication token.
  ///
  /// Returns `null` if no token is found or if it has expired.
  Future<String?> getFCMToken() {
    _validatePrefs();
    final String? token = _prefs!.getString(_fcmToken);
    if (token == null) {
      developer.log("No FCM token found.", name: "AppSharedPref.getFCMToken");
    }
    return Future.value(token);
  }

  /// Removes the authentication token from storage.
  ///
  /// Useful during logout.
  Future<bool> removeFCMToken() {
    _validatePrefs();
    developer.log("FCM Token removed.", name: "AppSharedPref.removeFCMToken");
    return _prefs!.remove(_fcmToken);
  }

  /// Saves the Role.
  ///
  /// Returns `true` if the operation succeeded.
  Future<bool> setRole(String role) {
    _validatePrefs();
    if (role.isEmpty) {
      developer.log(
        "Attempted to save empty Role.",
        name: "AppSharedPref.setRole",
      );
      return Future.value(false);
    }
    developer.log("Role saved.", name: "AppSharedPref.setRole");
    return _prefs!.setString(_roleKey, role);
  }

  /// Retrieves the stored Role.
  ///
  /// Returns `null` if no Role is found.
  String? getRole() {
    _validatePrefs();
    final String? role = _prefs!.getString(_roleKey);
    if (role == null) {
      developer.log("No role found.", name: "AppSharedPref.getRole");
    }
    return role;
  }

  /// Removes the role from storage.
  ///
  /// Useful during logout.
  Future<bool> removeRole() {
    _validatePrefs();
    developer.log("Role removed.", name: "AppSharedPref.removeRole");
    return _prefs!.remove(_roleKey);
  }

  /// Saves the user ID.
  ///
  /// Returns `true` on success.
  Future<bool> setUserID(int userID) {
    _validatePrefs();
    if (userID <= 0) {
      developer.log(
        "Invalid userID attempted to save: $userID",
        name: "AppSharedPref.setUserID",
      );
      return Future.value(false);
    }
    developer.log("User ID saved: $userID", name: "AppSharedPref.setUserID");
    return _prefs!.setInt(_userIDKey, userID);
  }

  /// Retrieves the stored user ID.
  ///
  /// Returns `null` if no user ID is found.
  int? getUserID() {
    _validatePrefs();
    final int? id = _prefs!.getInt(_userIDKey);
    if (id == null) {
      developer.log("No user ID found.", name: "AppSharedPref.getUserID");
    }
    return id;
  }

  /// Removes the stored user ID.
  Future<bool> removeUserID() {
    _validatePrefs();
    developer.log("User ID removed.", name: "AppSharedPref.removeUserID");
    return _prefs!.remove(_userIDKey);
  }

  /// Saves the user's mobile number.
  ///
  /// Returns `true` on success.
  Future<bool> setMobileNumber(String mobileNumber) {
    _validatePrefs();
    // final RegExp phoneRegex = RegExp(r'^[6-9]\d{9}$'); // Indian mobile format
    // if (!phoneRegex.hasMatch(mobileNumber)) {
    //   developer.log(
    //     "Invalid mobile number format: $mobileNumber",
    //     name: "AppSharedPref.setMobileNumber",
    //   );
    //   return Future.value(false);
    // }
    developer.log(
      "Mobile number saved.",
      name: "AppSharedPref.setMobileNumber",
    );
    return _prefs!.setString(_mobileNumberKey, mobileNumber);
  }

  /// Retrieves the stored mobile number.
  ///
  /// Returns `null` if not found.
  String? getMobileNumber() {
    _validatePrefs();
    final String? number = _prefs!.getString(_mobileNumberKey);
    if (number == null) {
      developer.log(
        "No mobile number found.",
        name: "AppSharedPref.getMobileNumber",
      );
    }
    return number;
  }

  /// Removes the stored mobile number.
  Future<bool> removeMobileNumber() {
    _validatePrefs();
    developer.log(
      "Mobile number removed.",
      name: "AppSharedPref.removeMobileNumber",
    );
    return _prefs!.remove(_mobileNumberKey);
  }

  /// Sets the verification status feature.
  ///
  /// Used to remember whether the Customer has verification (uploaded has Identity).
  Future<bool> setVerificationStatus(bool isVerifyCustomer) async {
    _validatePrefs();
    developer.log(
      "Customer's verification status set to: $isVerifyCustomer",
      name: "AppSharedPref.setVerificationStatus",
    );
    return await _prefs!.setBool(_isVerifyCustomer, isVerifyCustomer);
  }

  /// Gets the current verification status.
  ///
  /// Returns `false` by default if no value was previously set.
  bool getVerificationStatus() {
    _validatePrefs();
    final bool status = _prefs!.getBool(_isVerifyCustomer) ?? false;
    developer.log(
      "Current Customer Verification status: $status",
      name: "AppSharedPref.getVerificationStatus",
    );
    return status;
  }

  /// Sets the tracking status for location tracking feature.
  ///
  /// Used to remember whether the technician has enabled background location tracking.
  Future<bool> setTrackingStatus(bool isTracking) async {
    _validatePrefs();
    developer.log(
      "Tracking status set to: $isTracking",
      name: "AppSharedPref.setTrackingStatus",
    );
    return await _prefs!.setBool(_trackingStatusKey, isTracking);
  }

  /// Gets the current tracking status.
  ///
  /// Returns `false` by default if no value was previously set.
  Future<bool> getTrackingStatus() async {
    _validatePrefs();
    final bool status = _prefs!.getBool(_trackingStatusKey) ?? false;
    developer.log(
      "Current tracking status: $status",
      name: "AppSharedPref.getTrackingStatus",
    );
    return status;
  }

  /// Clears all stored data (e.g., during logout).
  ///
  /// Use with caution — removes all keys set by this class.
  Future<bool> clearAllUserData() async {
    _validatePrefs();

    developer.log(
      "Clearing all user data...",
      name: "AppSharedPref.clearAllUserData",
    );
    try {
      // Optionally, preserve some app settings here if needed
      await _prefs!.remove(_tokenKey);
      await _prefs!.remove(_userIDKey);
      await _prefs!.remove(_mobileNumberKey);
      await _prefs!.remove(_trackingStatusKey);
      await _prefs!.remove(_isVerifyCustomer);
      developer.log(
        "User data cleared successfully.",
        name: "AppSharedPref.clearAllUserData",
      );
      Get.offAllNamed(AppRoutes.login);
      return true;
    } catch (e) {
      developer.log(
        "Error clearing user data: $e",
        name: "AppSharedPref.clearAllUserData",
      );
      return false;
    }
  }

  /// Ensures that [_prefs] is available before any operation.
  ///
  /// Throws an error if [init] was not called.
  void _validatePrefs() {
    if (_prefs == null) {
      throw Exception(
        "AppSharedPref not initialized. Call AppSharedPref.init() before using it.",
      );
    }
  }
}
