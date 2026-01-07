import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../services/apis/base_api_service.dart';

class ModemInstallationController extends GetxController {
  // Selected files
  var signedInvoiceFile = Rx<File?>(null);
  var modemPictureFile = Rx<File?>(null);
  var ucReportFile = Rx<File?>(null);
  var upiPaymentFile = Rx<File?>(null);

  // Form fields
  var powerLevel = ''.obs;
  var latitude = ''.obs;
  var longitude = ''.obs;
  var selectedPaymentType = 'Cash'.obs;
  var otp = ''.obs;

  // State variables
  var isLoading = false.obs;
  var isGeneratingOtp = false.obs;
  var isSubmitting = false.obs;
  var error = ''.obs;
  var successMessage = ''.obs;

  final ImagePicker _imagePicker = ImagePicker();

  int? customerId;

  @override
  void onInit() {
    super.onInit();
    customerId = Get.arguments?['customerId'];
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude.value = position.latitude.toStringAsFixed(6);
      longitude.value = position.longitude.toStringAsFixed(6);
    } catch (e) {
      print("Location error: $e");
      latitude.value = '0.0';
      longitude.value = '0.0';
      BaseApiService().showSnackbar(
        'Location Error',
        'Unable to fetch current location',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage(ImageSource source, Rx<File?> fileVariable) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (image != null) {
        fileVariable.value = File(image.path);
        error.value = '';
      }
    } catch (e) {
      error.value = 'Failed to pick image: $e';
    }
  }

  void removeImage(Rx<File?> fileVariable) {
    fileVariable.value = null;
  }

  Future<void> generateOtp() async {
    try {
      isGeneratingOtp.value = true;
      error.value = '';

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Generate random 6-digit OTP
      final randomOtp = (100000 + Random().nextInt(900000)).toString();
      otp.value = randomOtp;

      BaseApiService().showSnackbar('OTP Generated', 'Your OTP is: $randomOtp');
    } catch (e) {
      error.value = 'Failed to generate OTP: $e';
    } finally {
      isGeneratingOtp.value = false;
    }
  }

  Future<void> downloadInvoice() async {
    try {
      // Simulate download process
      BaseApiService().showSnackbar(
        'Download Started',
        'Invoice download in progress...',
      );

      await Future.delayed(Duration(seconds: 2));

      BaseApiService().showSnackbar(
        'Download Complete',
        'Invoice downloaded successfully!',
      );
    } catch (e) {
      error.value = 'Failed to download invoice: $e';
    }
  }

  Future<void> submitInstallation() async {
    try {
      // Validation
      if (signedInvoiceFile.value == null) {
        error.value = 'Please upload signed invoice';
        return;
      }

      if (modemPictureFile.value == null) {
        error.value = 'Please upload modem picture';
        return;
      }

      if (ucReportFile.value == null) {
        error.value = 'Please upload UC report picture';
        return;
      }

      if (powerLevel.value.isEmpty) {
        error.value = 'Please enter power level';
        return;
      }

      if (selectedPaymentType.value == 'UPI' && upiPaymentFile.value == null) {
        error.value = 'Please upload UPI payment screenshot';
        return;
      }

      isSubmitting.value = true;
      error.value = '';

      // Simulate API submission
      await Future.delayed(Duration(seconds: 3));

      successMessage.value = 'Modem installation submitted successfully!';
      BaseApiService().showSnackbar('Success', 'Modem installation completed!');

      // Navigate back after success
      await Future.delayed(Duration(seconds: 2));
      Get.back(result: true);
    } catch (e) {
      error.value = 'Failed to submit installation: $e';
    } finally {
      isSubmitting.value = false;
    }
  }

  void updatePowerLevel(String value) => powerLevel.value = value;
  void updatePaymentType(String value) => selectedPaymentType.value = value;
}
