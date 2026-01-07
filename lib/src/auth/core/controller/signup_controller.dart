import 'dart:async';

import 'package:asia_fibernet/src/auth/core/controller/binding/otp_binding.dart';
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:asia_fibernet/src/services/sharedpref.dart';

import '../../ui/otp_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../services/apis/api_services.dart';

// Import your ApiServices
class SignUpController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // --- Dependencies ---
  final ApiServices _apiService =
      Get.find<ApiServices>(); // Get the ApiServices instance

  // --- Text Editing Controllers ---
  final fullNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  // Add controller for Referral Code if you have a field for it
  final referralCodeController = TextEditingController();

  // --- Animation Controllers (from your existing code) ---
  late AnimationController animationController;
  late Animation<double> textAnimation;
  late Animation<double> cardAnimation;

  // --- Observable for Selected Plan ---
  final selectedPlan = ''.obs; // Or RxString? selectedPlan = RxString('');

  // --- Loading State for Registration ---
  final RxBool isRegistering = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize animations (from your existing code)
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    textAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
    cardAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOut),
    );
    animationController.forward();
  }

  // --- Method to Handle Registration ---
  Future<void> registerCustomer() async {
    BaseApiService baseApiService = Get.find<BaseApiService>();
    isRegistering(true);
    try {
      // final deviceInfo = await DeviceInfoUtils.getAllDeviceInfo();

      // ✅ Wrap API call with timeout (15 seconds)
      final bool isSuccess = await _apiService
          .registerCustomer(
            fullName: fullNameController.text.trim(),
            mobileNumber: mobileNumberController.text.trim(),
            connectionType: "WiFi",
            email: emailController.text.trim(),
            address:
                ("${addressController.text.trim()}, ${cityController.text.trim()}, ${stateController.text.trim()}"),
            city: cityController.text.trim(),
            state: stateController.text.trim(),
            pinCode: pincodeController.text.trim(),
            referralCode: referralCodeController.text.trim(),
            // wifiName: deviceInfo['wifi_name'] ?? 'Unknown',
            // wifiBssid: deviceInfo['wifi_bssid'] ?? '00:00:00:00:00:00',
            // wifiGateway: deviceInfo['wifi_gateway'] ?? '0.0.0.0',
            // gpsLatitude: deviceInfo['latitude']?.toString() ?? '0.0',
            // gpsLongitude: deviceInfo['longitude']?.toString() ?? '0.0',
            wifiName: 'Unknown',
            wifiBssid: '00:00:00:00:00:00',
            wifiGateway: '0.0.0.0',
            gpsLatitude: '0.0',
            gpsLongitude: '0.0',
          )
          .timeout(
            const Duration(seconds: 10), // ⏱️ 15-second timeout
            onTimeout: () {
              throw TimeoutException('Server did not respond in time');
            },
          );

      if (isSuccess) {
        // await Get.offAll(
        //   () => OTPScreen(),
        //   binding: BindingsBuilder(
        //     () => OTPBinding(
        //       phoneNumber: mobileNumberController.text.trim(),
        //       token: "Guest",
        //       userID: -1,
        //     ),
        //   ),
        // );
        // ✅ Manually register OTPController with required data
        // Get.put();
        AppSharedPref.instance.setMobileNumber(
          mobileNumberController.text.trim(),
        );
        await AppSharedPref.instance.setUserID(-1);
        await AppSharedPref.instance.setToken("Guest");
        await AppSharedPref.instance.setRole('unknown');
        await AppSharedPref.instance.setVerificationStatus(false);
        // // ✅ Navigate without binding
        // await Get.offAll(
        //   () => OTPScreen(),
        //   binding: OTPBinding(
        //     phoneNumber: mobileNumberController.text.trim(),
        //     token: "Guest",
        //     userID: -1,
        //     underReview: true,
        //   ),
        // );
        Get.offAllNamed(AppRoutes.kycReview);
        clearForm();
        // await Get.offAll(() => UnregisteredUserScreen());
      }
    } on TimeoutException {
      baseApiService.showSnackbar(
        "Timeout",
        "The server is taking too long to respond. Please check your internet connection and try again.",

        isError: true,
      );
    } catch (e) {
      baseApiService.showSnackbar(
        "Error",
        "Registration failed: ${e.toString().split(':').first}",
        isError: true,
      );
    } finally {
      isRegistering(false); // 👈 Always reset loading
    }
  }

  // --- Optional: Method to Clear Form ---
  void clearForm() {
    fullNameController.clear();
    mobileNumberController.clear();
    emailController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    referralCodeController.clear();
    selectedPlan.value = ''; // Or RxString? selectedPlan.value = null;
  }

  @override
  void onClose() {
    // Dispose controllers
    fullNameController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    referralCodeController.dispose();
    animationController.dispose();
    super.onClose();
  }
}
