// screens/technician_profile_screen.dart

import 'dart:convert';
import 'dart:typed_data' show Uint8List;
import 'dart:io';

import 'package:asia_fibernet/src/services/apis/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asia_fibernet/src/utils/safe_navigation.dart';
import 'package:animate_do/animate_do.dart';
import '../../../auth/core/controller/binding/login_binding.dart';
import '../../../auth/ui/login_screen.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../services/sharedpref.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../core/models/technician_profile_model.dart';

// controllers/technician_profile_controller.dart

class TechnicianProfileController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  // ✅ Use unified model
  final technicianProfile = Rx<TechnicianProfileModel?>(null);
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUnifiedProfile();
  }

  Future<void> loadUnifiedProfile() async {
    isLoading.value = true;
    try {
      final profile = await _api.fetchUnifiedProfile();
      technicianProfile.value = profile;
    } finally {
      isLoading.value = false;
    }
  }

  void logOut() {
    AppSharedPref.instance.clearAllUserData();
    Get.offAll(() => LoginScreen(), binding: LoginBinding());
  }
}

// screens/technician_profile_screen.dart
class TechnicianProfileScreen extends StatelessWidget {
  TechnicianProfileScreen({super.key});
  final controller = Get.put(TechnicianProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: AppText.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundLight,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.backgroundLight),
        actions: [
          SlideInRight(
            duration: Duration(milliseconds: 500),
            child: IconButton(
              icon: Icon(Iconsax.logout, size: 22),
              onPressed: () {
                ApiServices().logOutDialog();
              },
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingScreen();
        }

        final profile = controller.technicianProfile.value;
        if (profile == null) {
          return _buildErrorScreen();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(profile),
              SizedBox(height: 24.h),
              // Personal Info Card
              _buildPersonalInfoCard(profile),
              SizedBox(height: 24.h),
              // KYC Details Card
              _buildKycDetailsCard(profile),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20.h),
          Text("Loading your profile...", style: AppText.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 48.w, color: AppColors.error),
          SizedBox(height: 12.h),
          Text(
            "Failed to load profile.",
            style: AppText.bodyLarge.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: controller.loadUnifiedProfile,
            icon: Icon(Icons.refresh, size: 18.w),
            label: Text("Retry", style: AppText.button),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Inside TechnicianProfileScreen class in screens/technician_profile_screen.dart

  Widget _buildProfileHeader(TechnicianProfileModel profile) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProfilePhoto(profile.profilePhoto),
          SizedBox(width: 16.w),
          Expanded(
            // Wrap the column in Expanded
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.contactName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile.email ?? "N/A",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Add Edit Button
          IconButton(
            icon: Icon(Iconsax.edit, color: Colors.white, size: 24.w),
            onPressed: () {
              Get.to(() => TechnicianProfileEditScreen(), arguments: profile);
            },
            tooltip: "Edit Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return Container(
        width: 70.w,
        height: 70.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.grey[300],
        ),
        child: Icon(Iconsax.user, size: 36.w, color: Colors.white),
      );
    }

    try {
      // ✅ API returns file path like "uploads/profile/profile_1769516848.jpg"
      // Construct full URL: https://asiafibernet.in/af/api/{photoPath}
      final String imageUrl = '$photoPath';

      return Container(
        width: 70.w,
        height: 70.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {
              debugPrint(
                "Profile Photo Error: $error \nstackTrace: $stackTrace",
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error loading profile photo: $e");
      return Container(
        width: 70.w,
        height: 70.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.grey[300],
        ),
        child: Icon(Iconsax.user, size: 36.w, color: Colors.white),
      );
    }
  }

  Widget _buildPersonalInfoCard(TechnicianProfileModel profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personal Information",
              style: AppText.headingSmall.copyWith(
                color: AppColors.textColorPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            // _buildInfoRow(Iconsax.profile, "Company", profile.companyName),
            _buildInfoRow(Iconsax.building, "Address", profile.address),
            _buildInfoRow(Iconsax.location, "City", profile.city),
            _buildInfoRow(Iconsax.global, "State", profile.state),
            _buildInfoRow(
              Iconsax.call,
              "Work Phone",
              profile.workPhoneNumber?.toString(),
            ),
            _buildInfoRow(
              Iconsax.call,
              "Mobile",
              profile.cellPhoneNumber?.toString(),
            ),
            _buildInfoRow(Iconsax.message, "Email", profile.email),
            // _buildInfoRow(Iconsax.link, "Website", profile.websiteAddress),
            _buildInfoRow(Iconsax.calendar, "Joined On", profile.creationDate),
          ],
        ),
      ),
    );
  }

