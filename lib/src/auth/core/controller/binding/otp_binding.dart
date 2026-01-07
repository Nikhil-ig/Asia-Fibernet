import 'package:get/get.dart';
// Adjust the import path according to your project structure
import '../otp_controller.dart'; // Or wherever OTPController is

/// Binding class for OTPScreen.
/// Responsible for creating the OTPController with the required phone number.
class OTPBinding implements Bindings {
  final String phoneNumber;
  final String token;
  final int userID;
  bool? underReview;

  OTPBinding({
    required this.phoneNumber,
    required this.token,
    required this.userID,
    this.underReview,
  });

  @override
  void dependencies() {
    // Register the OTPController, passing the phone number.
    // Get.lazyPut creates it only when first accessed (e.g., when OTPScreen is built).
    Get.lazyPut<OTPController>(
      () => OTPController(
        phone: phoneNumber,
        token: token,
        userID: userID,
        underReview: underReview,
      ),
    );
    // Or Get.put for immediate creation (less common for this case).
    // Get.put(OTPController(phone: phoneNumber));
  }
}
