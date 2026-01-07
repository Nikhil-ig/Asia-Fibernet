// screens/technician_profile_screen.dart

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;
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
                Get.dialog(
                  AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: controller.logOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );
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

  Widget _buildProfilePhoto(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
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
      final String cleanBase64 = base64Image.split(',').last;
      final bytes = base64Decode(cleanBase64);
      return Container(
        width: 70.w,
        height: 70.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          image: DecorationImage(
            image: MemoryImage(bytes),
            fit: BoxFit.cover,
            onError: (error, stackTrace) {
              print(
                "TechnicianProfileScreen's Image Error: $error \nstackTrace: $stackTrace",
              ); // fallback if image fails
            },
          ),
        ),
      );
    } catch (e) {
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
  final _prefs = AppSharedPref.instance;

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

  void _loadInitialData(TechnicianProfileModel profile) {
    contactName.value = profile.contactName;
    companyName.value = profile.companyName;
    workPhoneNumber.value = profile.workPhoneNumber?.toString() ?? '';
    cellPhoneNumber.value = profile.cellPhoneNumber?.toString() ?? '';
    email.value = profile.email ?? '';
    websiteAddress.value = profile.websiteAddress ?? '';
    dateOfBirth.value = profile.dateOfBirth ?? '';
    dateOfJoining.value = profile.dateOfJoining ?? '';

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
  String? _imageToBase64(Uint8List? imageBytes) {
    if (imageBytes != null) {
      // Check if it's already a base64 string (starts with data:image)
      // This handles cases where the original was base64 and wasn't changed
      // You might need to adjust this logic based on how you handle unchanged images
      // For now, we'll assume if it was loaded, it's new and needs encoding
      return base64Encode(imageBytes);
    }
    return null;
  }

  // Method to save the updated profile
  Future<void> saveProfile() async {
    if (isSaving.value) return; // Prevent multiple simultaneous saves

    isSaving.value = true;

    try {
      // 1. Get device and network information
      final deviceInfo = DeviceInfoPlugin();
      // final connectivityResult = await Connectivity().checkConnectivity();
      final networkInfo = NetworkInfo();
      final wifiName = await networkInfo.getWifiName();
      final wifiBSSID = await networkInfo.getWifiBSSID();
      final wifiIP = await networkInfo.getWifiIP();
      final wifiIPv6 = await networkInfo.getWifiIPv6();
      final wifiSubmask = await networkInfo.getWifiSubmask();
      final wifiBroadcast = await networkInfo.getWifiBroadcast();
      // final wifiGateway = await networkInfo.getWifiGatewayIp();

      // 2. Get location (simplified - request last known or current)
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Location services are disabled.
          print("Location services are disabled.");
        } else {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              print('Location permissions are denied');
            }
          }

          if (permission == LocationPermission.deniedForever) {
            print('Location permissions are permanently denied');
          } else {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            );
          }
        }
      } catch (e) {
        print("Error getting location: $e");
      }

      // 3. Get timezone
      final currentTimeZone = tz.local.name;

      // 4. Get customer ID from shared preferences
      final customerId =
          _prefs.getUserID().toString(); // Assuming this is the correct ID

      // 5. Prepare request body
      final requestBody = {
        "customer_id": customerId,
        "ip_address": wifiIP ?? "N/A",
        "time_zone": currentTimeZone,
        "latitude": position?.latitude.toString() ?? "0.0",
        "longitude": position?.longitude.toString() ?? "0.0",
        "city_name": city.value, // Use updated city
        "postal_code": "N/A", // You might want to add a postal code field
        "device": "Android", // Simplified, could get from deviceInfo
        "brand": "Generic", // Simplified, could get from deviceInfo
        "wifi_name": wifiName ?? "N/A",
        "wifi_bssid": wifiBSSID ?? "N/A",
        "wifi_ip": wifiIP ?? "N/A",
        "wifi_ipv6": wifiIPv6 ?? "N/A",
        "wifi_submask": wifiSubmask ?? "N/A",
        "wifi_broadcast": wifiBroadcast ?? "N/A",
        // "wifi_gateway": wifiGateway ?? "N/A",
        // Add profile fields
        "contact_name": contactName.value,
        "company_name": companyName.value,
        "address": address.value,
        "state": state.value,
        "work_phone_number": workPhoneNumber.value,
        "cell_phone_number": cellPhoneNumber.value,
        "email": email.value,
        "website_address": websiteAddress.value,
        "technician_name": technicianName.value,
        "aadharcard_no": aadharcardNo.value,
        "pancard_no": pancardNo.value,
        "bank_name": bankName.value,
        "branch_name": branchName.value,
        "ifsc_code": ifscCode.value,
        "account_no": accountNo.value,
        "date_of_birth": dateOfBirth.value,
        "date_of_joining": dateOfJoining.value,
        // Include images if they were selected/changed
        if (profilePhoto.value != null)
          "profile_photo": _imageToBase64(profilePhoto.value),
        if (aadharFront.value != null)
          "aadhar_front": _imageToBase64(aadharFront.value),
        if (aadharBack.value != null)
          "aadhar_back": _imageToBase64(aadharBack.value),
      };

      print("Sending update request with body: $requestBody");

      // 6. Make API call
      final response = await _api.updateProfile(requestBody);

      if (response) {
        // Go back to profile screen
        Get.back(result: true); // Indicate success if needed
      }
    } catch (e) {
      print("Error saving profile: $e");
      BaseApiService().showSnackbar(
        "❌ Error",
        "An error occurred while saving the profile.",
        isError: true,
      );
    } finally {
      isSaving.value = false;
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
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(Iconsax.save_2, size: 22),
              onPressed:
                  controller.isSaving.value ? null : controller.saveProfile,
              tooltip: "Save Profile",
            ),
          ),
        ],
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
                  _buildTextFormField(
                    label: "Contact Name",
                    icon: Iconsax.user,
                    controller: TextEditingController(
                      text: controller.contactName.value,
                    )..addListener(() {
                      controller.contactName.value =
                          controller.contactName.value;
                    }),
                    validator:
                        (value) =>
                            value?.isEmpty ?? true
                                ? "Enter contact name"
                                : null,
                  ),
                  _buildTextFormField(
                    label: "Address",
                    icon: Iconsax.location,
                    controller: TextEditingController(
                      text: controller.address.value,
                    )..addListener(() {
                      controller.address.value = controller.address.value;
                    }),
                  ),
                  // _buildTextFormField(
                  //   label: "City",
                  //   icon: Iconsax.location,
                  //   controller: TextEditingController(
                  //     text: controller.city.value,
                  //   )..addListener(() {
                  //     controller.city.value = controller.city.value;
                  //   }),
                  // ),
                  // _buildTextFormField(
                  //   label: "State",
                  //   icon: Iconsax.global,
                  //   controller: TextEditingController(
                  //     text: controller.state.value,
                  //   )..addListener(() {
                  //     controller.state.value = controller.state.value;
                  //   }),
                  // ),
                  _buildTextFormField(
                    label: "Work Phone",
                    icon: Iconsax.call,
                    controller: TextEditingController(
                      text: controller.workPhoneNumber.value,
                    )..addListener(() {
                      controller.workPhoneNumber.value =
                          controller.workPhoneNumber.value;
                    }),
                    keyboardType: TextInputType.phone,
                  ),
                  // _buildTextFormField(
                  //   label: "Mobile",
                  //   icon: Iconsax.call,
                  //   controller: TextEditingController(
                  //     text: controller.cellPhoneNumber.value,
                  //   )..addListener(() {
                  //     controller.cellPhoneNumber.value =
                  //         controller.cellPhoneNumber.value;
                  //   }),
                  //   keyboardType: TextInputType.phone,
                  // ),
                  // _buildTextFormField(
                  //   label: "Email",
                  //   icon: Iconsax.message,
                  //   controller: TextEditingController(
                  //     text: controller.email.value,
                  //   )..addListener(() {
                  //     controller.email.value = controller.email.value;
                  //   }),
                  //   keyboardType: TextInputType.emailAddress,
                  //   validator: (value) {
                  //     if (value == null || value.isEmpty)
                  //       return null; // Optional
                  //     if (!GetUtils.isEmail(value))
                  //       return "Enter a valid email";
                  //     return null;
                  //   },
                  // ),
                  // _buildTextFormField(
                  //   label: "Website",
                  //   icon: Iconsax.link,
                  //   controller: TextEditingController(
                  //     text: controller.websiteAddress.value,
                  //   )..addListener(() {
                  //     controller.websiteAddress.value =
                  //         controller.websiteAddress.value;
                  //   }),
                  //   keyboardType: TextInputType.url,
                  // ),
                ]),
                SizedBox(height: 24.h),

                // KYC Details Card
                // _buildEditableCard("KYC Details", [
                //   // _buildTextFormField(
                //   //   label: "Technician Name",
                //   //   icon: Iconsax.security_card,
                //   //   controller: TextEditingController(
                //   //     text: controller.technicianName.value,
                //   //   )..addListener(() {
                //   //     controller.technicianName.value =
                //   //         controller.technicianName.value;
                //   //   }),
                //   //   validator:
                //   //       (value) =>
                //   //           value?.isEmpty ?? true
                //   //               ? "Enter technician name"
                //   //               : null,
                //   // ),
                //   // _buildTextFormField(
                //   //   label: "Aadhaar No.",
                //   //   icon: Iconsax.security_card,
                //   //   controller: TextEditingController(
                //   //     text: controller.aadharcardNo.value,
                //   //   )..addListener(() {
                //   //     controller.aadharcardNo.value =
                //   //         controller.aadharcardNo.value;
                //   //   }),
                //   //   keyboardType: TextInputType.number,
                //   //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                //   // ),
                //   // _buildTextFormField(
                //   //   label: "PAN No.",
                //   //   icon: Iconsax.security_card,
                //   //   controller: TextEditingController(
                //   //     text: controller.pancardNo.value,
                //   //   )..addListener(() {
                //   //     controller.pancardNo.value = controller.pancardNo.value;
                //   //   }),
                //   // ),
                //   // SizedBox(height: 20.h),
                //   // // Aadhaar Images
                //   // _buildImageSection(
                //   //   "Aadhaar Front",
                //   //   controller.aadharFront.value,
                //   //   controller.pickAadharFront,
                //   //   Iconsax.document,
                //   // ),
                //   // SizedBox(height: 16.h),
                //   // _buildImageSection(
                //   //   "Aadhaar Back",
                //   //   controller.aadharBack.value,
                //   //   controller.pickAadharBack,
                //   //   Iconsax.document,
                //   // ),
                //   // SizedBox(height: 20.h),
                //   Text(
                //     "Bank Details",
                //     style: AppText.labelLarge.copyWith(
                //       color: AppColors.textColorPrimary,
                //     ),
                //   ),
                //   SizedBox(height: 12.h),
                //   _buildTextFormField(
                //     label: "Bank Name",
                //     icon: Iconsax.bank,
                //     controller: TextEditingController(
                //       text: controller.bankName.value,
                //     )..addListener(() {
                //       controller.bankName.value = controller.bankName.value;
                //     }),
                //   ),
                //   _buildTextFormField(
                //     label: "Branch",
                //     icon: Iconsax.bank,
                //     controller: TextEditingController(
                //       text: controller.branchName.value,
                //     )..addListener(() {
                //       controller.branchName.value = controller.branchName.value;
                //     }),
                //   ),
                //   _buildTextFormField(
                //     label: "IFSC Code",
                //     icon: Iconsax.document_code,
                //     controller: TextEditingController(
                //       text: controller.ifscCode.value,
                //     )..addListener(() {
                //       controller.ifscCode.value = controller.ifscCode.value;
                //     }),
                //   ),
                //   _buildTextFormField(
                //     label: "Account No.",
                //     icon: Iconsax.wallet,
                //     controller: TextEditingController(
                //       text: controller.accountNo.value,
                //     )..addListener(() {
                //       controller.accountNo.value = controller.accountNo.value;
                //     }),
                //     keyboardType: TextInputType.number,
                //     // ),
                //     // SizedBox(height: 20.h),
                //     // _buildDateField(
                //     //   label: "Date of Birth",
                //     //   icon: Iconsax.calendar,
                //     //   initialValue: controller.dateOfBirth.value,
                //     //   onDateSelected:
                //     //       (dateString) =>
                //     //           controller.dateOfBirth.value = dateString,
                //     // ),
                //     // _buildDateField(
                //     //   label: "Date of Joining",
                //     //   icon: Iconsax.calendar,
                //     //   initialValue: controller.dateOfJoining.value,
                //     //   onDateSelected:
                //     //       (dateString) =>
                //     //           controller.dateOfJoining.value = dateString,
                //   ),
                // ]),
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
                    icon:
                        controller.isSaving.value
                            ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Iconsax.save_2, size: 20.w),
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
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
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

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required String initialValue,
    required Function(String) onDateSelected,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: Get.context!,
            initialDate:
                initialValue.isNotEmpty
                    ? DateFormat('yyyy-MM-dd').parse(initialValue)
                    : DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
            onDateSelected(formattedDate);
          }
        },
        child: InputDecorator(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                initialValue.isNotEmpty ? initialValue : "Select Date",
                style: AppText.bodyMedium.copyWith(
                  color:
                      initialValue.isNotEmpty
                          ? AppColors.textColorPrimary
                          : AppColors.textColorHint,
                ),
              ),
              Icon(
                Iconsax.arrow_down_2,
                size: 16.w,
                color: AppColors.textColorHint,
              ),
            ],
          ),
        ),
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