  Widget _buildKycDetailsCard(TechnicianProfileModel profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.document_text,
                  size: 24.w,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  "KYC Details",
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.textColorPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow(
              Iconsax.security_card,
              "Technician Name",
              profile.technicianName,
            ),
            _buildInfoRow(
              Iconsax.security_card,
              "Aadhaar No.",
              profile.aadharcardNo,
            ),
            _buildInfoRow(Iconsax.security_card, "PAN No.", profile.pancardNo),
            SizedBox(height: 20.h),
            // Aadhaar Images
            if (profile.aadharFront != null || profile.aadharBack != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aadhaar Images",
                    style: AppText.labelMedium.copyWith(
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (profile.aadharFront != null)
                    _buildImagePreview(profile.aadharFront!, "Aadhaar Front"),
                  if (profile.aadharBack != null)
                    _buildImagePreview(profile.aadharBack!, "Aadhaar Back"),
                  SizedBox(height: 20.h),
                ],
              ),
            Text(
              "Bank Details",
              style: AppText.labelLarge.copyWith(
                color: AppColors.textColorPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            _buildInfoRow(Iconsax.bank, "Bank Name", profile.bankName),
            _buildInfoRow(Iconsax.bank, "Branch", profile.branchName),
            _buildInfoRow(Iconsax.document_code, "IFSC Code", profile.ifscCode),
            _buildInfoRow(Iconsax.wallet, "Account No.", profile.accountNo),
            SizedBox(height: 20.h),
            _buildInfoRow(
              Iconsax.calendar,
              "Date of Birth",
              profile.dateOfBirth,
            ),
            _buildInfoRow(
              Iconsax.calendar,
              "Date of Joining",
              profile.dateOfJoining,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String base64Image, String label) {
    try {
      final String cleanBase64 = base64Image.split(',').last;
      final bytes = base64Decode(cleanBase64);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dividerColor, width: 1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
          SizedBox(height: 12.h),
        ],
      );
    } catch (e) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: AppColors.error, size: 24.w),
                  SizedBox(height: 4.h),
                  Text(
                    "Invalid Image",
                    style: AppText.labelSmall.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.w, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value?.toString() ?? "Not Provided",
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// controllers/technician_profile_edit_controller.dart

class TechnicianProfileEditController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();
  final ImagePicker _picker = ImagePicker();

  // Reactive variables for form fields
  final contactName = ''.obs;
  final companyName = ''.obs;
  final address = ''.obs;
  final city = ''.obs;
  final state = ''.obs;
  final workPhoneNumber = ''.obs;
  final cellPhoneNumber = ''.obs;
  final email = ''.obs;
  final websiteAddress = ''.obs;
  final technicianName = ''.obs;
  final aadharcardNo = ''.obs;
  final pancardNo = ''.obs;
  final bankName = ''.obs;
  final branchName = ''.obs;
  final ifscCode = ''.obs;
  final accountNo = ''.obs;
  final dateOfBirth = ''.obs;
  final dateOfJoining = ''.obs;

  // ✅ TextEditingControllers for proper text input handling
  final TextEditingController addressController = TextEditingController();
  final TextEditingController workPhoneNumberController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController ifscCodeController = TextEditingController();
  final TextEditingController accountNoController = TextEditingController();

  // Reactive variables for images
  final profilePhoto = Rx<Uint8List?>(null);
  final aadharFront = Rx<Uint8List?>(null);
  final aadharBack = Rx<Uint8List?>(null);

  // Loading state
  final isSaving = false.obs;

  // Original profile data (for comparison or reset)
  TechnicianProfileModel? originalProfile;

  @override
  void onInit() {
    super.onInit();
    // Get the profile passed from the previous screen
    final args = Get.arguments;
    if (args is TechnicianProfileModel) {
      originalProfile = args;
      _loadInitialData(args);
    }
  }

  @override
  void onClose() {
    // ✅ Dispose controllers to prevent memory leaks
    addressController.dispose();
    workPhoneNumberController.dispose();
    emailController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    ifscCodeController.dispose();
    accountNoController.dispose();
    super.onClose();
  }

  void _loadInitialData(TechnicianProfileModel profile) {
    // ✅ Load all profile data into observable variables (handle null values)
    contactName.value = profile.contactName;
    companyName.value = profile.companyName;
    address.value = profile.address ?? '';
    city.value = profile.city ?? '';
    state.value = profile.state ?? '';
    workPhoneNumber.value = profile.workPhoneNumber?.toString() ?? '';
    cellPhoneNumber.value = profile.cellPhoneNumber?.toString() ?? '';
    email.value = profile.email ?? '';
    websiteAddress.value = profile.websiteAddress ?? '';
    technicianName.value = profile.technicianName ?? '';
    aadharcardNo.value = profile.aadharcardNo ?? '';
    pancardNo.value = profile.pancardNo ?? '';
    bankName.value = profile.bankName ?? '';
    branchName.value = profile.branchName ?? '';
    ifscCode.value = profile.ifscCode ?? '';
    accountNo.value = profile.accountNo ?? '';
    dateOfBirth.value = profile.dateOfBirth ?? '';
    dateOfJoining.value = profile.dateOfJoining ?? '';

    // ✅ Set TextEditingController values from profile
    addressController.text = address.value;
    workPhoneNumberController.text = workPhoneNumber.value;
    emailController.text = email.value;
    bankNameController.text = bankName.value;
    branchNameController.text = branchName.value;
    ifscCodeController.text = ifscCode.value;
    accountNoController.text = accountNo.value;

    // Load images from base64 if available
    _loadImageFromBase64(profile.profilePhoto, profilePhoto);
    _loadImageFromBase64(profile.aadharFront, aadharFront);
    _loadImageFromBase64(profile.aadharBack, aadharBack);
  }

  void _loadImageFromBase64(String? base64String, Rx<Uint8List?> imageRx) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        final String cleanBase64 = base64String.split(',').last;
        final bytes = base64Decode(cleanBase64);
        imageRx.value = bytes;
      } catch (e) {
        print("Error decoding base64 image: $e");
        imageRx.value = null;
      }
    } else {
      imageRx.value = null;
    }
  }

  // Image picking methods
  Future<void> pickProfilePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      profilePhoto.value = bytes;
    }
  }

  Future<void> pickAadharFront() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      aadharFront.value = bytes;
    }
  }

  Future<void> pickAadharBack() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      aadharBack.value = bytes;
    }
  }

  // Convert Uint8List to base64 string for sending to API
  // Note: Profile photo is uploaded separately via ApiServices.uploadProfilePhoto()

  // Method to save the updated profile
  Future<void> saveProfile() async {
    if (isSaving.value) return; // Prevent multiple simultaneous saves

    isSaving.value = true;

    try {
      // ✅ Prepare request body (matching API: techAPI/update_my_profile_tech.php)
      final requestBody = {
        // ✅ Core profile fields (required by API)
        "Address": address.value,
        "Cellphnumber": cellPhoneNumber.value,
        "Email": email.value,

        // ✅ Bank details (required by API)
        "bank_name": bankName.value,
        "account_no": accountNo.value,
        "ifsc_code": ifscCode.value,
        "branch_name": branchName.value,

        // Optional fields that may be supported
        if (contactName.value.isNotEmpty) "contact_name": contactName.value,
        if (companyName.value.isNotEmpty) "company_name": companyName.value,
        if (state.value.isNotEmpty) "state": state.value,
        if (workPhoneNumber.value.isNotEmpty)
          "work_phone_number": workPhoneNumber.value,
        if (websiteAddress.value.isNotEmpty)
          "website_address": websiteAddress.value,
        if (technicianName.value.isNotEmpty)
          "technician_name": technicianName.value,
        if (aadharcardNo.value.isNotEmpty) "aadharcard_no": aadharcardNo.value,
        if (pancardNo.value.isNotEmpty) "pancard_no": pancardNo.value,
        if (dateOfBirth.value.isNotEmpty) "date_of_birth": dateOfBirth.value,
        if (dateOfJoining.value.isNotEmpty)
          "date_of_joining": dateOfJoining.value,

        // Don't include images in this request - upload separately
      };

      debugPrint("📤 Sending profile update request to API: $requestBody");

      // 🔌 Make API call to update profile
      final response = await _api.updateProfile(requestBody);

      if (response) {
        debugPrint("✅ Profile updated successfully!");

        // ✅ Upload profile photo separately if changed
        if (profilePhoto.value != null) {
          await _uploadProfilePhotoIfChanged();
        }

        // ✅ Fetch fresh profile data from API
        debugPrint("🔄 Fetching fresh profile data...");
        final updatedProfile = await _api.fetchUnifiedProfile();

        if (updatedProfile != null) {
          debugPrint("✅ Fresh profile data fetched successfully!");

          // ✅ Update the parent controller (TechnicianProfileController)
          final parentController = Get.find<TechnicianProfileController>();
          parentController.technicianProfile.value = updatedProfile;

          debugPrint("✅ UI refreshed with new data");

          // ✅ Show success message
          BaseApiService().showSnackbar(
            "Success",
            "Profile updated successfully!",
            isError: false,
          );

          // ✅ Navigate back using Navigator (avoid Get.back issues)
          await Future.delayed(Duration(milliseconds: 500));
          // Use safePop to avoid using Get.context! directly which may be
          // deactivated when called from async flows.
          safePop(null, true);
        } else {
          debugPrint("⚠️ Failed to fetch updated profile data");
          BaseApiService().showSnackbar(
            "Warning",
            "Profile saved but failed to refresh data",
            isError: false,
          );
          await Future.delayed(Duration(milliseconds: 500));
          safePop(null, true);
        }
      } else {
        debugPrint("❌ Profile update failed");
        BaseApiService().showSnackbar(
          "Error",
          "Failed to update profile. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving profile: $e");
      BaseApiService().showSnackbar(
        "Error",
        "An error occurred while saving the profile: $e",
        isError: true,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // Helper method to get temp directory and save profile photo
  Future<void> _uploadProfilePhotoIfChanged() async {
    if (profilePhoto.value == null) return; // No photo to upload

    try {
      debugPrint("📸 Uploading profile photo...");

      // Get application temporary directory
      final tempDir = await _getApplicationTempDirectory();
      final tempFile = File(
        '${tempDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Write bytes to temp file
      await tempFile.writeAsBytes(profilePhoto.value!);

      // Use ApiServices to upload
      final photoUploaded = await ApiServices().uploadProfilePhoto(tempFile);

      if (photoUploaded) {
        debugPrint("✅ Profile photo uploaded successfully!");
      } else {
        debugPrint("⚠️ Profile updated but photo upload failed");
        BaseApiService().showSnackbar(
          "Warning",
          "Profile updated but photo upload failed",
          isError: false,
        );
      }

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint("Could not delete temp file: $e");
      }
    } catch (e) {
      debugPrint("⚠️ Error uploading profile photo: $e");
      BaseApiService().showSnackbar(
        "Warning",
        "Photo upload failed: $e",
        isError: false,
      );
    }
  }

  // Get application temp directory
  Future<Directory> _getApplicationTempDirectory() async {
    try {
      // For Android: /data/local/tmp or app cache
      // For iOS: app documents directory
      final tempDir = Directory.systemTemp;
      return tempDir;
    } catch (e) {
      return Directory.systemTemp;
    }
  }
}

class TechnicianProfileEditScreen extends StatelessWidget {
  TechnicianProfileEditScreen({super.key});
  final controller = Get.put(TechnicianProfileEditController());

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: AppText.headingMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.backgroundLight,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.backgroundLight),
        // actions: [
        //   Obx(
        //     () => IconButton(
        //       icon: Icon(Iconsax.save_2, size: 22),
        //       onPressed:
        //           controller.isSaving.value ? null : controller.saveProfile,
        //       tooltip: "Save Profile",
        //     ),
        //   ),
        // ],
      ),
      body: Obx(() {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Photo Section
                _buildImageSection(
                  "Profile Photo",
                  controller.profilePhoto.value,
                  controller.pickProfilePhoto,
                  Iconsax.user,
                ),
                SizedBox(height: 24.h),

                // Personal Information Card
                _buildEditableCard("Personal Information", [
                  // _buildTextFormField(
                  //   label: "Contact Name",
                  //   icon: Iconsax.user,
                  //   controller: TextEditingController(
                  //     text: controller.contactName.value,
                  //   )..addListener(() {
                  //     // This context captures the controller
                  //   }),
                  //   onChanged: (value) {
                  //     controller.contactName.value = value;
                  //   },
                  //   validator:
                  //       (value) =>
                  //           value?.isEmpty ?? true
                  //               ? "Enter contact name"
                  //               : null,
                  // ),
                  _buildTextFormField(
                    label: "Address",
                    icon: Iconsax.location,
                    controller: controller.addressController,
                    onChanged: (value) {
                      controller.address.value = value;
                    },
                  ),
                  _buildTextFormField(
                    label: "Mobile Number",
                    icon: Iconsax.call,

                    // controller: TextEditingController(
                    //   text: controller.cellPhoneNumber.value,
                    // ),
                    // onChanged: (value) {
                    //     controller.cellPhoneNumber.value = value;
                    //   },
                    //   keyboardType: TextInputType.phone,
                    //   validator:
                    //       (value) =>
                    //           (value?.isEmpty ?? true)
                    //               ? "Enter mobile number"
                    //               : null,
                    // ),
                    controller: controller.workPhoneNumberController,
                    onChanged: (value) {
                      controller.workPhoneNumber.value = value;
                      controller.cellPhoneNumber.value = value;
                    },
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextFormField(
                    label: "Email",
                    icon: Iconsax.message,
                    controller: controller.emailController,
                    onChanged: (value) {
                      controller.email.value = value;
                    },
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return "Enter email";
                      }
                      if (!GetUtils.isEmail(value ?? '')) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  // _buildTextFormField(
                  //   label: "Work Phone",
                  //   icon: Iconsax.call,
                  //   controller: TextEditingController(
                  //     text: controller.workPhoneNumber.value,
                  //   ),
                  //   onChanged: (value) {
                  //     controller.workPhoneNumber.value = value;
                  //   },
                  //   keyboardType: TextInputType.phone,
                  // ),
                ]),
                SizedBox(height: 24.h),

                // Bank Details Card
                // _buildEditableCard("Bank Details", [
                //   _buildTextFormField(
                //     label: "Bank Name",
                //     icon: Iconsax.bank,
                //     controller: controller.bankNameController,
                //     onChanged: (value) {
                //       controller.bankName.value = value;
                //     },
                //     validator:
                //         (value) =>
                //             (value?.isEmpty ?? true) ? "Enter bank name" : null,
                //   ),
                //   _buildTextFormField(
                //     label: "Branch Name",
                //     icon: Iconsax.bank,
                //     controller: controller.branchNameController,
                //     onChanged: (value) {
                //       controller.branchName.value = value;
                //     },
                //     validator:
                //         (value) =>
                //             (value?.isEmpty ?? true)
                //                 ? "Enter branch name"
                //                 : null,
                //   ),
                //   _buildTextFormField(
                //     label: "IFSC Code",
                //     icon: Iconsax.document_code,
                //     controller: controller.ifscCodeController,
                //     onChanged: (value) {
                //       controller.ifscCode.value = value;
                //     },
                //     validator:
                //         (value) =>
                //             (value?.isEmpty ?? true) ? "Enter IFSC code" : null,
                //   ),
                //   _buildTextFormField(
                //     label: "Account Number",
                //     icon: Iconsax.wallet,
                //     controller: controller.accountNoController,
                //     onChanged: (value) {
                //       controller.accountNo.value = value;
                //     },
                //     keyboardType: TextInputType.number,
                //     validator:
                //         (value) =>
                //             (value?.isEmpty ?? true)
                //                 ? "Enter account number"
                //                 : null,
                //   ),
                // ]
                // ),
                SizedBox(height: 24.h),

                // KYC Details Card
                // _buildEditableCard("KYC Details", [
                SizedBox(height: 24.h),
                // Save Button at the bottom
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed:
                        controller.isSaving.value
                            ? null
                            : controller.saveProfile,
                    // icon:
                    //     controller.isSaving.value
                    //         ? SizedBox(
                    //           width: 20.w,
                    //           height: 20.w,
                    //           child: CircularProgressIndicator(
                    //             strokeWidth: 2.w,
                    //             valueColor: AlwaysStoppedAnimation<Color>(
                    //               Colors.white,
                    //             ),
                    //           ),
                    //         )
                    //         : Icon(Iconsax.save_2, size: 20.w),
                    label: Text(
                      controller.isSaving.value ? "Saving..." : "Save Profile",
                      style: AppText.button.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 24.h), // Add some padding at the bottom
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEditableCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title.contains("KYC")
                      ? Iconsax.document_text
                      : Iconsax.info_circle,
                  size: 24.w,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.textColorPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.ltr,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppText.labelMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
          prefixIcon: Icon(icon, size: 20.w, color: AppColors.primary),
          filled: true,
          fillColor: AppColors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.primary, width: 2.w),
          ),
        ),
        style: AppText.bodyMedium.copyWith(color: AppColors.textColorPrimary),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      ),
    );
  }

  Widget _buildImageSection(
    String title,
    Uint8List? imageBytes,
    VoidCallback onTap,
    IconData placeholderIcon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.labelMedium.copyWith(
            color: AppColors.textColorPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child:
                imageBytes != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.memory(imageBytes, fit: BoxFit.cover),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          placeholderIcon,
                          size: 40.w,
                          color: AppColors.textColorHint,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Tap to select image",
                          style: AppText.labelSmall.copyWith(
                            color: AppColors.textColorHint,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
