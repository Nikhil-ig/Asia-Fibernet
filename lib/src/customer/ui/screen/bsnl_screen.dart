// lib/src/ui/screen/premium_bsnl_plans_screen.dart

import 'package:asia_fibernet/src/auth/ui/scaffold_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import '../../../services/apis/base_api_service.dart';
import '/src/customer/ui/screen/pages/home_page.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/sharedpref.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart'; // Import theme.dart
import '../../core/models/bsnl_plan_model.dart';
import 'dart:developer' as developer;

// lib/src/controllers/premium_bsnl_plans_controller.dart
class PremiumBsnlPlansController extends GetxController {
  final ApiServices _apiService = Get.find<ApiServices>();

  final RxList<BsnlPlan> allPlans = <BsnlPlan>[].obs;
  final RxList<BsnlPlan> filteredPlans = <BsnlPlan>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isBackBtn = false.obs;
  final RxString selectedValidity = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    isLoading.value = true;
    try {
      // --- Ensure this method name matches your ApiServices class ---
      final List<BsnlPlan>? fetchedPlans =
          await _apiService.fetchBsnlPlan(); // <-- Check this method name
      allPlans.assignAll(fetchedPlans ?? []);
      applyFilters();
    } catch (e) {
      developer.log('Error fetching BSNL plans: $e');
      BaseApiService().showSnackbar(
        'Error',
        'Failed to load plans. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    if (selectedValidity.value == 'All') {
      filteredPlans.assignAll(allPlans);
    } else {
      filteredPlans.assignAll(
        allPlans
            .where((plan) => plan.validity == selectedValidity.value)
            .toList(),
      );
    }
  }

  Future<void> requestPlanUpdate(BsnlPlan plan) async {
    if (plan.id == null) {
      BaseApiService().showSnackbar('Error', 'Invalid plan selected.');
      return;
    }

    final int? userId = await AppSharedPref.instance.getUserID();
    final String? mobileStr = await AppSharedPref.instance.getMobileNumber();

    if (userId == null || mobileStr == null) {
      BaseApiService().showSnackbar(
        'Error',
        'User information not found. Please log in.',
        isError: true,
      );
      return;
    }

    int mobileNumberInt;
    try {
      mobileNumberInt = int.parse(mobileStr);
    } catch (e) {
      developer.log("Error parsing mobile number '$mobileStr': $e");
      BaseApiService().showSnackbar(
        'Error',
        'Invalid mobile number format.',
        isError: true,
      );
      return;
    }

    BaseApiService().showSnackbar(
      'Requesting...',
      'Sending plan update request...',
      // isError: true,
    );

    final bool success = await _apiService.updatePlanRequest(
      id: userId,
      requestPlanId: plan.id!,
      customerId: userId,
      registerMobileNo: mobileNumberInt,
    );

    if (success) {
      BaseApiService().showSnackbar(
        'Success',
        'Plan update request sent successfully!',
      );
    }
  }

  List<String> get validityOptions {
    Set<String> validities = {'All'};

    for (var plan in allPlans) {
      if (plan.validity != null) {
        String normalized = _normalizeValidity(plan.validity!);
        if (normalized.isNotEmpty) {
          validities.add(normalized);
        }
      }
    }

    // Sort: 'All' first, then by numeric value
    List<String> sorted =
        validities.toList()..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;

          // Extract number from "X Month(s)"
          int numA = int.tryParse(a.split(RegExp(r'\s+'))[0]) ?? 0;
          int numB = int.tryParse(b.split(RegExp(r'\s+'))[0]) ?? 0;
          return numA.compareTo(numB);
        });

    return sorted;
  }

  // Helper to normalize strings like "1month", "12 months", "24Months" → "1 Month", "12 Months", etc.
  String _normalizeValidity(String input) {
    // Trim and collapse extra spaces
    String clean = input.trim().replaceAll(RegExp(r'\s+'), ' ');

    // Match patterns: optional space, number, optional "month"/"months" (case-insensitive)
    RegExp pattern = RegExp(r'^(\d+)\s*(month|months)?$', caseSensitive: false);
    Match? match = pattern.firstMatch(clean);

    if (match != null) {
      int number = int.parse(match.group(1)!);
      String word = number == 1 ? 'Month' : 'Months';
      return '$number $word';
    }

    // If it doesn't match, return as title-cased fallback (e.g., "Annual" → "Annual")
    return _toTitleCase(clean);
  }

  String _toTitleCase(String input) {
    return input
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}

