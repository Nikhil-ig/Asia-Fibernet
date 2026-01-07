// ignore_for_file: public_member_api_docs, sort_constructors_first
// lib/src/ui/screen/profile_screen.dart
import 'dart:io';
import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

// Import your models and services
import '/src/services/apis/base_api_service.dart';
import '../../../auth/core/model/customer_details_model.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/sharedpref.dart';

// Import your theme
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';

// Import widgets
import '../../../theme/widgets/appbar.dart';
import '../widgets/app_textfield.dart';

class ProfileController extends GetxController {
  final ApiServices _apiServices = Get.find<ApiServices>();
  final BaseApiService _baseAPIServices = Get.find<BaseApiService>();
  final customerProfile = Rxn<CustomerDetails>();
  final isUpdating = false.obs;
  final isLoading = true.obs;

  // ✅ Updated: Only include fields that exist in real API
  final contactNameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();

  Rx<File>? profileImage;

  // Confetti Controller
  final ConfettiController confettiController = ConfettiController(
    duration: Duration(seconds: 3),
  );

  @override
  void onInit() {
    super.onInit();
    fetchCustomerProfile();
    fetchRelocationStatus(); // <-- Add this
  }

  Future<void> fetchCustomerProfile() async {
    isLoading(true);
    try {
      final int? customerId = AppSharedPref.instance.getUserID();
      if (customerId == null) {
        _baseAPIServices.showSnackbar(
          'Error',
          'Customer ID not found. Please log in.',
        );
        return;
      }

      final CustomerDetails? profile = await _apiServices.fetchCustomer();
      // final CustomerDetails? profile = profileData!;
      if (profile != null) {
        customerProfile.value = profile;
        _populateControllers(profile);
      } else {
        _baseAPIServices.showSnackbar('Error', 'Failed to load profile data.');
      }
    } catch (e) {
      _baseAPIServices.showSnackbar('Error', 'Failed to fetch profile: $e');
    } finally {
      isLoading(false);
    }
  }

  // ✅ Updated: Only populate real existing fields
  void _populateControllers(CustomerDetails profile) {
    contactNameController.text = profile.contactName!;
    mobileController.text = profile.cellPhone!;
    emailController.text = profile.email!;
    addressController.text = profile.address!;
    cityController.text = profile.city!;
    stateController.text = profile.state!;
  }

  // requestDisconnection() async {
  //   final success = await _apiServices.requestDisconnection(
  //     reason: "Moving to another city",
  //     disconnectionDate: "2025-10-15",
  //     bankAccountNo: "123456789012",
  //     ifscCode: "HDFC0001234",
  //     bankRegisteredName: "Kalmesh Sukhwal",
  //     ftthNo: "08029878909",
  //   );
  //   if (success) {
  //     // Handle success (e.g., show confirmation, navigate)
  //     // _baseAPIServices.showSnackbar(
  //     //   'Sended',
  //     //   'Disconnection request submitted successfully',
  //     // );
  //   }
  // }

  // lib/src/ui/screen/profile_screen.dart → inside ProfileController

  // ✅ BEAUTIFUL DISCONNECTION SHEET
  // Beautiful Request Disconnection Bottom Sheet
  void showDisconnectionSheet() {
    final reasonCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final bankAccCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ftthCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        height: Get.size.height * .85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.close_circle,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Disconnection',
                                style: AppText.headingMedium.copyWith(
                                  color: AppColors.backgroundLight,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'We\'re sorry to see you go',
                                style: AppText.bodyMedium.copyWith(
                                  color: AppColors.backgroundLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDisconnectionField(
                        controller: reasonCtrl,
                        label: 'Reason for Disconnection',
                        hint: 'e.g., Moving to another city, Service issues...',
                        icon: Iconsax.message_question,
                        maxLines: 2,
                      ),
                      SizedBox(height: 16),

                      _buildDisconnectionField(
                        controller: dateCtrl,
                        label: 'Preferred Disconnection Date',
                        hint: 'YYYY-MM-DD',
                        icon: Iconsax.calendar,
                        onTap: () => _selectDisconnectionDate(dateCtrl),
                      ),

                      // Bank Details Section
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF90CAF9),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.bank,
                                  color: Color(0xFF1976D2),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Bank Details for Refund',
                                  style: TextStyle(
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildDisconnectionField(
                              controller: bankAccCtrl,
                              label: 'Bank Account Number',
                              hint: 'Enter 12-digit account number',
                              icon: Iconsax.card,
                            ),
                            SizedBox(height: 12),
                            _buildDisconnectionField(
                              controller: ifscCtrl,
                              label: 'IFSC Code',
                              hint: 'e.g., HDFC0001234',
                              icon: Iconsax.code,
                            ),
                            SizedBox(height: 12),
                            _buildDisconnectionField(
                              controller: nameCtrl,
                              label: 'Bank Registered Name',
                              hint: 'Name as per bank records',
                              icon: Iconsax.user,
                            ),
                          ],
                        ),
                      ),

