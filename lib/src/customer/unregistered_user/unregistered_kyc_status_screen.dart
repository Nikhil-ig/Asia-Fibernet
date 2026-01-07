import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '/src/services/apis/api_services.dart';
import '/src/services/routes.dart';
import '/src/services/sharedpref.dart';

import '../../services/apis/base_api_service.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/models/unregistered_kyc_status_model.dart';

// --- POLICY POPUP DIALOG ---
class PolicyAcceptanceDialog extends StatefulWidget {
  final String policyUrl;
  final VoidCallback onAccept;

  const PolicyAcceptanceDialog({
    Key? key,
    required this.policyUrl,
    required this.onAccept,
  }) : super(key: key);

  @override
  State<PolicyAcceptanceDialog> createState() => _PolicyAcceptanceDialogState();
}

class _PolicyAcceptanceDialogState extends State<PolicyAcceptanceDialog> {
  bool _isChecked = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(widget.policyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Terms & Policies',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        height: 400.h,
        width: Get.size.width * .9,
        child: Column(
          children: [
            Expanded(child: WebViewWidget(controller: _webViewController)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    'I agree to the terms and policies.',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isChecked ? widget.onAccept : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Accept & Continue'),
        ),
      ],
    );
  }
}

// --- CONTROLLER ---
class KycStatusController extends GetxController {
  final ApiServices _api = ApiServices();
  final ImagePicker _picker = ImagePicker();
  var kycData = Rx<KycStatusResponse?>(null);
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isRefreshing = false.obs;
  var hasShownCompletionPopup = false.obs; // 👈 NEW FLAG
  String termLink = '${BaseApiService.api}get_policy.php'; // 👈 NEW FLAG

  @override
  void onInit() {
    fetchKycStatus();
    super.onInit();
  }

  Future<void> fetchKycStatus() async {
    final mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) {
      errorMessage.value = 'Mobile number not found';
      return;
    }
    try {
      isLoading(true);
      final result = await _api.checkKycStatus(mobile);
      kycData.value = result;
      errorMessage.value = '';
      if (kycData.value!.data.documents.isEmpty) {
        AppSharedPref.instance.clearAllUserData();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load KYC status';
    } finally {
      isLoading(false);
      isRefreshing(false);
    }
  }

  Future<void> refreshData() async {
    isRefreshing(true);
    await fetchKycStatus();
  }

  Future<bool> reUploadDocument(KycDocument doc) async {
    BaseApiService baseApiService = Get.find<BaseApiService>();
    final mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) {
      baseApiService.showSnackbar(
        'Error',
        'Mobile number not found',
        isError: true,
      );
      return false;
    }

    final docTypeLower = doc.type.toLowerCase();
    final isFullAadhar =
        docTypeLower == 'aadhar' || docTypeLower == 'full aadhar';
    final isAddressProofOnly = 'address';

    final frontPicked = await _showImagePickerDialog('Front of ${doc.type}');
    if (frontPicked == null) return false;

    XFile? backPicked;
    if (isFullAadhar) {
      backPicked = await _showImagePickerDialog('Back of ${doc.type}');
      if (backPicked == null) return false;
    }

