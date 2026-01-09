import 'dart:async';

import 'package:flutter/material.dart';
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

  // ✅ OTP Mode: "whatsapp" or "sms"
  RxString otpMode = "whatsapp".obs;

  late Timer timer;
  final BaseApiService _baseApiService = BaseApiService(BaseApiService.api);

  @override
  void onInit() {
    super.onInit();
    startTimer();
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
      // Add API call to resend OTP if needed
      ApiServices().generateOTP(phone, isWhatsApp: true);
      _baseApiService.showSnackbar(
        "OTP",
        "OTP resent to $phone",
      ); // Example feedback
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
      _baseApiService.showSnackbar(
        "Error",
        "Please enter a valid 6-digit OTP.",
      );
      return;
    }

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
          if (userRole == "technician") {
            Get.offAllNamed(AppRoutes.technicianDashboard);
          } else {
            Get.offAllNamed(AppRoutes.home);
          }
        } else {
          _baseApiService.showSnackbar(
            "Error",
            verifyResponse?.message ?? "Invalid OTP",
          );
          _clearOtpFields();
        }
      } catch (e) {
        _baseApiService.showSnackbar(
          "Error",
          "OTP verification failed. Please try again.",
        );
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
        _baseApiService.showSnackbar(
          "Error",
          verifyResponse?.message ?? "Invalid OTP",
        );
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
      _baseApiService.showSnackbar(
        "Error",
        "Something went wrong. Please try again.",
      );
      _navigateToUnregisteredFlow();
    }
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
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var n in focusNodes) {
      n.dispose();
    }
    super.onClose();
  }
}
