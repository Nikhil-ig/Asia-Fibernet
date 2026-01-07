// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asia_fibernet/src/customer/ui/widgets/relocation_bottom_sheet.dart';
import 'package:asia_fibernet/src/services/apis/api_services.dart';
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:asia_fibernet/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class SettingsController extends GetxController {
  final ApiServices _apiServices = Get.find<ApiServices>();
  final BaseApiService _baseAPIServices = Get.find<BaseApiService>();

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
    TextEditingController deleteText = TextEditingController();
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
              SingleChildScrollView(
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
                              controller: deleteText,
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
                                  fontSize: 12.sp,
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
                                if (deleteText.value.text == "DELETE") {
                                  deleteCustomerAccount();
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
                                    Iconsax.profile_delete,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'DELETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
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

  deleteCustomerAccount() async {
    final deleted = await _apiServices.deleteCustomerAccount();
    if (deleted) {
      // Clear local data and navigate to login
      await AppSharedPref.instance.clearAllUserData();
      Get.offAllNamed(AppRoutes.login);
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

  void showSwitchAccountBottomSheet() {
    // TODO: Implement switch account bottom sheet
  }
}
