// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:asia_fibernet/src/services/apis/api_services.dart';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:asia_fibernet/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../auth/core/model/customer_details_model.dart';
import '../../../services/apis/base_api_service.dart';

// lib/src/customer/core/controllers/relocation_controller.dart
class RelocationRequestController extends GetxController {
  final ApiServices _api = ApiServices();
  CustomerDetails? _cust = CustomerDetails();
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
  void onInit() async {
    // Prefill from shared pref or customer data if available
    mobileNo.value = AppSharedPref.instance.getMobileNumber() ?? '';
    _cust = await _api.fetchCustomer();
    // You can fetch customer details here if needed
    super.onInit();
  }

  Future<void> submitRequest() async {
    if (isSubmitting.value) return;
    if (newAddress.value.isEmpty) {
      BaseApiService().showSnackbar(
        'Error',
        'New address is required',
        isError: true,
      );
      return;
    }
    if (preferredShiftDate.value.isEmpty) {
      BaseApiService().showSnackbar(
        'Error',
        'Preferred shift date is required',
        isError: true,
      );
      return;
    }
    isSubmitting(true);
    final body = {
      "customer_id": customerId.value,
      "customer_name": _cust!.companyName, //customerName.value,
      "mobile_no": mobileNo.value,
      "email_id": _cust!.email, //emailId.value,
      "plan_period": _cust!.planPeriod, //planPeriod.value,
      "old_address": _cust!.address, //oldAddress.value,
      "new_address": newAddress.value,
      "service_no": serviceNo.value,
      "subscribe_plan": _cust!.subscriptionPlan, //subscribePlan.value,
      "billing_address": billingAddress.value,
      "preferred_shift_date": preferredShiftDate.value,
      "relocation_type": relocationType.value,
      "ssa_code": ssaCode.value,
      "charges": charges.value,
    };
    try {
      final result = await _api.submitRelocationRequest(body);
      if (result != null) {
        Navigator.pop(Get.context!); // Close bottom sheet
        BaseApiService().showSnackbar(
          'Success',
          'Relocation request submitted!\nTicket: ${result['data']['ticket_no']}',
        );
        dispose();
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
      child: SafeArea(
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
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'A relocation charge of ₹${controller.charges.value} will be applied.',
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
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
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
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
