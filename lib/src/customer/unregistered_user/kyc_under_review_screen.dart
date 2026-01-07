// ui/screen/kyc_under_review_screen.dart
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/models/bsnl_plan_model.dart';

// ui/controllers/kyc_under_review_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../services/apis/api_services.dart';
import '../../services/routes.dart';
import '../../services/sharedpref.dart';
import '../core/models/bsnl_plan_model.dart';
import '../core/models/unregistered_kyc_status_model.dart';

class KycUnderReviewController extends GetxController {
  final ApiServices _apiService = Get.find<ApiServices>();

  var kycStatus = Rx<KycStatusResponse?>(null);
  var bsnlPlans = <BsnlPlan>[].obs;
  var isCheckingStatus = false.obs;
  var isPlansLoading = false.obs;

  Timer? _statusCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _startStatusChecking();
  }

  Future<void> _loadInitialData() async {
    await _fetchKycStatus();
    await _fetchBsnlPlans();
  }

  Future<void> _fetchKycStatus() async {
    final mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) return;

    final status = await _apiService.checkKycStatus(mobile);
    if (status != null) {
      kycStatus.value = status;
    }
  }

  Future<void> _fetchBsnlPlans() async {
    isPlansLoading(true);
    try {
      final plans = await _apiService.fetchBsnlPlan();
      if (plans != null) {
        bsnlPlans.assignAll(plans);
      }
    } finally {
      isPlansLoading(false);
    }
  }

  void _startStatusChecking() {
    // Initial check
    _checkKycStatus();

    _statusCheckTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _checkKycStatus();
    });
  }

  Future<void> _checkKycStatus() async {
    if (isCheckingStatus.value) return;

    isCheckingStatus(true);
    try {
      final mobile = AppSharedPref.instance.getMobileNumber();
      if (mobile == null) return;

      final status = await _apiService.checkKycStatus(mobile);
      if (status == null) return;

      kycStatus.value = status;

      // Navigate away if no longer under review
      if (status.serviceStatus != "under_review") {
        _statusCheckTimer?.cancel();

        if (status.data.registration.steps >= 3 &&
            status.data.documents.isNotEmpty) {
          Get.offAllNamed(AppRoutes.finalKYCReview);
        } else {
          Get.offAllNamed(AppRoutes.unregisteredUser);
        }
      }
    } finally {
      isCheckingStatus(false);
    }
  }

  void manualCheckStatus() {
    _checkKycStatus();
  }

  void explorePlans() {
    Get.toNamed(AppRoutes.bsnlPlans);
  }

  void viewPlanDetails(BsnlPlan plan) {
    Get.dialog(PlanDetailsDialog(plan: plan));
  }

  @override
  void onClose() {
    _statusCheckTimer?.cancel();
    super.onClose();
  }
}

class KycUnderReviewScreen extends StatefulWidget {
  const KycUnderReviewScreen({Key? key}) : super(key: key);

  @override
  State<KycUnderReviewScreen> createState() => _KycUnderReviewScreenState();
}

