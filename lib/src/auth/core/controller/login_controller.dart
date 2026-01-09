// ignore_for_file: avoid_print

import 'package:asia_fibernet/src/services/sharedpref.dart';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
// Import your ApiServices
import '../../../services/apis/base_api_service.dart';
import '../model/verify_mobile_model.dart';
import '../../../services/apis/api_services.dart';
// Import OTP Screen
import '../../ui/otp_screen.dart';
import 'binding/otp_binding.dart';

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

  final phoneController = TextEditingController(
    text: AppSharedPref.instance.getMobileNumber(),
  );
  // late AnimationController _animationController;
  // late Animation<double> logoAnimation;
  // late Animation<double> textAnimation;
  // late Animation<double> cardAnimation;

  // ✅ Add a loading state observable
  final RxBool isLoading = false.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  //   // _animationController = AnimationController(
  //   //   duration: Duration(milliseconds: 1000),
  //   //   vsync: this, // Requires GetSingleTickerProviderStateMixin
  //   // );
  //   // // Define curves for different timings if needed
  //   // logoAnimation = CurvedAnimation(
  //   //   parent: _animationController,
  //   //   curve: Curves.easeOut,
  //   // );
  //   // textAnimation = CurvedAnimation(
  //   //   parent: _animationController,
  //   //   curve: Curves.easeInOut,
  //   // );
  //   // cardAnimation = CurvedAnimation(
  //   //   parent: _animationController,
  //   //   curve: Curves.easeInOut,
  //   // );
  //   // // Start the animation
  //   // _animationController.forward();
  // }

  // Inside LoginController class

  void login() async {
    if (isLoading.value) {
      print("Login already in progress...");
      return;
    }

    String phoneNumber = phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      _baseApiService.showSnackbar("Error", "Please enter a mobile number.");
      return;
    }

    isLoading.value = true;

    try {
      print("Attempting to verify mobile: $phoneNumber");

      final verifyResponse = await _apiService.mobileVerification(phoneNumber);
      await _apiService.generateOTP(phoneNumber);

      if (verifyResponse == null) {
        // _baseApiService.showSnackbar(
        //   "Network Error",
        //   "Could not connect. Please check your internet connection.",
        // );
        return;
      }

      if (verifyResponse.status == "success") {
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
      } else {
        // API returned status != "success"
        _baseApiService.showSnackbar("Login Failed", verifyResponse.message);
      }
    } catch (e) {
      print("Exception during login: $e");
      _baseApiService.showSnackbar(
        "Error",
        "An unexpected error occurred. Please try again.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // _animationController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