// lib/src/ui/screen/premium_bsnl_plans_screen.dart
class PremiumBsnlPlansScreen extends StatefulWidget {
  @override
  _PremiumBsnlPlansScreenState createState() => _PremiumBsnlPlansScreenState();
}

class _PremiumBsnlPlansScreenState extends State<PremiumBsnlPlansScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late final PremiumBsnlPlansController _controller = Get.put(
    PremiumBsnlPlansController(),
  );
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.isBackBtn.value = Get.previousRoute.isNotEmpty;
    // Wrap the entire screen content with ScreenUtilInit
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Use your design's base size
      minTextAdapt: true, // Enable text adaptation
      splitScreenMode: true, // Enable for split screen if needed
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [_buildSliverAppBar(), _buildPlansList()],
              ),
              _buildFloatingFilterButton(),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      leading: Obx(() {
        return ScaffoldController().currentIndex.value == 1
            ? IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.backgroundLight,
                size: 24.sp, // Make leading icon responsive
              ),
            )
            : const SizedBox();
      }),
      expandedHeight: 280.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'BSNL PLANS',
          style: AppText.bodyLarge.copyWith(
            // Use AppText style
            color: Colors.white,

            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
              ),
            ),
            Positioned(
              top: -50.w,
              right: -30.w,
              child: Container(
                width: 150.w,
                height: 150.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -80.h,
              left: -50.w,
              child: Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 60.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Iconsax.wifi,
                    size: 60.sp,
                    color: Colors.white,
                  ).animate().shake(duration: 2000.ms),
                  SizedBox(height: 20.h),
                  Text(
                    'Lightning Fast Internet',
                    style: AppText.headingLarge.copyWith(
                      // Use AppText style
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 10.h),
                  Text(
                    'Choose the perfect plan for your needs',
                    style: AppText.bodyMedium.copyWith(
                      // Use AppText style
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final plans = _controller.filteredPlans;

      if (plans.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.search_normal,
                  size: 60.sp,
                  color: AppColors.textColorSecondary,
                ),
                SizedBox(height: 20.h),
                Text(
                  'No plans found',
                  style: AppText.headingSmall.copyWith(
                    // Use AppText style
                    color: AppColors.textColorPrimary,
                    fontSize:
                        18.sp, // AppText.headingSmall uses 14.sp, overridden here
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Try adjusting your filters',
                  style: AppText.bodyMedium.copyWith(
                    // Use AppText style
                    color: AppColors.textColorSecondary,
                    fontSize: 14.sp, // AppText.bodyMedium uses 14.sp
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final plan = plans[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20.w,
              10.h,
              20.w,
              index == plans.length - 1 ? 30.h : 10.h,
            ),
            child: _buildPremiumPlanCard(plan),
          );
        }, childCount: plans.length),
      );
    });
  }

  Widget _buildFloatingFilterButton() {
    return Positioned(
      bottom: 30.h,
      right: 20.w,
      child: FloatingActionButton(
        heroTag: null, // Prevents Hero animation conflicts
        onPressed: _showFilterDialog,
        backgroundColor: AppColors.primary,
        elevation: 5,
        child: Icon(Iconsax.filter, color: Colors.white, size: 24.sp),
      ),
    );
  }

  Widget _buildPremiumPlanCard(BsnlPlan plan) {
    final bool isNewCustomerPlan =
        plan.additionalBenefits != null &&
        plan.additionalBenefits!.toLowerCase().contains('new customer');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showPremiumPlanDetails(plan),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20.r),
            // gradient: LinearGradient(
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            //   colors: [AppColors.primary.withOpacity(0.1), Colors.white],
            // ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name and Price Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planName ?? 'Plan',
                            style: AppText.bodyLarge.copyWith(
                              // Use AppText style
                              color: AppColors.textColorPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isNewCustomerPlan)
                            Container(
                              margin: EdgeInsets.only(top: 5.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.orange[300]!,
                                  width: 1.w,
                                ),
                              ),
                              child: Text(
                                'NEW CUSTOMER',
                                style: AppText.labelSmall.copyWith(
                                  // Use AppText style
                                  color: Colors.orange[800],
                                  fontSize:
                                      10.sp, // AppText.labelSmall uses 12.sp
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        plan.formattedPrice,
                        style: AppText.labelMedium.copyWith(
                          // Use AppText style
                          color: Colors.white,
                          // fontSize: 16.sp, // AppText.bodyLarge uses 16.sp
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                // Features Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPlanFeature(
                      icon: Iconsax.flash,
                      label: 'Speed',
                      value: plan.formattedSpeed,
                    ),
                    _buildPlanFeature(
                      icon: Iconsax.document,
                      label: 'Data',
                      value: plan.formattedDataLimit,
                    ),
                    _buildPlanFeature(
                      icon: Iconsax.calendar,
                      label: 'Validity',
                      value: plan.formattedValidity,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanFeature({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              // Use AppText style
              color: AppColors.textColorSecondary,
              fontSize: 12.sp, // AppText.labelSmall uses 12.sp
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.bodySmall.copyWith(
              // Use AppText style
              color: AppColors.textColorPrimary,

              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showPremiumPlanDetails(BsnlPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20.r,
                spreadRadius: 5.r,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPlanDetailHeader(plan),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlanDetailGrid(plan),
                      SizedBox(height: 25.h),
                      _buildPlanBenefitsSection(plan),
                      SizedBox(height: 25.h),
                      _buildPlanChargesSection(plan),
                    ],
                  ),
                ),
              ),
              _buildPlanActionButtons(plan),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanDetailHeader(BsnlPlan plan) {
    return Container(
      padding: EdgeInsets.all(20.w).copyWith(top: 30.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.9), AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        children: [
          Text(
            plan.planName ?? 'Plan',
            style: AppText.headingLarge.copyWith(
              // Use AppText style
              color: Colors.white,

              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan.formattedPrice,
                style: AppText.headingLarge.copyWith(
                  // Use AppText style
                  color: Colors.white,
                  fontSize:
                      32.sp, // AppText.headingLarge uses 24.sp, overridden here
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  plan.formattedValidity,
                  style: AppText.button.copyWith(
                    // Use AppText style
                    color: AppColors.primary,
                    fontSize:
                        14.sp, // AppText.button uses 16.sp, overridden here
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetailGrid(BsnlPlan plan) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 15.w,
      mainAxisSpacing: 15.h,
      children: [
        _buildDetailFeature(
          icon: Iconsax.flash,
          title: 'Speed',
          value: plan.formattedSpeed,
        ),
        _buildDetailFeature(
          icon: Iconsax.document,
          title: 'Data Limit',
          value: plan.formattedDataLimit,
        ),
        _buildDetailFeature(
          icon: Iconsax.calendar,
          title: 'Validity',
          value: plan.formattedValidity,
        ),
        _buildDetailFeature(
          icon: Iconsax.call,
          title: 'Calls',
          value: 'Unlimited Local/STD',
        ),
      ],
    );
  }

  Widget _buildPlanBenefitsSection(BsnlPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Benefits',
          style: AppText.bodyMedium.copyWith(
            // Use AppText style
            color: AppColors.textColorPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 15.h),
        if (plan.benefitsList.isNotEmpty)
          ...plan.benefitsList.map((benefit) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Iconsax.tick_circle,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppText.bodyMedium.copyWith(
                        // Use AppText style
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        else
          Text(
            'No specific benefits listed.',
            style: AppText.bodyMedium.copyWith(
              // Use AppText style
              color: AppColors.textColorSecondary,
              fontSize: 14.sp, // AppText.bodyMedium uses 14.sp
            ),
          ),
      ],
    );
  }

  Widget _buildPlanChargesSection(BsnlPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call Charges',
          style: AppText.bodyMedium.copyWith(
            // Use AppText style
            color: AppColors.textColorPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 15.h),
        _buildChargeRow(
          'BSNL Network',
          '₹${plan.bsnlNetworkCharge?.toStringAsFixed(2) ?? "0.00"}',
        ),
        _buildChargeRow(
          'Other Networks',
          '₹${plan.otherNetworkCharge?.toStringAsFixed(2) ?? "0.00"}',
        ),
        _buildChargeRow(
          'ISD Rate / Min',
          '₹${plan.isdRate?.toStringAsFixed(2) ?? "0.00"}',
        ),
      ],
    );
  }

  Widget _buildChargeRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppText.bodyMedium.copyWith(
              // Use AppText style
              color: AppColors.textColorSecondary,
            ),
          ),
          Text(
            value,
            style: AppText.bodyMedium.copyWith(
              // Use AppText style
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActionButtons(BsnlPlan plan) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Inside _showPremiumPlanDetails, find the OutlinedButton for "Request This Plan Update"
              // Replace its `onPressed` with this:
              onPressed: () async {
                // Show the custom loading dialog
                _showRequestSendingDialog(context);

                try {
                  // Call the controller's method
                  await _controller.requestPlanUpdate(plan);
                  Get.find<HomeController>().refreshCustomerData();

                  // If successful, the controller shows a success snackbar.
                  // We just need to dismiss our loading dialog.
                } catch (e) {
                  // If there's an error, show an error snackbar (the controller might also handle this)
                  BaseApiService().showSnackbar(
                    'Error',
                    'Failed to send request. Please try again.',
                    isError: true,
                  );
                } finally {
                  // Always dismiss the loading dialog
                  Get.back(); // This will close the dialog shown by _showRequestSendingDialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.r),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.refresh, color: Colors.white, size: 24.sp),
                  SizedBox(width: 10.w),
                  Text(
                    'Request This Plan Update',
                    style: AppText.button.copyWith(
                      // Use AppText style
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 15.h),
          // SizedBox(
          //   width: double.infinity,
          //   child: OutlinedButton(
          //     onPressed: () {
          //       Get.back();
          //       BaseApiService().showSnackbar(
          //         'Info',
          //         'Direct subscription will be available soon.',
          //         backgroundColor: AppColors.info,
          //         colorText: Colors.white,
          //       );
          //     },
          //     style: OutlinedButton.styleFrom(
          //       side: BorderSide(color: AppColors.primary, width: 2.w),
          //       padding: EdgeInsets.symmetric(vertical: 16.h),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(15.r),
          //       ),
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Iconsax.shopping_cart,
          //           color: AppColors.primary,
          //           size: 24.sp,
          //         ),
          //         SizedBox(width: 10.w),
          //         Text(
          //           'Subscribe Now (Info)',
          //           style: TextStyle(
          //             fontSize: 16.sp,
          //             fontWeight: FontWeight.bold,
          //             color: AppColors.primary,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Add this method to your _PremiumBsnlPlansScreenState class
  void _showRequestSendingDialog(context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(30.w), // Make padding responsive
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                20.r,
              ), // Make radius responsive
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.r, // Make blur responsive
                  offset: Offset(0, 4.h), // Make offset responsive
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon (e.g., a spinning gear or a sending animation)
                // Replace the CircularProgressIndicator section with this:
                SizedBox(
                  width: 120.w, // Make width responsive
                  height: 120.h, // Make height responsive
                  child: Lottie.asset(
                    'assets/Ai-powered marketing tools abstract.json', // Path to your Lottie file
                    repeat: true,
                    animate: true,
                  ),
                ).animate().fadeIn(duration: 500.ms),

                SizedBox(height: 30.h), // Make height responsive
                // Title Text
                Text(
                  'Sending Request...',
                  style: AppText.headingMedium.copyWith(
                    // Use AppText style
                    color: AppColors.textColorPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                SizedBox(height: 15.h), // Make height responsive
                // Instructional Message
                Text(
                  'Your plan update request has been sent successfully!',
                  textAlign: TextAlign.center,
                  style: AppText.bodyMedium.copyWith(
                    // Use AppText style
                    color: AppColors.textColorSecondary,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                SizedBox(height: 10.h), // Make height responsive
                Text(
                  'Please wait while our team reviews your request. They will contact you shortly.',
                  textAlign: TextAlign.center,
                  style: AppText.bodySmall.copyWith(
                    // Use AppText style
                    color: AppColors.textColorSecondary,
                  ),
                ).animate().fadeIn(delay: 700.ms),
                SizedBox(height: 15.h), // Make height responsive
                // Optional: A small "Do not close this app" note
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 16.w,
                  ), // Make padding responsive
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      12.r,
                    ), // Make radius responsive
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: AppColors.info,
                      ), // Make icon size responsive
                      SizedBox(width: 8.w), // Make width responsive
                      Flexible(
                        child: Text(
                          'You can safely navigate away. We\'ll notify you via SMS.',
                          style: AppText.bodySmall.copyWith(
                            // Use AppText style
                            color: AppColors.info,
                            fontSize: 10.sp, // AppText.bodySmall uses 12.sp
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h), // Make height responsive
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Inside _showPremiumPlanDetails, find the OutlinedButton for "Request This Plan Update"
                    // Replace its `onPressed` with this:
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(); // This will close the dialog shown by pop-up
                      Navigator.of(
                        context,
                      ).pop(); // This will close the dialog shown by _showRequestSendingDialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon(Iconsax.refresh, color: Colors.white, size: 24.sp),
                        // SizedBox(width: 10.w),
                        Text(
                          'Okay',
                          style: AppText.button.copyWith(
                            // Use AppText style
                            color: Colors.white,
                            fontSize: 16.sp, // AppText.button uses 16.sp
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildDetailFeature({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ), // Make padding responsive
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r), // Make radius responsive
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.w,
        ), // Make border width responsive
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w, // Make width responsive
            height: 36.h, // Make height responsive
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18.sp,
              color: AppColors.primary,
            ), // Make icon size responsive
          ),
          SizedBox(width: 8.w), // Make width responsive
          Expanded(
            child: Column(
              mainAxisSize:
                  MainAxisSize
                      .min, // <-- Add this to make the Column only as tall as its children
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start, // <-- Align text to start for better readability
              children: [
                // --- REMOVE `Expanded` from here ---
                Text(
                  title,
                  style: AppText.labelSmall.copyWith(
                    // Use AppText style
                    color: AppColors.textColorSecondary,
                    fontSize: 10.sp, // AppText.labelSmall uses 12.sp
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1, // <-- Ensure title doesn't wrap
                  overflow:
                      TextOverflow
                          .ellipsis, // <-- Handle very long titles gracefully
                ),
                SizedBox(height: 2.h), // Make height responsive
                Text(
                  value,
                  style: AppText.labelSmall.copyWith(
                    // Use AppText style
                    color: AppColors.textColorPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 8.sp,
                  ),
                  maxLines: 2,
                  // overflow: TextOverflow.C,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r), // Make radius responsive
          ),
          title: Text(
            'Filter by Validity',
            style: AppText.headingMedium.copyWith(
              // Use AppText style
              color: AppColors.textColorPrimary,
              fontSize:
                  20.sp, // AppText.headingMedium uses 22.sp, overridden here
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: EdgeInsets.all(20.w), // Make padding responsive
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.w, // Make spacing responsive
                  runSpacing: 8.h, // Make run spacing responsive
                  children:
                      _controller.validityOptions.map((validity) {
                        print(validity);

                        return FilterChip(
                          label: Text(
                            validity,
                            style: AppText.bodyMedium.copyWith(
                              // Use AppText style
                              color: AppColors.textColorPrimary,
                              fontSize: 14.sp, // AppText.bodyMedium uses 14.sp
                            ),
                          ),
                          selected:
                              _controller.selectedValidity.value == validity,
                          onSelected: (bool selected) {
                            if (selected) {
                              _controller.selectedValidity.value = validity;
                              _controller.applyFilters();
                              Navigator.pop(
                                context,
                              ); // Close dialog after selection
                            }
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: AppText.bodyMedium.copyWith(
                            // Use AppText style
                            color:
                                _controller.selectedValidity.value == validity
                                    ? Colors.white
                                    : AppColors.textColorPrimary,
                            fontSize: 14.sp, // AppText.bodyMedium uses 14.sp
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10.r,
                            ), // Make radius responsive
                          ),
                          backgroundColor: Colors.grey[100],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: AppText.bodyMedium.copyWith(
                  // Use AppText style
                  color: AppColors.textColorPrimary,
                  fontSize: 14.sp, // AppText.bodyMedium uses 14.sp
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