class _KycUnderReviewScreenState extends State<KycUnderReviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late final KycUnderReviewController controller = Get.put(
    KycUnderReviewController(),
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  void _manualCheckStatus() {
    _animationController.reset();
    _animationController.forward();
    controller.manualCheckStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 30.h),
              _buildHeaderSection(),
              SizedBox(height: 40.h),
              _buildProgressSteps(),
              SizedBox(height: 20.h),
              _buildConnectionCheckInfo(),
              SizedBox(height: 20.h),
              _buildEstimatedTime(),
              SizedBox(height: 20.h),
              _buildSupportInfo(),
              SizedBox(height: 20.h),
              _buildPlansPreview(),
              SizedBox(height: 30.h),
              _buildActionButtons(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          _buildStatusIndicator(),
          SizedBox(height: 30.h),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'File is Under Review',
              style: AppText.headingLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 10.h),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'We are verifying your documents and checking service availability in your area. This usually takes 24-48 hours.',
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120.w,
        height: 120.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary,
              AppColors.primaryDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20.r,
              spreadRadius: 5.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 4.w,
                    ),
                  ),
                ),
              ),
            ),
            Center(child: Icon(Iconsax.clock, size: 50.r, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Obx(() {
      final currentStep =
          controller.kycStatus.value?.data.registration.steps ?? 0;
      final totalSteps = 3;

      return FadeInUp(
        duration: Duration(milliseconds: 800),
        child: Container(
          padding: EdgeInsets.all(20.w),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20.r,
                spreadRadius: 2.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Verification Progress',
                style: AppText.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              ...List.generate(totalSteps, (index) {
                final isCompleted = index <= currentStep;
                final isCurrent = index == currentStep;

                return SlideInLeft(
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 15.h),
                    padding: EdgeInsets.all(15.w),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? AppColors.success.withOpacity(0.1)
                              : isCurrent
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color:
                            isCompleted
                                ? AppColors.success
                                : isCurrent
                                ? AppColors.primary
                                : AppColors.dividerColor,
                        width: 2.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? AppColors.success
                                    : isCurrent
                                    ? AppColors.primary
                                    : AppColors.textColorHint,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child:
                                isCompleted
                                    ? Icon(
                                      Iconsax.tick_circle,
                                      color: Colors.white,
                                      size: 20.r,
                                    )
                                    : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStepTitle(index),
                                style: AppText.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textColorPrimary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getStepDescription(index),
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                              if (isCurrent) ...[
                                SizedBox(height: 8.h),
                                Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: 0.7,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryDark,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          2.r,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Icon(
                            Iconsax.tick_circle,
                            color: AppColors.success,
                            size: 24.r,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Under Review';
      case 2:
        return 'Service Feasibility Check';
      default:
        return 'Step $step';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Your Basic Information have been submitted successfully';
      case 1:
        return 'We are verifying your details';
      case 2:
        return 'Checking connection availability in your area';
      default:
        return 'Processing...';
    }
  }

  Widget _buildConnectionCheckInfo() {
    return Obx(() {
      final address =
          controller.kycStatus.value?.data.registration.streetAddress ??
          'Loading...';
      final city = controller.kycStatus.value?.data.registration.city;
      final state = controller.kycStatus.value?.data.registration.state;

      return FadeInUp(
        duration: Duration(milliseconds: 1000),
        child: Container(
          padding: EdgeInsets.all(20.w),
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2.w,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.location,
                      color: AppColors.primary,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Availability Check',
                          style: AppText.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                        Text(
                          'Verifying connection feasibility in your area',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.map, color: AppColors.primary, size: 20.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Installation Address',
                            style: AppText.labelSmall.copyWith(
                              color: AppColors.textColorSecondary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            address,
                            style: AppText.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                          if (city != null && city.isNotEmpty)
                            Text(
                              '$city, $state',
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
        ),
      );
    });
  }

  Widget _buildPlansPreview() {
    return FadeInUp(
      duration: Duration(milliseconds: 1000),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
              child: Row(
                children: [
                  Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Explore Our Plans',
                    style: AppText.headingSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              if (controller.isPlansLoading.value) {
                return _buildPlansLoading();
              }

              final featuredPlans = controller.bsnlPlans.take(3).toList();

              return Column(
                children: [
                  SizedBox(
                    height: 180.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: featuredPlans.length,
                      itemBuilder: (context, index) {
                        final plan = featuredPlans[index];
                        return _buildPlanCard(plan, index);
                      },
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Explore Plans Button
                  OutlinedButton.icon(
                    onPressed: controller.explorePlans,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary, width: 2.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                    ),
                    icon: Icon(Icons.explore_rounded, size: 20.sp),
                    label: Text(
                      'Explore All Plans',
                      style: AppText.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BsnlPlan plan, int index) {
    return GestureDetector(
      onTap: () => controller.viewPlanDetails(plan),
      child: Container(
        width: 320.w,
        // height: 260.h,
        margin: EdgeInsets.only(right: 16.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getPlanCardColor(index).withOpacity(0.1),
              _getPlanCardColor(index).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _getPlanCardColor(index).withOpacity(0.2),
            width: 2.w,
          ),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getPlanCardColor(index).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'POPULAR',
                    style: AppText.labelSmall.copyWith(
                      color: _getPlanCardColor(index),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.textColorHint,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: Text(
                plan.planName ?? 'BSNL Plan',
                overflow: TextOverflow.ellipsis,
                style: AppText.headingSmall.copyWith(
                  color: AppColors.textColorPrimary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: Text(
                plan.formattedPrice,
                overflow: TextOverflow.ellipsis,
                style: AppText.headingMedium.copyWith(
                  color: _getPlanCardColor(index),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 16.sp,
                  color: AppColors.textColorSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    plan.formattedSpeed,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.data_usage_rounded,
                  size: 16.sp,
                  color: AppColors.textColorSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    plan.formattedDataLimit,
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Validity: ${plan.formattedValidity}',
              style: AppText.labelSmall.copyWith(
                color: AppColors.textColorHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanCardColor(int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.success];
    return colors[index % colors.length];
  }

  Widget _buildPlansLoading() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280.w,
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
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
                Container(
                  width: 60.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: 120.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 80.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstimatedTime() {
    return FadeInUp(
      duration: Duration(milliseconds: 1200),
      child: Container(
        padding: EdgeInsets.all(20.w),
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15.r,
              spreadRadius: 1.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.clock, color: AppColors.warning, size: 24.r),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Processing Time',
                    style: AppText.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  Text(
                    '24-48 hours',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'Ongoing',
                style: AppText.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportInfo() {
    return FadeInUp(
      duration: Duration(milliseconds: 1400),
      child: Container(
        padding: EdgeInsets.all(20.w),
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.headphone,
                color: AppColors.secondary,
                size: 24.r,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help?',
                    style: AppText.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  Text(
                    'Contact our support team for assistance',
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Iconsax.call,
                        size: 16.r,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '+91-XXXXXX-XXXX',
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildActionButtons() {
    return FadeInUp(
      duration: Duration(milliseconds: 1600),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            Obx(
              () => ElevatedButton.icon(
                onPressed:
                    controller.isCheckingStatus.value
                        ? null
                        : _manualCheckStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 30.w,
                    vertical: 16.h,
                  ),
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                icon:
                    controller.isCheckingStatus.value
                        ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                        : Icon(
                          Iconsax.refresh,
                          size: 20.r,
                          color: AppColors.backgroundLight,
                        ),
                label: Text(
                  controller.isCheckingStatus.value
                      ? 'Checking Status...'
                      : 'Check Status',
                  style: AppText.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              'Status updates automatically every 30 seconds',
              style: AppText.bodySmall.copyWith(color: AppColors.textColorHint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Plan Details Dialog
class PlanDetailsDialog extends StatelessWidget {
  final BsnlPlan plan;

  const PlanDetailsDialog({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30.r,
              spreadRadius: 5.r,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sim_card_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        plan.planName ?? 'BSNL Plan',
                        style: AppText.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Center(
                      child: Text(
                        plan.formattedPrice,
                        style: AppText.headingLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Center(
                      child: Text(
                        'Per ${plan.formattedValidity.toLowerCase()}',
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Features
                    _buildFeatureItem(
                      Icons.speed_rounded,
                      'Speed',
                      plan.formattedSpeed,
                    ),
                    _buildFeatureItem(
                      Icons.data_usage_rounded,
                      'Data Limit',
                      plan.formattedDataLimit,
                    ),
                    _buildFeatureItem(
                      Icons.calendar_today_rounded,
                      'Validity',
                      plan.formattedValidity,
                    ),

                    if (plan.additionalBenefits?.isNotEmpty == true) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Additional Benefits',
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        plan.additionalBenefits!,
                        style: AppText.bodyMedium.copyWith(
                          color: AppColors.textColorSecondary,
                        ),
                      ),
                    ],

                    // SizedBox(height: 24.h),

                    // Action Buttons
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: OutlinedButton(
                    //         onPressed: Get.back,
                    //         style: OutlinedButton.styleFrom(
                    //           foregroundColor: AppColors.primary,
                    //           side: BorderSide(
                    //             color: AppColors.primary,
                    //             width: 2.w,
                    //           ),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12.r),
                    //           ),
                    //           padding: EdgeInsets.symmetric(vertical: 12.h),
                    //         ),
                    //         child: Text('Close'),
                    //       ),
                    //     ),
                    //     SizedBox(width: 12.w),
                    //     Expanded(
                    //       child: ElevatedButton(
                    //         onPressed: () {
                    //           // Handle plan selection
                    //           Get.back();
                    //           BaseApiService().showSnackbar(
                    //             'Plan Selected',
                    //             '${plan.planName} has been selected',
                    //             snackPosition: SnackPosition.BOTTOM,
                    //             backgroundColor: AppColors.success,
                    //             colorText: Colors.white,
                    //           );
                    //         },
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: AppColors.primary,
                    //           foregroundColor: Colors.white,
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12.r),
                    //           ),
                    //           padding: EdgeInsets.symmetric(vertical: 12.h),
                    //         ),
                    //         child: Text('Select Plan'),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppText.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animation Widgets
