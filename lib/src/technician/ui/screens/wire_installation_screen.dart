import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';

class WireInstallationSubmissionModel {
  String wireType;
  String wireLength;
  String installedAt;
  String remarks;
  String noOfPoints;
  String routeOfCables;
  String existingWiring;
  String accountNo;
  List<String> photos;
  String technicianName;
  String technicianId;

  WireInstallationSubmissionModel({
    required this.wireType,
    required this.wireLength,
    required this.installedAt,
    required this.remarks,
    required this.noOfPoints,
    required this.routeOfCables,
    required this.existingWiring,
    required this.accountNo,
    required this.photos,
    required this.technicianName,
    required this.technicianId,
  });

  Map<String, dynamic> toJson() {
    return {
      'wire_type': wireType,
      'wire_length': wireLength,
      'installed_at': installedAt,
      'remarks': remarks,
      'no_of_points': noOfPoints,
      'route_of_cables': routeOfCables,
      'existing_wiring': existingWiring,
      'account_no': accountNo,
      'photos': photos,
      'technician_name': technicianName,
      'technician_id': technicianId,
    };
  }
}

// --- CONTROLLER ---
class WireInstallationSubmissionController extends GetxController {
  final Rx<WireInstallationSubmissionModel> formData =
      Rx<WireInstallationSubmissionModel>(
        WireInstallationSubmissionModel(
          wireType: 'Fiber',
          wireLength: '',
          installedAt: '',
          remarks: '',
          noOfPoints: '1',
          routeOfCables: 'Ceiling',
          existingWiring: 'No',
          accountNo: '',
          photos: [],
          technicianName: '',
          technicianId: '',
        ),
      );

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final ImagePicker _picker = ImagePicker();
  final RxList<XFile> selectedImages = <XFile>[].obs;

  // Form validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadTechnicianInfo();
  }

  void _loadTechnicianInfo() {
    // Load technician info from shared preferences or API
    formData.update((val) {
      val?.technicianName = 'John Technician'; // Replace with actual data
      val?.technicianId = 'TECH001'; // Replace with actual data
    });
  }

  // Wire Type Options
  final List<String> wireTypes = ['Fiber', 'Copper', 'Ethernet', 'Coaxial'];
  final List<String> routeOptions = [
    'Ceiling',
    'Wall',
    'Underground',
    'Pole',
    'Mixed',
  ];
  final List<String> existingWiringOptions = ['Yes', 'No', 'Partial'];
  final List<String> pointOptions = ['1', '2', '3', '4', '5+'];

  void updateWireType(String value) {
    formData.update((val) {
      val?.wireType = value;
    });
  }

  void updateRouteOfCables(String value) {
    formData.update((val) {
      val?.routeOfCables = value;
    });
  }

  void updateExistingWiring(String value) {
    formData.update((val) {
      val?.existingWiring = value;
    });
  }

  void updateNoOfPoints(String value) {
    formData.update((val) {
      val?.noOfPoints = value;
    });
  }

  Future<void> pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        selectedImages.addAll(images);
        // Convert to base64 or upload to server
        formData.update((val) {
          val?.photos.addAll(images.map((e) => e.path).toList());
        });
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        'Error',
        'Failed to pick images: $e',
        isError: true,
      );
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (photo != null) {
        selectedImages.add(photo);
        formData.update((val) {
          val?.photos.add(photo.path);
        });
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        'Error',
        'Failed to take photo: $e',
        isError: true,
      );
    }
  }

  void removeImage(int index) {
    if (index < selectedImages.length) {
      selectedImages.removeAt(index);
      formData.update((val) {
        if (index < val!.photos.length) {
          val.photos.removeAt(index);
        }
      });
    }
  }

  Future<void> submitInstallation() async {
    if (!formKey.currentState!.validate()) {
      BaseApiService().showSnackbar(
        'Validation Error',
        'Please fill all required fields',
        isError: true,
      );
      return;
    }

    if (selectedImages.isEmpty) {
      BaseApiService().showSnackbar(
        'Photos Required',
        'Please add at least one installation photo',
        isError: true,
      );
      return;
    }

    try {
      isSubmitting(true);

      // Simulate API call - replace with actual submission
      await Future.delayed(Duration(seconds: 2));

      // Here you would call your actual API
      // await _apiService.submitWireInstallation(formData.value.toJson());

      Get.offAllNamed('/installation-success');

      BaseApiService().showSnackbar(
        'Success',
        'Installation details submitted successfully',
      );
    } catch (e) {
      BaseApiService().showSnackbar(
        'Submission Failed',
        'Failed to submit installation details: $e',
        isError: true,
      );
    } finally {
      isSubmitting(false);
    }
  }

  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? validateWireLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter wire length';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? validateAccountNo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter account number';
    }
    if (value.length < 5) {
      return 'Account number seems too short';
    }
    return null;
  }
}

