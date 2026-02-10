import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../ui/scaffold_screen.dart';
import '/src/services/routes.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/sharedpref.dart';
import '../model/verify_mobile_model.dart';

class OTPController extends GetxController {
  // Receive phone number via constructor
  final String phone;
  final String token;
  final int userID;
  bool? underReview;

  OTPController({
    required this.phone,
    required this.token,
    required this.userID,
    this.underReview,
  });

  // Rx variables
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  RxInt currentIndex = 0.obs;
  RxInt secondsRemaining = 60.obs;
  RxBool resendEnabled = false.obs;

  // ✅ Timer for showing SMS option after 45 seconds
  RxInt smsCountdownSeconds = 45.obs;
  RxBool showSmsOption = false.obs;

  // ✅ OTP Mode: "whatsapp" or "sms"
  RxString otpMode = "whatsapp".obs;

  // ✅ Error tracking for display
  RxString otpError = "".obs;
  RxBool isVerifying = false.obs;

  late Timer timer;
  late Timer smsTimer;
  final BaseApiService _baseApiService = BaseApiService(BaseApiService.api);

  @override
  void onInit() {
    super.onInit();
    startTimer();
    startSmsCountdown(); // ✅ Start SMS option countdown
    // ✅ Auto-detect OTP from clipboard when screen loads
    autoDetectOtpFromClipboard();
  }