    try {
      final frontBytes = await frontPicked.readAsBytes();
      final backBytes =
          backPicked != null ? await backPicked.readAsBytes() : null;
      final front64 = base64Encode(frontBytes);
      final back64 = backBytes != null ? base64Encode(backBytes) : null;

      String documentType;
      Map<String, dynamic> docFields;
      if (isFullAadhar) {
        documentType = "Aadhar";
        docFields = {"proof_front": front64, "proof_back": back64!};
      } else {
        documentType = "Address Proof";
        docFields = {"address_proof_img": front64};
      }

      final payload = {
        "customer": {"mobile_no": mobile},
        "documents": [
          {"document_type": documentType, ...docFields},
        ],
      };

      final bool success = await _api.reUploadKyc(payload);
      Get.back();

      if (success) {
        await fetchKycStatus();
        baseApiService.showSnackbar(
          'Success',
          "Document re-uploaded successfully!",
          isError: false,
        );
        return true;
      } else {
        baseApiService.showSnackbar(
          'Error',
          "Upload failed. Please try again.",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      Get.back();
      baseApiService.showSnackbar(
        "Error",
        e.toString().split(':').first,
        isError: true,
      );
      return false;
    }
  }

  void _showUploadingDialog() {
    Get.dialog(
      Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30.r,
                spreadRadius: 5.r,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.document_upload,
                  size: 40.r,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Uploading Document",
                style: AppText.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Please wait while we process your document...",
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: 40.w,
                height: 40.h,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<XFile?> _showImagePickerDialog(String title) async {
    return await showDialog<XFile?>(
      context: Get.context!,
      builder:
          (context) => AlertDialog(
            title: Text(title, style: AppText.headingSmall),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text('Gallery', style: AppText.bodyMedium),
                  onTap: () async {
                    final image = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    Get.back(result: image);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Camera', style: AppText.bodyMedium),
                  onTap: () async {
                    final image = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    Get.back(result: image);
                  },
                ),
              ],
            ),
          ),
    );
  }
}

// --- MAIN SCREEN ---
class FinalKycStatusScreen extends StatelessWidget {
  final KycStatusController controller = Get.put(KycStatusController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Obx(() {
        // 🔥 Trigger popup once when fully complete
        final data = controller.kycData.value;
        if (data != null &&
            !controller.hasShownCompletionPopup.value &&
            data.data.registration.steps >= 5
        // &&
        // (data.serviceStatus == 'verified' ||
        //     data.serviceStatus == 'completed')
        ) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.hasShownCompletionPopup.value = true;
            _showCompletionPolicyPopup(context);
          });
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          backgroundColor: AppColors.primary,
          color: Colors.white,
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [_buildAppBar(), _buildContent()],
          ),
        );
      }),
    );
  }

  void _showCompletionPolicyPopup(BuildContext context) {
    Get.dialog(
      barrierDismissible: false,
      PolicyAcceptanceDialog(
        policyUrl: "${BaseApiService.api}get_policy.php",
        onAccept: () async {
          Get.back(); // Close dialog

          // ✅ Call user confirmation API
          final api = ApiServices();
          final success = await api.userConfirmation();

          if (success) {
            // ✅ Mark user as fully verified
            await AppSharedPref.instance.setVerificationStatus(true);

            // ✅ Navigate to home (not greeting/login!)
            Get.offAllNamed(AppRoutes.greeting);
          } else {
            // ❌ Show error and stay on screen
            BaseApiService().showSnackbar(
              "Error",
              "Failed to confirm your agreement. Please try again.",
              isError: true,
            );
          }
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.h,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'KYC Status',
          style: AppText.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.primaryLight,
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40.w,
                top: -40.h,
                child: Container(
                  width: 160.w,
                  height: 160.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -30.w,
                bottom: -30.h,
                child: Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 60.w,
                bottom: 20.h,
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Obx(
          () => IconButton(
            icon:
                controller.isRefreshing.value
                    ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed:
                controller.isRefreshing.value
                    ? null
                    : () => controller.refreshData(),
          ),
        ),
      ],
    );
  }

  Obx _buildContent() {
    return Obx(() {
      if (controller.isLoading.value && controller.kycData.value == null) {
        return SliverFillRemaining(child: _buildLoadingIndicator());
      }
      if (controller.errorMessage.isNotEmpty) {
        return SliverFillRemaining(child: _buildErrorWidget());
      }
      if (controller.kycData.value == null) {
        return SliverFillRemaining(child: _buildNoDataWidget());
      }
      return _buildMainContent(controller.kycData.value!);
    });
  }

  SliverList _buildMainContent(KycStatusResponse data) {
    return SliverList(
      delegate: SliverChildListDelegate([
        SizedBox(height: 16.h),
        _buildStepsOverview(data),
        SizedBox(height: 24.h),
        _buildPersonalInfoSection(data),
        SizedBox(height: 24.h),
        _buildDocumentSection(data),
        SizedBox(height: 40.h),
      ]),
    );
  }

  // ... (rest of your existing helper methods: _buildStepsOverview, _buildTimelineStep, etc.)
  // They remain **unchanged** — just paste them below as they were

  Widget _buildStepsOverview(KycStatusResponse data) {
    final _steps = [
      {"name": "Registration", "description": "Registration created"},
      {
        "name": "Feasibility",
        "description": "Feasibility checked & Technician assigned",
      },
      {"name": "KYC", "description": "KYC under verification / rejected"},
      {"name": "Wire Installation", "description": "Wire installation done"},
      {"name": "Modem Installation", "description": "Modem installation done"},
      {
        "name": "Customer Confirmation",
        "description": "Customer user confirmation",
      },
    ];
    final currentStep =
        (data.data.registration.steps) >= 5 ? 5 : data.data.registration.steps;
    final totalSteps = _steps.length;
    final progress = (currentStep + 1) / totalSteps;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w).copyWith(top: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Installation Journey',
                        style: AppText.headingSmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: AppText.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Stack(
                  children: [
                    Container(
                      height: 8.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.dividerColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 8.h,
                      width: MediaQuery.of(Get.context!).size.width * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 320.h,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isActive = index <= currentStep;
                final isCompleted = index < currentStep;
                final isCurrent = index == currentStep;
                final isLast = index == _steps.length - 1;
                return _buildTimelineStep(
                  index: index,
                  step: step,
                  isActive: isActive,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isLast: isLast,
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.primaryLight.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Step: ${_steps[currentStep]['name']}',
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _steps[currentStep]['description']!,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required Map<String, String> step,
    required bool isActive,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (index > 0)
                Container(
                  width: 2.w,
                  height: 24.h,
                  color:
                      isActive
                          ? AppColors.success
                          : AppColors.dividerColor.withOpacity(0.3),
                )
              else
                SizedBox(height: 24.h),
              Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      isActive
                          ? (isCompleted || isLast
                              ? LinearGradient(
                                colors: [AppColors.success, Color(0xFF4CAF50)],
                              )
                              : LinearGradient(
                                colors: [AppColors.warning, AppColors.primary],
                              ))
                          : null,
                  color:
                      isActive ? null : AppColors.dividerColor.withOpacity(0.3),
                  boxShadow:
                      isActive
                          ? [
                            BoxShadow(
                              color: (isCurrent
                                      ? (isLast
                                          ? AppColors.success
                                          : AppColors.warning)
                                      : AppColors.success)
                                  .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ]
                          : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isCompleted || isLast)
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    if (isCurrent && !isLast)
                      Icon(
                        Icons.autorenew_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    if (!isActive)
                      Icon(
                        Icons.circle_outlined,
                        color: AppColors.textColorHint,
                        size: 20.sp,
                      ),
                    if (isCurrent && !isLast)
                      PulseAnimation(
                        child: Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.6),
                              width: 2.w,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2.w,
                  height: 38.h,
                  color:
                      (isActive && !isCurrent)
                          ? AppColors.success
                          : AppColors.dividerColor.withOpacity(0.3),
                )
              else
                SizedBox(height: 24.h),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? (isCurrent
                                ? (isLast
                                    ? AppColors.success.withOpacity(0.15)
                                    : AppColors.warning.withOpacity(0.15))
                                : AppColors.success.withOpacity(0.15))
                            : AppColors.dividerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Step ${index + 1} • ${step['name']!}',
                    style: AppText.labelMedium.copyWith(
                      color:
                          isActive
                              ? (isCurrent
                                  ? (isLast
                                      ? AppColors.success
                                      : AppColors.warning)
                                  : AppColors.success)
                              : AppColors.textColorHint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  step['description']!,
                  style: AppText.bodyMedium.copyWith(
                    color:
                        isActive
                            ? AppColors.textColorPrimary
                            : AppColors.textColorHint,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                SizedBox(height: 8.h),
                if (isActive)
                  Row(
                    children: [
                      Icon(
                        isCompleted || isLast
                            ? Icons.check_circle
                            : Icons.access_time,
                        size: 16.sp,
                        color:
                            isCompleted || isLast
                                ? AppColors.success
                                : AppColors.warning,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isCompleted || isLast ? 'Completed' : 'In Progress',
                        style: AppText.labelSmall.copyWith(
                          color:
                              isCompleted || isLast
                                  ? AppColors.success
                                  : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(KycStatusResponse data) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Personal Information',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _buildUserInfoCard(data),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(KycStatusResponse data) {
    final infoItems = [
      _InfoItem(
        Icons.person_outline_rounded,
        'Full Name',
        data.data.registration.fullName,
      ),
      _InfoItem(
        Icons.phone_android_rounded,
        'Mobile',
        data.data.registration.mobileNumber,
      ),
      _InfoItem(Icons.email_rounded, 'Email', data.data.registration.email),
      _InfoItem(
        Icons.home_work_rounded,
        'Address',
        data.data.registration.streetAddress != ''
            ? data.data.registration.streetAddress
            : '${data.data.registration.streetAddress}, ${data.data.registration.city}, ${data.data.registration.state}',
      ),
    ];
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: infoItems.map((item) => _buildInfoRow(item)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 18.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppText.labelSmall.copyWith(
                    color: AppColors.textColorSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.value,
                  style: AppText.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
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

  Widget _buildDocumentSection(KycStatusResponse data) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Icon(
                  Icons.folder_copy_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Document Verification',
                  style: AppText.headingSmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ...data.data.documents.map((doc) => _buildDocumentCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(KycDocument doc) {
    final statusConfig = _getDocumentStatusConfig(doc.verificationStatus);
    final showReupload = doc.issue != null && doc.issue!.isNotEmpty;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      _getDocumentIcon(doc.type),
                      size: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    doc.type.toUpperCase(),
                    style: AppText.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showReupload) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Issue: ${doc.issue}',
                      style: AppText.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
          if ((doc.documentFrontUrl != null &&
                  doc.documentFrontUrl!.isNotEmpty) ||
              (doc.documentBackUrl != null && doc.documentBackUrl!.isNotEmpty))
            Row(
              children: [
                if (doc.documentFrontUrl != null &&
                    doc.documentFrontUrl!.isNotEmpty)
                  Expanded(
                    child: _buildPreviewButton(
                      doc.documentFrontUrl!,
                      'Front View',
                    ),
                  ),
                if ((doc.type == "Aadhar") &&
                    (doc.documentBackUrl != null &&
                        doc.documentBackUrl!.isNotEmpty)) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildPreviewButton(
                      doc.documentBackUrl!,
                      'Back View',
                    ),
                  ),
                ],
              ],
            ),
          if (showReupload) ...[
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => controller.reUploadDocument(doc),
              icon: Icon(
                Icons.cloud_upload_rounded,
                size: 18.sp,
                color: AppColors.backgroundLight,
              ),
              label: Text('Re-Upload ${doc.type}', style: AppText.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                minimumSize: Size(double.infinity, 50.h),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewButton(String url, String title) {
    return InkWell(
      onTap: () => _showImagePreview(url, title),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 24.sp,
              color: AppColors.primary,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: AppText.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(String fileUrl, String title) {
    final isPdf = fileUrl.toLowerCase().endsWith('.pdf');

    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppText.headingMedium),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close_rounded, size: 24.sp),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child:
                  isPdf ? _buildPdfViewer(fileUrl) : _buildImageViewer(fileUrl),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // PDF Viewer
  Widget _buildPdfViewer(String pdfUrl) {
    return PDFView(
      filePath: pdfUrl, // Supports network URL directly
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      pageSnap: true,
      defaultPage: 1,
      preventLinkNavigation: false,
      onRender: (pages) {
        debugPrint('PDF rendered with $pages pages');
      },
      onError: (error) {
        debugPrint('PDF error: $error');
      },
      onPageError: (page, error) {
        debugPrint('PDF page error: page=$page, error=$error');
      },
    );
  }

  // Image Viewer (your existing logic)
  Widget _buildImageViewer(String imageUrl) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder:
              (_, __, ___) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48.sp,
                      color: AppColors.error,
                    ),
                    SizedBox(height: 16.h),
                    Text('Failed to load file', style: AppText.bodyMedium),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String serviceStatus) {
    switch (serviceStatus) {
      case 'verified':
      case 'completed':
        return _StatusConfig(
          color: AppColors.success,
          icon: Icons.verified_user_rounded,
          title: 'Verified',
          description: 'Your KYC has been successfully verified and approved',
        );
      case 'pending':
        return _StatusConfig(
          color: AppColors.warning,
          icon: Icons.pending_actions_rounded,
          title: 'Pending Review',
          description: 'Your KYC is currently under verification process',
        );
      case 'rejected':
        return _StatusConfig(
          color: AppColors.error,
          icon: Icons.error_outline_rounded,
          title: 'Rejected',
          description: 'Your KYC requires additional verification',
        );
      default:
        return _StatusConfig(
          color: AppColors.info,
          icon: Icons.hourglass_empty_rounded,
          title: 'In Progress',
          description: 'Your KYC is being processed',
        );
    }
  }

  _DocumentStatusConfig _getDocumentStatusConfig(String status) {
    switch (status) {
      case 'verified':
        return _DocumentStatusConfig(
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: 'Verified',
        );
      case 'rejected':
        return _DocumentStatusConfig(
          color: AppColors.error,
          icon: Icons.cancel_rounded,
          label: 'Rejected',
        );
      case 'pending':
      default:
        return _DocumentStatusConfig(
          color: AppColors.warning,
          icon: Icons.pending_rounded,
          label: 'Pending',
        );
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'aadhar':
        return Icons.credit_card_rounded;
      case 'address proof':
        return Icons.home_work_rounded;
      case 'pancard':
        return Icons.badge_rounded;
      case 'photo':
        return Icons.camera_alt_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 24.h),
        Text(
          'Loading KYC Status...',
          style: AppText.headingSmall.copyWith(color: AppColors.primaryDark),
        ),
        SizedBox(height: 8.h),
        Text(
          'Please wait while we fetch your information',
          style: AppText.bodyMedium.copyWith(
            color: AppColors.textColorSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/error.json',
          width: 150.w,
          height: 150.h,
        ),
        SizedBox(height: 24.h),
        Text(
          'Oops! Something went wrong',
          style: AppText.headingSmall.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            controller.errorMessage.value,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton.icon(
          onPressed: controller.fetchKycStatus,
          icon: Icon(Icons.refresh_rounded),
          label: Text('Try Again', style: AppText.button),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 60, color: AppColors.textColorHint),
        SizedBox(height: 24.h),
        Text(
          'No KYC Data Found',
          style: AppText.headingSmall.copyWith(color: AppColors.primaryDark),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            'We couldn\'t find any KYC information associated with your account',
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton.icon(
          onPressed: controller.fetchKycStatus,
          icon: Icon(Icons.refresh_rounded),
          label: Text('Refresh', style: AppText.button),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  _StatusConfig({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _DocumentStatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  _DocumentStatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  _InfoItem(this.icon, this.label, this.value);
}

class PulseAnimation extends StatefulWidget {
  final Widget child;
  const PulseAnimation({Key? key, required this.child}) : super(key: key);
  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
