// // controllers/technician_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../services/apis/api_services.dart';
// class TechnicianController extends GetxController {
//   final ApiServices apiServices = ApiServices();
//   final otpController = TextEditingController();
//   final isLoading = false.obs;

//   Future<void> verifyOtp({
//     required int complaintId,
//     required String ticketNo,
//     required String otp,
//     required VoidCallback onSuccess,
//   }) async {
//     isLoading.value = true;
//     final success = await apiServices.verifyTechnicianOtp(
//       complaintId: complaintId,
//       ticketNo: ticketNo,
//       otp: otp,
//     );
//     isLoading.value = false;

//     if (success) {
//       onSuccess();
//     }
//   }

//   Future<void> resendOtp(String ticketNo) async {
//     final success = await apiServices.resendTechnicianOtp(ticketNo);
//     if (success) {
//       BaseApiService().showSnackbar("OTP Sent", "A new OTP has been sent to the customer.");
//     }
//   }
// }