  void startTimer() {
    secondsRemaining.value = 60;
    resendEnabled.value = false;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining.value--;
      if (secondsRemaining.value <= 0) {
        resendEnabled.value = true;
        timer.cancel();
      }
    });
  }

  /// ✅ Start countdown for showing SMS option (45 seconds)
  void startSmsCountdown() {
    smsCountdownSeconds.value = 45;
    showSmsOption.value = false;
    smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      smsCountdownSeconds.value--;
      if (smsCountdownSeconds.value <= 0) {
        showSmsOption.value = true;
        timer.cancel();
      }
    });
  }

  void onOtpChanged(String value, int index) {
    // Move forward on input
    if (value.length == 1 && index < 5) {
      FocusScope.of(Get.context!).requestFocus(focusNodes[index + 1]);
    }

    // Auto-verify when complete
    if (otpControllers.every((c) => c.text.isNotEmpty)) {
      Future.delayed(const Duration(milliseconds: 100), verifyAndLogin);
    }
  }

  void resendOTP() {
    if (resendEnabled.value) {
      // Reset timer state
      secondsRemaining.value = 60;
      resendEnabled.value = false;
      startTimer();

      // ✅ Reset SMS countdown when resending
      if (otpMode.value == "sms") {
        smsCountdownSeconds.value = 45;
        showSmsOption.value = true; // Keep SMS option visible after first show
      } else {
        startSmsCountdown(); // Restart countdown if switching to WhatsApp
      }

      // ✅ Call API with selected OTP mode (SMS or WhatsApp)
      final isWhatsApp = otpMode.value == "whatsapp";
      ApiServices().generateOTP(phone, resend: true, isWhatsApp: isWhatsApp);

      final method = isWhatsApp ? "WhatsApp" : "SMS";
      _baseApiService.showSnackbar("OTP", "OTP resent to $phone via $method");
    }
  }

  /// ✅ Handle pasted OTP - auto-fill fields and verify
  void handleOtpPaste(String pastedText) {
    // Extract only digits from pasted text
    final otpDigits = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

    if (otpDigits.length >= 6) {
      // ✅ Clear all fields first
      for (int i = 0; i < 6; i++) {
        otpControllers[i].clear();
      }

      // ✅ Small delay to ensure clear is processed
      Future.delayed(const Duration(milliseconds: 10), () {
        // Fill OTP fields with first 6 digits
        for (int i = 0; i < 6; i++) {
          otpControllers[i].text = otpDigits[i];
          print('✅ Filled field $i with digit: ${otpDigits[i]}');
        }

        print("✅ OTP auto-filled from paste: ${'*' * 6}");
        print("✅ OTP values: ${otpControllers.map((c) => c.text).join()}");

        // Auto-verify after filling
        Future.delayed(const Duration(milliseconds: 500), verifyAndLogin);
      });
    } else {
      print("❌ Invalid OTP length (pasted text had less than 6 digits)");
    }
  }

  /// ✅ Auto-detect OTP from clipboard on screen load
  Future<void> autoDetectOtpFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        final clipboardText = data.text!;
        // Check if clipboard contains digits
        final otpDigits = clipboardText.replaceAll(RegExp(r'[^0-9]'), '');

        if (otpDigits.length >= 6) {
          handleOtpPaste(otpDigits);
          _baseApiService.showSnackbar(
            "OTP Detected",
            "OTP automatically filled from clipboard",
          );
        }
      }
    } catch (e) {
      // Silently fail if clipboard access fails
      print("Could not access clipboard: $e");
    }
  }

  // ) {
  //   if (resendEnabled.value) {
  //     // Reset timer state
  //     secondsRemaining.value = 60;
  //     resendEnabled.value = false;
  //     startTimer();

  //     // ✅ Call API with OTP mode
  //     ApiServices().generateOTP(
  //       phone,
  //       resend: true,
  //       isWhatsApp: otpMode.value == "whatsapp",
  //     );

  //     final modeText = otpMode.value == "whatsapp" ? "WhatsApp" : "SMS";
  //     _baseApiService.showSnackbar(
  //       "OTP Resent",
  //       "OTP sent via $modeText to $phone",
  //     );
  //   }
  // }

  // void verifyAndLogin() async {
  //   // Join the text from all controllers to get the full OTP string
  //   String enteredOTP = otpControllers.map((c) => c.text).join();

  //   // Validate length before proceeding
  //   if (enteredOTP.length != 6) {
  //     _baseApiService.showSnackbar(
  //       "Error",
  //       "Please enter a valid 6-digit OTP.",
  //     );
  //     return;
  //   }

  //   // Dummy verification - Replace with real API call
  //   bool isOtpValid = (enteredOTP == "123456"); // Example only

  //   if (isOtpValid) {
  //     print("✅ OTP verified successfully for user ID: $userID");

  //     // Check if still a Guest (token missing or set as Guest)
  //     bool isGuestAfterOtp = token.isEmpty || token == "Guest";

  //     if (isGuestAfterOtp) {
  //       print("📱 OTP verified for Guest user → UnregisteredUserScreen");

  //       // Save minimal guest info
  //       await AppSharedPref.instance.setUserID(userID);
  //       await AppSharedPref.instance.setMobileNumber(phone);
  //       await AppSharedPref.instance.setToken("Guest");
  //       await AppSharedPref.instance.setRole(UserRole.unknown.name); // ✅ Fix
  //       await AppSharedPref.instance.setVerificationStatus(false);

  //       // Navigate to guest flow
  //       Get.offAndToNamed(
  //         underReview ?? true ? AppRoutes.kycReview : AppRoutes.finalKYCReview,
  //         // binding: ScaffoldScreenBinding(),
  //       );
  //       _baseApiService.showSnackbar(
  //         "Success",
  //         "OTP Verified! Please complete your profile.",
  //       );
  //       return;
  //     }

  //     // ✅ Registered user flow
  //     print("📱 OTP verified for registered user → Main App");

  //     await AppSharedPref.instance.setToken(token);
  //     await AppSharedPref.instance.setUserID(userID);
  //     await AppSharedPref.instance.setMobileNumber(phone);

  //     // Use correct role (customer, technician, admin).
  //     // Ideally this should come from API response, not hardcoded.
  //     await AppSharedPref.instance.setRole(UserRole.customer.name); // ✅ Fix
  //     await AppSharedPref.instance.setVerificationStatus(true);

  //     Get.offAll(() => ScaffoldScreen(), binding: ScaffoldScreenBinding());
  //   } else {
  //     _baseApiService.showSnackbar("Error", "Invalid OTP");
  //     // Clear OTP fields
  //     for (var c in otpControllers) {
  //       c.clear();
  //     }
  //     if (focusNodes.isNotEmpty) {
  //       FocusScope.of(Get.context!).requestFocus(focusNodes[0]);
  //     }
  //   }
  // }

  void verifyAndLogin() async {
    String enteredOTP = otpControllers.map((c) => c.text).join();

    if (enteredOTP.length != 6) {
      otpError.value = "Please enter a valid 6-digit OTP";
      _baseApiService.showSnackbar(
        "Error",
        "Please enter a valid 6-digit OTP.",
      );
      return;
    }

    // ✅ Set verification state to prevent multiple submissions
    isVerifying.value = true;
    otpError.value = ""; // Clear previous errors

    try {
      // 🔑 STEP 1: Check if user is already registered (has valid token)
      bool isGuest = token.isEmpty || token == "Guest";
      if (!isGuest) {
        // ✅ Registered user → verify OTP and go to home
        try {
          // Call the actual verifyOTP API
          final verifyResponse = await ApiServices().verifyOTP(
            otp: enteredOTP,
            mobile: phone,
          );

          if (verifyResponse != null && verifyResponse.isValid) {
            // ✅ OTP verified successfully
            // Token and user data are already saved by the API method

            if (!Get.isRegistered<ScaffoldController>()) {
              Get.put(ScaffoldController());
            }

            _baseApiService.showSnackbar("Success", verifyResponse.message);

            // 🔑 Check user role from response and navigate accordingly
            final userRole = verifyResponse.data.role;

            // 📱 Upload FCM token in background (non-blocking)
            // This runs after navigation so it doesn't slow down the login flow
            _uploadFcmTokenInBackground();

            if (userRole == "technician") {
              Get.offAllNamed(AppRoutes.technicianDashboard);
            } else {
              Get.offAllNamed(AppRoutes.home);
            }
          } else {
            // ✅ Show error message from API response as toast + display below OTP box
            final errorMessage = verifyResponse?.message ?? "Invalid OTP";
            print("❌ OTP Verification Failed: $errorMessage");
            otpError.value = errorMessage; // ✅ Store error for UI display
            _baseApiService.showSnackbar("Error", errorMessage, isError: true);
            _clearOtpFields();
          }
        } catch (e) {
          final errorMsg = "OTP verification failed. Please try again.";
          otpError.value = errorMsg;
          _baseApiService.showSnackbar("Error", errorMsg);
          _clearOtpFields();
        }
        return;
      } else if (AppSharedPref.instance.getRole() == 'technician') {
        Get.toNamed(AppRoutes.technicianDashboard);
        return;
      }

      // 👤 Guest/Unregistered user flow
      try {
        // Verify OTP first (even for guests)
        final verifyResponse = await ApiServices().verifyOTP(
          otp: enteredOTP,
          mobile: phone,
        );

        if (verifyResponse == null || !verifyResponse.isValid) {
          final errorMessage = verifyResponse?.message ?? "Invalid OTP";
          print("❌ OTP Verification Failed (Guest): $errorMessage");
          otpError.value = errorMessage; // ✅ Store error for UI display
          _baseApiService.showSnackbar("Error", errorMessage, isError: true);
          _clearOtpFields();
          return;
        }

        // Now fetch KYC status to decide next screen
        final kycStatusResponse = await ApiServices().checkKycStatus(phone);

        if (kycStatusResponse?.status != "success") {
          // Treat as new user with no KYC
          _navigateToUnregisteredFlow();
          return;
        }

        final data = kycStatusResponse!.data;
        final serviceStatus =
            kycStatusResponse.serviceStatus; // "feasible", "under_review", etc.
        final steps = data.registration.steps;
        final hasDocuments = data.documents.isNotEmpty;

        // Save guest context
        await AppSharedPref.instance.setUserID(data.registration.id);
        await AppSharedPref.instance.setMobileNumber(phone);
        await AppSharedPref.instance.setToken("Guest");
        await AppSharedPref.instance.setRole(UserRole.unknown.name);
        await AppSharedPref.instance.setVerificationStatus(false);

        // ✅ Decision Logic
        if (steps <= 3 || (serviceStatus == "under_review" || underReview!)) {
          Get.offAndToNamed(AppRoutes.kycReview);
        } else if (steps >= 3 && hasDocuments) {
          // Fully complete → show policy screen
          Get.offAndToNamed(AppRoutes.finalKYCReview);
        } else {
          // Incomplete KYC → allow editing
          Get.offAndToNamed(AppRoutes.unregisteredUser);
        }
      } catch (e) {
        print("Guest OTP/KYC flow error: $e");
        final errorMsg = "Something went wrong. Please try again.";
        otpError.value = errorMsg;
        _baseApiService.showSnackbar("Error", errorMsg);
        _navigateToUnregisteredFlow();
      }
    } finally {
      isVerifying.value = false; // Clear verification state
    }
  }

  /// 📱 Upload FCM token to the API after successful login
  /// 📱 Upload FCM token in background (non-blocking)
  /// This method runs asynchronously without awaiting, allowing login to proceed
  void _uploadFcmTokenInBackground() {
    // Run in background without blocking the UI
    Future.microtask(() async {
      try {
        // 📱 Step 1: Refresh FCM token from Firebase
        developer.log(
          '🔄 Refreshing FCM token from Firebase after login...',
          name: 'OTPController._uploadFcmTokenInBackground',
        );

        final newFcmToken = await FirebaseMessaging.instance.getToken();

        if (newFcmToken != null && newFcmToken.isNotEmpty) {
          // Save the fresh token
          await AppSharedPref.instance.setfcmToken(newFcmToken);
          developer.log(
            '✅ Fresh FCM token saved from Firebase: $newFcmToken',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
        }

        // 📱 Step 2: Get FCM token from SharedPreferences
        final fcmToken = await AppSharedPref.instance.getFCMToken();

        if (fcmToken == null || fcmToken.isEmpty) {
          developer.log(
            '⚠️ FCM token is empty or null in background upload',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
          return;
        }

        developer.log(
          '📤 Uploading FCM token to API: $fcmToken',
          name: 'OTPController._uploadFcmTokenInBackground',
        );

        // 📱 Step 3: Upload FCM token to API
        final apiService = ApiServices();
        final result = await apiService.fcmToken();

        if (result != null && result['status'] != 'skipped') {
          developer.log(
            '✅ FCM Token uploaded successfully in background\nResponse: $result',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
        } else {
          developer.log(
            '⚠️ FCM token upload skipped or failed - API returned: $result',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
        }
      } catch (e) {
        developer.log(
          '❌ Error uploading FCM token in background: $e',
          name: 'OTPController._uploadFcmTokenInBackground',
          error: e,
        );
      }
    });
  }

  void _clearOtpFields() {
    for (var c in otpControllers) c.clear();
    if (focusNodes.isNotEmpty) {
      FocusScope.of(Get.context!).requestFocus(focusNodes[0]);
    }
  }

  void _navigateToUnregisteredFlow() {
    Get.offAndToNamed(AppRoutes.unregisteredUser);
  }

  @override
  void onClose() {
    timer.cancel();
    if (smsTimer.isActive) smsTimer.cancel(); // ✅ Cancel SMS timer
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var n in focusNodes) {
      n.dispose();
    }
    super.onClose();
  }
}