// --- MAIN SCREEN ---
class WireInstallationSubmissionScreen extends StatelessWidget {
  final WireInstallationSubmissionController controller = Get.put(
    WireInstallationSubmissionController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: 100.h,
                ), // Space for submit button
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),

                      // Installation Details Card
                      _buildInstallationDetailsCard(),

                      SizedBox(height: 20.h),

                      // Technical Specifications Card
                      _buildTechnicalSpecsCard(),

                      SizedBox(height: 20.h),

                      // Photos Section
                      _buildPhotosSection(),

                      SizedBox(height: 20.h),

                      // Remarks Section
                      _buildRemarksSection(),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Submit Button
      bottomSheet: _buildSubmitButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wire Installation Report',
                  style: AppText.headingMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Obx(
                  () => Text(
                    'Technician: ${controller.formData.value.technicianName}',
                    style: AppText.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationDetailsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.build_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Installation Details',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Account Number
            _buildTextField(
              label: 'Account Number *',
              hintText: 'Enter customer account number',
              onChanged:
                  (value) => controller.formData.update(
                    (val) => val?.accountNo = value,
                  ),
              validator: (value) => controller.validateAccountNo(value),
              icon: Icons.credit_card_rounded,
            ),

            SizedBox(height: 16.h),

            // Wire Length
            _buildTextField(
              label: 'Wire Length (meters) *',
              hintText: 'e.g., 123.00',
              keyboardType: TextInputType.number,
              onChanged:
                  (value) => controller.formData.update(
                    (val) => val?.wireLength = value,
                  ),
              validator: (value) => controller.validateWireLength(value),
              icon: Icons.straighten_rounded,
            ),

            SizedBox(height: 16.h),

            // Installation Date & Time
            _buildDateTimeField(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSpecsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFF), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15.r,
              spreadRadius: 1.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.engineering_rounded,
                    color: AppColors.info,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Technical Specifications',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Wire Type
            _buildDropdownField(
              label: 'Wire Type *',
              value: controller.formData.value.wireType,
              items: controller.wireTypes,
              onChanged: controller.updateWireType,
              icon: Icons.cable_rounded,
            ),

            SizedBox(height: 16.h),

            // Route of Cables
            _buildDropdownField(
              label: 'Cable Route *',
              value: controller.formData.value.routeOfCables,
              items: controller.routeOptions,
              onChanged: controller.updateRouteOfCables,
              icon: Icons.route_rounded,
            ),

            SizedBox(height: 16.h),

            // Number of Points
            _buildDropdownField(
              label: 'Connection Points *',
              value: controller.formData.value.noOfPoints,
              items: controller.pointOptions,
              onChanged: controller.updateNoOfPoints,
              icon: Icons.point_of_sale_rounded,
            ),

            SizedBox(height: 16.h),

            // Existing Wiring
            _buildDropdownField(
              label: 'Existing Wiring *',
              value: controller.formData.value.existingWiring,
              items: controller.existingWiringOptions,
              onChanged: controller.updateExistingWiring,
              icon: Icons.electrical_services_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: AppColors.success,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Installation Photos',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Add photos of the installation work',
              style: AppText.bodySmall.copyWith(
                color: AppColors.textColorSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            Obx(
              () =>
                  controller.selectedImages.isEmpty
                      ? _buildEmptyPhotosState()
                      : _buildPhotosGrid(),
            ),

            SizedBox(height: 16.h),

            // Photo Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    icon: Icon(Icons.photo_library_rounded, size: 18.sp),
                    label: Text('Gallery'),
                  ),
                ),
                SizedBox(width: 12.w),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.takePhoto,
                    autofocus: true,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      size: 18.sp,
                      color: AppColors.backgroundLight,
                    ),
                    label: Text('Take Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhotosState() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.dividerColor.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_rounded,
            size: 32.sp,
            color: AppColors.textColorHint,
          ),
          SizedBox(height: 8.h),
          Text(
            'No photos added',
            style: AppText.bodyMedium.copyWith(color: AppColors.textColorHint),
          ),
          Text(
            'Add installation photos',
            style: AppText.bodySmall.copyWith(color: AppColors.textColorHint),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Obx(
      () => Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        children:
            controller.selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;

              return Stack(
                children: [
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      image: DecorationImage(
                        image: FileImage(File(image.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4.w,
                    right: 4.w,
                    child: GestureDetector(
                      onTap: () => controller.removeImage(index),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 12.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20.r,
              spreadRadius: 2.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.note_rounded,
                    color: AppColors.warning,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Remarks & Notes',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            TextFormField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Add any remarks, issues, or special notes about the installation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.all(16.w),
              ),
              onChanged:
                  (value) =>
                      controller.formData.update((val) => val?.remarks = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Obx(
        () => ElevatedButton(
          onPressed:
              controller.isSubmitting.value
                  ? null
                  : controller.submitInstallation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            minimumSize: Size(double.infinity, 50.h),
          ),
          child:
              controller.isSubmitting.value
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Submitting...',
                        style: AppText.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Submit Installation Report',
                        style: AppText.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 20.sp) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.dividerColor),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            icon: Icon(Icons.arrow_drop_down_rounded, size: 24.sp),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, size: 20.sp) : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
            ),
            items:
                items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: AppText.bodyMedium),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installation Date & Time *',
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _showDateTimePicker(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dividerColor),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 12.w),
                Obx(
                  () => Text(
                    controller.formData.value.installedAt.isEmpty
                        ? 'Select date and time'
                        : controller.formData.value.installedAt,
                    style: AppText.bodyMedium.copyWith(
                      color:
                          controller.formData.value.installedAt.isEmpty
                              ? AppColors.textColorHint
                              : AppColors.textColorPrimary,
                    ),
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down_rounded, size: 24.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDateTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: Get.context!,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        controller.formData.update((val) {
          val?.installedAt = finalDateTime.toString();
        });
      }
    }
  }
}

// Add this import for File