                      _buildDisconnectionField(
                        controller: ftthCtrl,
                        label: 'FTTH Number',
                        hint: 'Your fiber connection number',
                        icon: Iconsax.receipt_text,
                      ),

                      SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Icon(
                                    //   Iconsax.arrow_left,
                                    //   color: Colors.grey.shade700,
                                    // ),
                                    SizedBox(width: 8),
                                    Text(
                                      'CANCEL',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF5252),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFF6B6B).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_validateDisconnectionForm(
                                    reasonCtrl,
                                    dateCtrl,
                                    bankAccCtrl,
                                    ifscCtrl,
                                    nameCtrl,
                                    ftthCtrl,
                                  )) {
                                    final success = await _apiServices
                                        .requestDisconnection(
                                          reason: reasonCtrl.text,
                                          disconnectionDate: dateCtrl.text,
                                          bankAccountNo: bankAccCtrl.text,
                                          ifscCode: ifscCtrl.text,
                                          bankRegisteredName: nameCtrl.text,
                                          ftthNo: ftthCtrl.text,
                                        );
                                    if (success) {
                                      Get.back();
                                      _showDisconnectionSuccess();
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.send_2,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'SUBMIT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildDisconnectionField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelSmall.copyWith(color: AppColors.textColorPrimary),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 16),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    enabled: onTap == null,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                if (onTap != null)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Iconsax.calendar, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _validateDisconnectionForm(
    TextEditingController reason,
    TextEditingController date,
    TextEditingController bankAcc,
    TextEditingController ifsc,
    TextEditingController name,
    TextEditingController ftth,
  ) {
    if (reason.text.isEmpty) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Please provide a reason for disconnection',
      );
      return false;
    }
    if (date.text.isEmpty) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Please select disconnection date',
      );
      return false;
    }
    if (bankAcc.text.isEmpty || bankAcc.text.length != 12) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Please enter valid 12-digit account number',
      );
      return false;
    }
    if (ifsc.text.isEmpty) {
      _baseAPIServices.showSnackbar('Error', 'Please enter IFSC code');
      return false;
    }
    if (name.text.isEmpty) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Please enter bank registered name',
      );
      return false;
    }
    if (ftth.text.isEmpty) {
      _baseAPIServices.showSnackbar('Error', 'Please enter FTTH number');
      return false;
    }
    return true;
  }

  void _selectDisconnectionDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textColorPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _showDisconnectionSuccess() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: Color(0xFF4CAF50),
                  size: 60,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Request Submitted!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your disconnection request has been submitted successfully. Our team will contact you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textColorSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 25),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'GOT IT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Beautiful Delete Account Dialog
  void showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: EdgeInsets.zero,

        content: SizedBox(
          width: Get.size.width * .9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with warning icon
              Container(
                width: Get.size.width * .9,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.warning_2,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Delete Account?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This action cannot be undone',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Warning content
              Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  children: [
                    _buildWarningItem(
                      icon: Iconsax.profile_delete,
                      text:
                          'All your personal data will be permanently deleted',
                    ),
                    SizedBox(height: 12),
                    _buildWarningItem(
                      icon: Iconsax.receipt,
                      text: 'Service history and billing records will be lost',
                    ),
                    SizedBox(height: 12),
                    _buildWarningItem(
                      icon: Iconsax.lock_slash,
                      text: 'You won\'t be able to recover your account',
                    ),
                    SizedBox(height: 20),

                    // Confirmation input
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFFFCDD2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Type "DELETE" to confirm',
                            style: AppText.headingSmall.copyWith(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: TextEditingController(),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: 'Type DELETE here...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                              ),
                              style: AppText.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 25),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFF5252).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Add your delete account logic here
                                deleteCustomerAccount();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.profile_delete,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'DELETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Color(0xFFD32F2F), size: 16.sp),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textColorSecondary,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }

  // Updated buttons in ProfileScreen (replace the existing ones)
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Request Disconnection Button
        Container(
          width: double.infinity,
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF9800).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed:
                () => Get.find<ProfileController>().showDisconnectionSheet(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.discount_circle, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Request Disconnection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Delete Account Button
        Container(
          width: double.infinity,
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF5252).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: showDeleteAccountDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.profile_delete, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ KEEP YOUR EXISTING deleteCustomerAccount() METHOD (it already clears data and navigates)
  // Just ensure it's async and handles API call:
  // deleteCustomerAccount() async {
  //   final deleted = await _apiServices.deleteCustomerAccount();
  //   if (deleted) {
  //     await AppSharedPref.instance.clearAllUserData();
  //     Get.offAllNamed(AppRoutes.login);
  //   }
  // }

  deleteCustomerAccount() async {
    final deleted = await _apiServices.deleteCustomerAccount();
    if (deleted) {
      // Clear local data and navigate to login
      await AppSharedPref.instance.clearAllUserData();
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> updateProfile() async {
    if (isUpdating.value) return;
    isUpdating(true);

    if (!_validateForm()) {
      isUpdating(false);
      return;
    }

    try {
      final userId = await AppSharedPref.instance.getUserID();
      final currentProfile = customerProfile.value;

      if (userId == null || currentProfile == null) return;

      // ✅ Updated: Only send fields that exist in API
      bool success = await _apiServices.editCustomerDetails(
        id: currentProfile.id!,
        customerId: userId,
        accountID: currentProfile.accountId.toString(),
        accountType: currentProfile.accountType!,
        contactName: contactNameController.text.trim(),
        address: addressController.text.trim(),
        cellphnumber: mobileController.text.trim(),
        email: emailController.text.trim(),
        // ❌ Removed: companyName, otherphnumber, websiteAddress (not in real API)
      );

      if (profileImage != null) {
        success = await _apiServices.uploadProfilePhoto(profileImage!.value);
      }

      if (success) {
        confettiController.play();

        // Show confetti on screen

        OverlayEntry(
          builder:
              (context) => Positioned.fill(
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: -pi / 2,
                  emissionFrequency: 0.01,
                  numberOfParticles: 20,
                  maxBlastForce: 100,
                  minBlastForce: 50,
                  gravity: 0.1,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent1,
                    AppColors.success,
                    AppColors.warning,
                  ],
                ),
              ),
        );

        // Refresh profile
        await fetchCustomerProfile();

        // Close edit screen after success
        Future.delayed(Duration(seconds: 2), () {
          Get.back(); // Go back to view screen
        });
      }
    } catch (e) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Update failed: $e',
        isError: true,
      );
    } finally {
      isUpdating(false);
      Navigator.pop(Get.context!);
    }
  }

  bool _validateForm() {
    final name = contactNameController.text.trim();
    final mobile = mobileController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      _baseAPIServices.showSnackbar('Error', 'Name is required', isError: true);
      return false;
    }

    if (mobile.isEmpty || mobile.length < 10) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Valid mobile number is required',
        isError: true,
      );
      return false;
    }

    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      _baseAPIServices.showSnackbar(
        'Error',
        'Enter a valid email',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> pickProfileImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      profileImage = File(image.path).obs;
      // Optional: Upload immediately or wait for save
      // await _apiServices.uploadProfilePhoto(profileImage!.value);
      update(); // Refresh UI
    }
  }

  void showRelocationSheet() {
    Get.bottomSheet(
      RelocationRequestBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
    );
  }

  // Add these fields in ProfileController
  final relocationStatus = Rxn<Map<String, dynamic>>();
  final isRelocationLoading = false.obs;

  // Add this method
  Future<void> fetchRelocationStatus() async {
    final mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) return;

    isRelocationLoading(true);
    try {
      final data = await _apiServices.checkRelocationStatus(mobile);
      if (data != null && data.containsKey('data')) {
        relocationStatus.value = data['data'];
      } else {
        relocationStatus.value = null;
      }
    } finally {
      isRelocationLoading(false);
    }
  }

  void logOut() {
    _apiServices.logOutDialog();
    // AppSharedPref.instance.clearAllUserData();
    // Get.offAll(() => LoginScreen(), binding: LoginBinding());
  }

  @override
  void onClose() {
    contactNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    confettiController.dispose();
    super.onClose();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Animated Gradient Background
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.1, 0.9],
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          RefreshIndicator(
            onRefresh: controller.fetchCustomerProfile,
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  title: FadeIn(
                    duration: Duration(milliseconds: 800),
                    child: Text(
                      'My Profile',
                      style: AppText.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black.withOpacity(0.2),
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  actions: [
                    SlideInRight(
                      duration: Duration(milliseconds: 500),
                      child: IconButton(
                        icon: Icon(Iconsax.logout, size: 22),
                        onPressed: () {
                          controller.logOut();
                        },
                      ),
                    ),
                  ],
                  iconTheme: IconThemeData(color: Colors.white),
                  pinned: true,
                  expandedHeight: 220,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Obx(() {
                      final profile = controller.customerProfile.value;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: [0.1, 0.9],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: Center(
                                child: FadeIn(
                                  duration: Duration(milliseconds: 1000),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    child: CircleAvatar(
                                      radius: 56,
                                      backgroundImage:
                                          profile?.profilePhoto != null
                                              ? NetworkImage(
                                                // "${BaseApiService.api}${profile!.profileImageUrl!}",
                                                profile!.fullProfileImageUrl!,
                                              ) // ✅ Fixed URL — removed redundant "uploads/profile/"
                                              : null,
                                      child:
                                          profile?.profilePhoto == null
                                              ? Icon(
                                                Iconsax.user,
                                                size: 50,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return _buildShimmerCard();
                      }

                      final profile = controller.customerProfile.value;

                      if (profile == null) {
                        return Column(
                          children: [
                            SizedBox(height: 40),
                            Icon(
                              Iconsax.profile_delete,
                              size: 60,
                              color: AppColors.textColorSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No profile data found',
                              style: AppText.bodyMedium.copyWith(
                                color: AppColors.textColorSecondary,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: controller.fetchCustomerProfile,
                              child: Text('Retry'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          // Welcome card
                          FadeInUp(
                            duration: Duration(milliseconds: 600),
                            child: Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: AppText.bodySmall.copyWith(
                                            color: AppColors.textColorSecondary,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          profile.contactName!,
                                          style: AppText.headingMedium.copyWith(
                                            color: AppColors.primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        // ✅ Removed: creationDate (doesn’t exist in real data)
                                      ],
                                    ),
                                  ),
                                  // Bounce(
                                  //   from: 10,
                                  //   infinite: true,
                                  //   child: Icon(
                                  //     Iconsax.headphone,
                                  //     color: AppColors.primary,
                                  //     size: 40,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Personal Info Card
                          FadeInUp(
                            duration: Duration(milliseconds: 700),
                            delay: Duration(milliseconds: 100),
                            child: _buildInfoCard(
                              context,
                              title: 'Personal Information',
                              icon: Iconsax.user,
                              items: [
                                _item(
                                  Iconsax.user,
                                  'Full Name',
                                  profile.contactName!,
                                ),
                                _item(
                                  Iconsax.call,
                                  'Mobile',
                                  profile.cellPhone!,
                                ),
                                if (profile.email != null &&
                                    profile.email!.isNotEmpty)
                                  _item(Iconsax.sms, 'Email', profile.email!),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // Location Card
                          FadeInUp(
                            duration: Duration(milliseconds: 800),
                            delay: Duration(milliseconds: 200),
                            child: _buildInfoCard(
                              context,
                              title: 'Location',
                              icon: Iconsax.location,
                              items: [
                                if (profile.address != null &&
                                    profile.address!.isNotEmpty)
                                  _item(
                                    Iconsax.map,
                                    'Address',
                                    profile.address!,
                                  ),
                                _item(Iconsax.buildings, 'City', profile.city!),
                                _item(Iconsax.map_1, 'State', profile.state!),
                                // ✅ Removed: Zip Code (not in real data)
                              ],
                            ),
                          ),
                          SizedBox(height: 16),

                          // Account Card
                          FadeInUp(
                            duration: Duration(milliseconds: 900),
                            delay: Duration(milliseconds: 300),
                            child: _buildInfoCard(
                              context,
                              title: 'Account Details',
                              icon: Iconsax.wallet,
                              items: [
                                _item(
                                  Iconsax.card,
                                  'Account ID',
                                  profile.accountId.toString(),
                                ),
                                _item(
                                  Iconsax.status,
                                  'Account Type',
                                  profile.accountType!,
                                ),
                                // ✅ Removed: Website (not in real data)
                              ],
                            ),
                          ),
                          // SizedBox(height: 30),
                          // TextButton(
                          //   onPressed: controller.showRelocationSheet,
                          //   child: Text(
                          //     "Relocation Request",
                          //     style: AppText.bodySmall,
                          //   ),
                          // ),
                          // Inside the Column in Obx builder (after Account Card)
                          SizedBox(height: 16),

                          // Relocation Status Section
                          Obx(() {
                            if (controller.isRelocationLoading.value &&
                                controller.relocationStatus.value == null) {
                              return _buildRelocationShimmer();
                            }
                            final relocation =
                                controller.relocationStatus.value;
                            if (relocation != null) {
                              return _buildRelocationStatusCard(relocation);
                            } else {
                              return Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Iconsax.transaction_minus,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Relocation Request',
                                          style: AppText.headingSmall,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No active relocation request',
                                      style: AppText.bodyMedium,
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: controller.showRelocationSheet,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary
                                            .withOpacity(0.1),
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: Text('Request Relocation'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }),
                          // SizedBox(height: 30),
                          // Add Disconnection & Delete Buttons
                          SizedBox(height: 16),
                          // Disconnection Request Button
                          // Inside ProfileScreen → Obx builder → after relocation section
                          SizedBox(height: 16),
                          // ✅ BEAUTIFUL ACTION BUTTONS
                          // Container(
                          //   width: double.infinity,
                          //   height: 60,
                          //   margin: EdgeInsets.symmetric(
                          //     horizontal: 20,
                          //     vertical: 8,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     gradient: LinearGradient(
                          //       colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          //       begin: Alignment.topLeft,
                          //       end: Alignment.bottomRight,
                          //     ),
                          //     borderRadius: BorderRadius.circular(15),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: Color(0xFFFF9800).withOpacity(0.3),
                          //         blurRadius: 15,
                          //         offset: Offset(0, 6),
                          //       ),
                          //     ],
                          //   ),
                          //   child: ElevatedButton(
                          //     onPressed: controller.showDisconnectionSheet,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.transparent,
                          //       shadowColor: Colors.transparent,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(15),
                          //       ),
                          //     ),
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Icon(
                          //           Iconsax.close_circle,
                          //           color: Colors.white,
                          //           size: 22,
                          //         ),
                          //         SizedBox(width: 10),
                          //         Text(
                          //           'Request Disconnection',
                          //           style: AppText.headingMedium.copyWith(
                          //             color: AppColors.backgroundLight,
                          //             fontSize: 14.sp,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          // Container(
                          //   width: double.infinity,
                          //   height: 60,
                          //   margin: EdgeInsets.symmetric(
                          //     horizontal: 20,
                          //     vertical: 8,
                          //   ),
                          //   decoration: BoxDecoration(
                          //     gradient: LinearGradient(
                          //       colors: [Color(0xFFFF5252), Color(0xFFD32F2F)],
                          //       begin: Alignment.topLeft,
                          //       end: Alignment.bottomRight,
                          //     ),
                          //     borderRadius: BorderRadius.circular(15),
                          //     boxShadow: [
                          //       BoxShadow(
                          //         color: Color(0xFFFF5252).withOpacity(0.3),
                          //         blurRadius: 15,
                          //         offset: Offset(0, 6),
                          //       ),
                          //     ],
                          //   ),
                          //   child: ElevatedButton(
                          //     onPressed: controller.showDeleteAccountDialog,
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.transparent,
                          //       shadowColor: Colors.transparent,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(15),
                          //       ),
                          //     ),
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: [
                          //         Icon(
                          //           Iconsax.profile_delete,
                          //           color: Colors.white,
                          //           size: 22,
                          //         ),
                          //         SizedBox(width: 10),
                          //         Text(
                          //           'Delete Account',
                          //           style: AppText.headingMedium.copyWith(
                          //             fontSize: 14.sp,
                          //             color: AppColors.backgroundLight,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          SizedBox(height: 60),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Edit FAB
          Positioned(
            bottom: 30,
            right: 20,
            child: FadeInUp(
              duration: Duration(milliseconds: 1000),
              child: FloatingActionButton.extended(
                onPressed: () => Get.to(() => EditProfileScreen()),
                backgroundColor: AppColors.primary,
                icon: Icon(Iconsax.edit_2, color: Colors.white, size: 22),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> items,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: AppText.headingSmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(
            color: AppColors.dividerColor.withOpacity(0.5),
            height: 1,
            thickness: 1,
          ),
          SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textColorSecondary.withOpacity(0.7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textColorSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textColorPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 80, height: 12, color: Colors.white),
                      SizedBox(height: 8),
                      Container(width: 150, height: 16, color: Colors.white),
                    ],
                  ),
                ),
                Container(width: 40, height: 40, color: Colors.white),
              ],
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: List.generate(
                    3, // Reduced from 4 → no zip/website/company
                    (_) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(width: 20, height: 20, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 6),
                                Container(
                                  width: 150,
                                  height: 14,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelocationStatusCard(Map<String, dynamic> data) {
    Color statusColor;
    String statusText;
    switch (data['status']?.toString().toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusText = 'Completed';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusText = 'Rejected';
        break;
      case 'pending':
      default:
        statusColor = AppColors.warning;
        statusText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.transaction_minus,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Relocation Request',
                style: AppText.headingSmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: AppText.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: AppColors.dividerColor.withOpacity(0.5), height: 1),
          SizedBox(height: 16),
          _item(Iconsax.location, 'Old Address', data['old_address'] ?? 'N/A'),
          _item(Iconsax.location, 'New Address', data['new_address'] ?? 'N/A'),
          _item(Iconsax.ticket, 'Ticket No', data['ticket_no'] ?? 'N/A'),
          _item(
            Iconsax.calendar,
            'Preferred Date',
            data['preferred_shift_date'] ?? 'N/A',
          ),
          if (data['remark'] != null)
            _item(Iconsax.note, 'Remark', data['remark']),
          _item(Iconsax.money, 'Charges', '₹${data['charges']}'),
        ],
      ),
    );
  }

  Widget _buildRelocationShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 20, height: 20, color: Colors.white),
                SizedBox(width: 12),
                Container(width: 150, height: 16, color: Colors.white),
              ],
            ),
            SizedBox(height: 16),
            ...List.generate(
              5,
              (_) => Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(width: 20, height: 20, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 80, height: 10, color: Colors.white),
                          SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends GetView<ProfileController> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Column(
            children: [
              // App Bar
              MyAppBar(title: 'Edit Profile'),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.all(20),
                      children: [
                        // Profile Image Upload
                        Center(
                          child: FadeIn(
                            duration: Duration(milliseconds: 500),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage:
                                        controller
                                                    .customerProfile
                                                    .value!
                                                    .profilePhoto ==
                                                null
                                            ? FileImage(
                                              controller.profileImage!.value,
                                            )
                                            : NetworkImage(
                                              controller
                                                  .customerProfile
                                                  .value!
                                                  .fullProfileImageUrl!,
                                            ),
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    child:
                                        controller
                                                    .customerProfile
                                                    .value!
                                                    .profilePhoto ==
                                                null
                                            ? Icon(
                                              Iconsax.user,
                                              size: 50,
                                              color: AppColors.primary,
                                            )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: controller.pickProfileImage,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Iconsax.camera,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Edit Fields
                        FadeInUp(
                          duration: Duration(milliseconds: 600),
                          child: Text(
                            'Personal Information',
                            style: AppText.headingMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        FadeInUp(
                          duration: Duration(milliseconds: 700),
                          child: AppTextField(
                            controller: controller.contactNameController,
                            labelText: 'Full Name',
                            prefixIcon: Icon(
                              Iconsax.user,
                              color: AppColors.primary,
                            ),
                            keyboardType: null,
                          ),
                        ),
                        SizedBox(height: 12),

                        FadeInUp(
                          duration: Duration(milliseconds: 800),
                          child: AppTextField(
                            controller: controller.mobileController,
                            labelText: 'Mobile',
                            prefixIcon: Icon(
                              Iconsax.call,
                              color: AppColors.primary,
                            ),
                            keyboardType: TextInputType.phone,
                            isEnabled:
                                false, // Usually can't change primary mobile
                          ),
                        ),
                        SizedBox(height: 12),

                        FadeInUp(
                          duration: Duration(milliseconds: 900),
                          child: AppTextField(
                            controller: controller.emailController,
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Iconsax.sms,
                              color: AppColors.primary,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        SizedBox(height: 24),

                        FadeInUp(
                          duration: Duration(milliseconds: 1000),
                          child: Text(
                            'Address',
                            style: AppText.headingMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        FadeInUp(
                          duration: Duration(milliseconds: 1050),
                          child: AppTextField(
                            controller: controller.addressController,
                            labelText: 'Address',
                            prefixIcon: Icon(
                              Iconsax.map,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),

                        FadeInUp(
                          duration: Duration(milliseconds: 1100),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: controller.cityController,
                                  labelText: 'City',
                                  prefixIcon: Icon(
                                    Iconsax.buildings,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  controller: controller.stateController,
                                  labelText: 'State',
                                  prefixIcon: Icon(
                                    Iconsax.map_1,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Removed: Zip Code field
                        SizedBox(height: 40),

                        FadeInUp(
                          duration: Duration(milliseconds: 1200),
                          child: SizedBox(
                            height: 50,
                            child: Obx(
                              () => ElevatedButton(
                                onPressed:
                                    controller.isUpdating.value ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppColors.primary.withOpacity(
                                    0.3,
                                  ),
                                ),
                                child:
                                    controller.isUpdating.value
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Iconsax.tick_circle, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'SAVE CHANGES',
                                              style: AppText.button.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      controller.updateProfile();
    }
  }
}

// lib/src/customer/core/controllers/relocation_controller.dart
class RelocationRequestController extends GetxController {
  final ApiServices _api = ApiServices();

  final customerId = ''.obs;
  final customerName = ''.obs;
  final mobileNo = ''.obs;
  final emailId = ''.obs;
  final planPeriod = 'MONTHLY'.obs;
  final oldAddress = ''.obs;
  final newAddress = ''.obs;
  final serviceNo = ''.obs;
  final subscribePlan = ''.obs;
  final billingAddress = ''.obs;
  final preferredShiftDate = ''.obs;
  final relocationType =
      'Within City'.obs; // Within City, Within State, Inter-State
  final ssaCode = ''.obs;
  final charges = 250.obs;

  final isSubmitting = false.obs;

  @override
  void onInit() {
    // Prefill from shared pref or customer data if available
    mobileNo.value = AppSharedPref.instance.getMobileNumber() ?? '';
    // You can fetch customer details here if needed
    super.onInit();
  }

  Future<void> submitRequest() async {
    if (isSubmitting.value) return;

    if (newAddress.value.isEmpty) {
      BaseApiService().showSnackbar('Error', 'New address is required');
      return;
    }
    if (preferredShiftDate.value.isEmpty) {
      BaseApiService().showSnackbar(
        'Error',
        'Preferred shift date is required',
      );
      return;
    }

    isSubmitting(true);

    final body = {
      "customer_id": customerId.value,
      "customer_name": customerName.value,
      "mobile_no": mobileNo.value,
      "email_id": emailId.value,
      "plan_period": planPeriod.value,
      "old_address": oldAddress.value,
      "new_address": newAddress.value,
      "service_no": serviceNo.value,
      "subscribe_plan": subscribePlan.value,
      "billing_address": billingAddress.value,
      "preferred_shift_date": preferredShiftDate.value,
      "relocation_type": relocationType.value,
      "ssa_code": ssaCode.value,
      "charges": charges.value,
    };

    try {
      final result = await _api.submitRelocationRequest(body);
      if (result != null) {
        Get.back(); // Close bottom sheet
        BaseApiService().showSnackbar(
          'Success',
          'Relocation request submitted!\nTicket: ${result['data']['ticket_no']}',
        );
      }
    } finally {
      isSubmitting(false);
    }
  }

  void selectDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
    );
    if (picked != null) {
      preferredShiftDate.value =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void selectRelocationType(String type) {
    relocationType.value = type;
  }
}

// lib/src/customer/ui/widgets/relocation_bottom_sheet.dart
class RelocationRequestBottomSheet extends StatelessWidget {
  final RelocationRequestController controller = Get.put(
    RelocationRequestController(),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24.h,
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.dividerColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Relocation Request',
            style: AppText.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Move your connection to a new address',
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 24.h),

          // New Address
          _buildTextField(
            label: 'New Address *',
            hint: 'Enter new full address',
            controller:
                TextEditingController()..text = controller.newAddress.value,
            onChanged: (v) => controller.newAddress.value = v,
            maxLines: 2,
          ),
          SizedBox(height: 16.h),

          // Preferred Shift Date
          Obx(
            () => _buildDateField(
              label: 'Preferred Shift Date *',
              date: controller.preferredShiftDate.value,
              onTap: controller.selectDate,
            ),
          ),
          SizedBox(height: 16.h),

          // Relocation Type
          Obx(
            () => _buildDropdownField(
              label: 'Relocation Type',
              value: controller.relocationType.value,
              items: ['Within City', 'Within State', 'Inter-State'],
              onChanged: controller.selectRelocationType,
            ),
          ),
          SizedBox(height: 16.h),

          // Optional Fields (you can expand as needed)
          _buildTextField(
            label: 'SSA Code',
            hint: 'e.g., BLRXXXXXXX',
            controller:
                TextEditingController()..text = controller.serviceNo.value,
            onChanged: (v) => controller.serviceNo.value = v,
          ),
          SizedBox(height: 16.h),

          // Charges Info
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'A relocation charge of ₹${controller.charges.value} will be applied.',
                    style: AppText.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Submit Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    controller.isSubmitting.value
                        ? null
                        : controller.submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 5,
                ),
                child:
                    controller.isSubmitting.value
                        ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : Text(
                          'Submit Request',
                          style: AppText.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.bodyMedium.copyWith(
              color: AppColors.textColorHint,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date.isEmpty ? 'Select date' : date,
                  style: AppText.bodyMedium.copyWith(
                    color:
                        date.isEmpty
                            ? AppColors.textColorHint
                            : AppColors.textColorPrimary,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items:
                  items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item, style: AppText.bodyMedium),
                    );
                  }).toList(),
              onChanged: (val) {
                onChanged(val.toString());
              },
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: AppText.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
