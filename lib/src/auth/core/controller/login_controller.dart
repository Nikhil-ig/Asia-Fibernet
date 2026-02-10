// ignore_for_file: avoid_print

import 'package:asia_fibernet/src/services/sharedpref.dart';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../services/apis/base_api_service.dart';
import '../model/verify_mobile_model.dart';
import '../../../services/apis/api_services.dart';
// Import OTP Screen
import '../../ui/otp_screen.dart';
import 'binding/otp_binding.dart';

/// ⚠️ DEBUG MODE CONFIGURATION
/// Set this to true ONLY during development/testing to bypass OTP verification
/// IMPORTANT: Set to false before production release!
const bool kDebugModeBypassOTP = false;

/// Debug phone number to automatically trigger skip OTP
const String kDebugPhoneNumber = '7877851728';

class LoginController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Needed for AnimationController

  // --- Create an instance of ApiServices ---
  // ✅ It's better practice to get the singleton instance registered with GetX
  // Make sure you register ApiServices as a GetX service (e.g., Get.put(ApiServices()) or Get.lazyPut(() => ApiServices()) in main.dart or an initializer)
  // final ApiServices _apiService = ApiServices(); // Old way - creates new instance
  final ApiServices _apiService =
      Get.find<ApiServices>(); // ✅ Get the registered instance
  final BaseApiService _baseApiService = BaseApiService(BaseApiService.api);

  late TextEditingController phoneController;
  // late AnimationController _animationController;
  // late Animation<double> logoAnimation;
  // late Animation<double> textAnimation;
  // late Animation<double> cardAnimation;

  // ✅ Add a loading state observable
  final RxBool isLoading = false.obs;

  // ✅ Error message display in UI
  final RxString loginError = "".obs;

  // ✅ Clipboard monitoring for phone number auto-fill
  String? _lastClipboardContent;
  bool _shouldIgnoreNextPhoneNumber =
      false; // Changed: auto-detect on load counts as first
  Timer? _clipboardCheckTimer;

  @override
  void onInit() {
    super.onInit();
    // ✅ Initialize phoneController here instead of as a field
    phoneController = TextEditingController(
      text: AppSharedPref.instance.getMobileNumber() ?? '',
    );
    // ✅ Start monitoring clipboard for phone numbers
    _startClipboardMonitoring();
    // ✅ Auto-detect phone number from clipboard on screen load
    _autoDetectPhoneOnLoad();
  }

  /// ✅ Auto-detect phone number from clipboard when screen loads
  Future<void> _autoDetectPhoneOnLoad() async {
    try {
      // Wait a bit for the screen to render first
      await Future.delayed(const Duration(milliseconds: 500));

      final ClipboardData? data = await Clipboard.getData('text/plain');
      final clipboardText = data?.text?.trim() ?? '';

      if (clipboardText.isNotEmpty) {
        // Extract only digits from clipboard
        final phoneDigits = clipboardText.replaceAll(RegExp(r'[^0-9]'), '');

        // Check if it's a valid 10-digit phone number
        if (phoneDigits.length == 10 &&
            phoneDigits.startsWith(RegExp(r'[6-9]'))) {
          print('🔍 Auto-detected phone on load: $phoneDigits');

          // Set the phone number using helper method
          _setPhoneNumber(phoneDigits);

          // Show snackbar only if context/overlay is available
          try {
            _baseApiService.showSnackbar(
              "Phone Number Detected",
              "Your phone number has been auto-detected from clipboard.",
            );
          } catch (e) {
            print("Could not show snackbar: $e");
          }
        }
      }
    } catch (e) {
      print("Could not auto-detect phone on load: $e");
    }
  }

  /// ✅ Helper method to safely set phone number in controller
  void _setPhoneNumber(String phoneNumber) {
    try {
      // Clear the controller
      phoneController.clear();

      // Wait a frame to ensure clear is processed
      Future.delayed(const Duration(milliseconds: 10), () {
        // Set the new value
        phoneController.text = phoneNumber;

        // Ensure cursor is at the end
        if (phoneController.text.length == 10) {
          phoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: phoneNumber.length),
          );
        }

        print('✅ Phone set successfully: ${phoneController.text}');
        print('✅ Phone length: ${phoneController.text.length}');
      });
    } catch (e) {
      print('❌ Error setting phone: $e');
    }
  }

  /// ✅ Monitor clipboard every 500ms for phone numbers
  void _startClipboardMonitoring() {
    _clipboardCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      try {
        final ClipboardData? data = await Clipboard.getData('text/plain');
        final clipboardText = data?.text?.trim() ?? '';

        // Check if clipboard content changed
        if (clipboardText != _lastClipboardContent &&
            clipboardText.isNotEmpty) {
          _lastClipboardContent = clipboardText;

          // Extract only digits from clipboard
          final phoneDigits = clipboardText.replaceAll(RegExp(r'[^0-9]'), '');

          // Check if it's a valid 10-digit phone number
          if (phoneDigits.length == 10 &&
              phoneDigits.startsWith(RegExp(r'[6-9]'))) {
            // Auto-detect counts as first, so directly fill on subsequent copies
            if (!_shouldIgnoreNextPhoneNumber) {
              // Auto-fill the phone number using the helper method
              _setPhoneNumber(phoneDigits);

              print('✅ Clipboard changed - Auto-filling: $phoneDigits');

              // Show snackbar only if context/overlay is available
              try {
                _baseApiService.showSnackbar(
                  "Phone Number Auto-Filled",
                  "Your phone number has been updated from clipboard.",
                );
              } catch (e) {
                print("Could not show snackbar: $e");
              }
            } else {
              // Mark that we've seen a copy
              _shouldIgnoreNextPhoneNumber = false;
              print('📋 First copy detected: $phoneDigits');
            }
          }
        }
      } catch (e) {
        // Silently fail if clipboard access fails
        print("Could not access clipboard: $e");
      }
    });
  }

  // ✅ Clear error message when user starts typing
  void clearError() {
    if (loginError.value.isNotEmpty) {
      loginError.value = "";
    }
  }

  // Inside LoginController class

  void login() async {
    if (isLoading.value) {
      print("Login already in progress...");
      return;
    }

    String phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      loginError.value = "Please enter a mobile number";
      _baseApiService.showSnackbar("Error", "Please enter a mobile number.");
      return;
    }

    isLoading.value = true;
    loginError.value = ""; // Clear previous errors

    try {
      print("Attempting to verify mobile: $phoneNumber");

      final verifyResponse = await _apiService.mobileVerification(phoneNumber);
      final otpResponse = await _apiService.generateOTP(phoneNumber);

      // ✅ Check if EITHER verify or OTP response is null
      if (verifyResponse == null && otpResponse == null) {
        loginError.value = "Could not connect. Please check your internet.";
        _baseApiService.showSnackbar(
          "Network Error",
          "Could not connect. Please check your internet connection.",
        );
        isLoading.value = false;
        return;
      }

      // ✅ Check if OTP generation failed (priority over verify response)
      if (otpResponse != null && otpResponse.status == "error") {
        loginError.value =
            otpResponse.message.isNotEmpty
                ? otpResponse.message
                : "Unable to send OTP. Please try again.";
        _baseApiService.showSnackbar("Error", loginError.value);
        isLoading.value = false;
        return;
      }

      // ✅ Check if mobile verification failed
      if (verifyResponse != null && verifyResponse.status == "error") {
        loginError.value =
            verifyResponse.message.isNotEmpty
                ? verifyResponse.message
                : "Unable to verify mobile number. Please try again.";
        _baseApiService.showSnackbar("Error", loginError.value);
        isLoading.value = false;
        return;
      }

      if (verifyResponse != null && verifyResponse.status == "success") {
        // AppSharedPref.instance.setOTP(otp.otp);
        final role = verifyResponse.data.userRole;
        final userId =
            verifyResponse.data.userId ?? verifyResponse.data.customerId ?? -1;
        final token = verifyResponse.token;

        print("✅ Verification successful");
        print("User Role: $role");
        print("User ID: $userId");
        print(
          "Token: '$token'",
        ); // Print with quotes to see empty string clearly

        // ⚠️ DEBUG MODE: Bypass OTP if debug flag is enabled and phone matches
        if (kDebugModeBypassOTP && phoneNumber == kDebugPhoneNumber) {
          print("🔧 DEBUG MODE: Bypassing OTP verification for $phoneNumber");
          // Save token and user data
          await AppSharedPref.instance.setToken(token);
          await AppSharedPref.instance.setUserID(userId);
          await AppSharedPref.instance.setMobileNumber(phoneNumber);
          await AppSharedPref.instance.setRole(role.toString().split('.').last);
          await AppSharedPref.instance.setVerificationStatus(true);

          print("✅ User logged in directly (DEBUG MODE)");
          loginError.value = ""; // Clear error on success
          _baseApiService.showSnackbar(
            "Debug Mode",
            "Logged in directly (OTP bypassed for testing)",
          );

          // Navigate based on role
          if (role == "technician") {
            Get.offAllNamed('/technician-dashboard');
          } else {
            Get.offAllNamed('/home');
          }
          return;
        }

        // --- Key Change: Check for Guest/Unregistered ---
        // Define conditions for being a "Guest" or unregistered user.
        // This might be an empty token, a specific role, or a specific message.
        // Adjust these conditions based on your API's actual response for new users.
        bool isGuest =
            token.isEmpty ||
            token == '' ||
            role == UserRole.unknown; // Example conditions

        if (isGuest) {
          print(
            "📱 User identified as Guest/Unregistered. Navigating to UnregisteredUserScreen.",
          );
          // Save necessary info for the unregistered user
          // Even if token is empty, saving phoneNumber and a placeholder might be useful
          // You might get a temporary ID or session token from the API for guests, use that if available.
          AppSharedPref.instance.setUserID(
            userId,
          ); // Save the ID if provided, even for guests
          AppSharedPref.instance.setMobileNumber(phoneNumber);
          AppSharedPref.instance.setToken(
            "Guest",
          ); // Save the (possibly empty) token
          AppSharedPref.instance.setRole("Guest"); // Set role explicitly
          AppSharedPref.instance.setVerificationStatus(
            false,
          ); // Indicate not fully verified
          Get.to(
            () => OTPScreen(),
            binding: OTPBinding(
              phoneNumber: phoneNumber,
              token: token,
              userID: userId,
              underReview: verifyResponse.serviceStatus == "under_review",
              // underReview: verifyResponse.serviceStatus == "feasible",
            ),
          );
          // Navigate directly to UnregisteredUserScreen for guests
          // Get.offAll(
          //   () => UnregisteredUserScreen(),
          //   // binding: ScaffoldScreenBinding(),
          // ); // Assuming binding is correct
          // Show a welcome message or instructions specific to new users if desired
          // _baseApiService.showSnackbar(
          //   "Welcome!",
          //   "Please complete your registration.",
          //   snackPosition: SnackPosition.BOTTOM,
          // );
          // return; // Stop further processing
        }

        // --- End Key Change ---

        // If not a guest, proceed with standard role-based navigation
        switch (role) {
          case UserRole.customer:
            // Standard customer flow - go to OTP
            AppSharedPref.instance.setVerificationStatus(
              true,
            ); // Or keep false if OTP confirms verification
            // Consider if OTP is always needed for existing customers or just guests
            // For now, keeping original flow for existing customers
            Get.to(
              () => OTPScreen(),
              binding: OTPBinding(
                phoneNumber: phoneNumber,
                token: token,
                userID: userId,
              ),
            );
            break;

          case UserRole.technician:
            // ✅ CHANGED: Technicians also go through OTP verification
            AppSharedPref.instance.setToken(token);
            AppSharedPref.instance.setUserID(userId);
            AppSharedPref.instance.setMobileNumber(phoneNumber);
            AppSharedPref.instance.setRole("technician");

            // Show OTP screen for verification
            Get.to(
              () => OTPScreen(),
              binding: OTPBinding(
                phoneNumber: phoneNumber,
                token: token,
                userID: userId,
                underReview: verifyResponse.serviceStatus == "under_review",
              ),
            );
            break;

          // case UserRole.admin:
          // _baseApiService.showSnackbar(
          //   "Admin Access",
          //   "Redirecting to admin panel...",
          //   snackPosition: SnackPosition.BOTTOM,
          // );
          // Get.to(() => AdminDashboardScreen());
          // break;

          default:
            // Handle any other unexpected roles
            // _baseApiService.showSnackbar(
            //   "Access Denied",
            //   "Your account type is not recognized. Please contact support.",
            // );
            break;
        }
      }
    } catch (e) {
      print("Exception during login: $e");
      loginError.value = "An unexpected error occurred. Please try again.";
      _baseApiService.showSnackbar("Error", loginError.value);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // ✅ Stop clipboard monitoring
    _clipboardCheckTimer?.cancel();
    // ⚠️ Don't dispose phoneController here as it may still be in use
    // The framework will handle cleanup when needed
    super.onClose();
  }
}
