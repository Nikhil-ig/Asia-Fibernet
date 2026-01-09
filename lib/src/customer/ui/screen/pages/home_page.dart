// lib/src/ui/screen/home_screen.dart
import 'dart:async';

// Add this import at the top
import 'package:intl/intl.dart';

import 'package:asia_fibernet/src/auth/ui/scaffold_screen.dart';
import 'package:asia_fibernet/src/customer/ui/screen/profile_screen.dart';
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Import your models and services
import '../../../../auth/core/model/customer_details_model.dart';
import '../../../../services/apis/api_services.dart';
import '../../../../services/apis/base_api_service.dart';
import '../../../../services/sharedpref.dart';
// Import your theme
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
// Import other screens
import '../../../../theme/widgets/technician_task_card.dart';
import '../../../core/models/plan_request_status_model.dart';
import '../bsnl_screen.dart';

class HomeController extends GetxController {
  final ApiServices apiServices = ApiServices();
  final customer = Rx<CustomerDetails?>(null);
  final currentPlanName = ''.obs;
  final currentSpeed = ''.obs;
  final currentPrice = ''.obs;
  final usageText = ''.obs;
  final usageProgress = 0.0.obs;
  final isLoading = true.obs;
  final planRequestStatus = Rx<PlanRequestStatusModel?>(null);
  final isFetchingPlanStatus = false.obs;
  final ticketDashboardTaskToday = Rx<List?>(null);
  Timer? _refreshTimer;

  @override
  void onInit() async {
    super.onInit();
    ScaffoldController().fetchcustomerDetails();
    fetchCustomerData();
    fetchRelocationStatus();
    // ticketDashboardTaskToday.value =
    //     await apiServices.fetchCustomerTicketDashboardToday();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  final Rx<Map<String, dynamic>?> relocationStatus =
      ProfileController().relocationStatus;

  Future<void> fetchCustomerData() async {
    try {
      final int? userId = AppSharedPref.instance.getUserID();
      if (userId == null) return;

      final resultData = await apiServices.fetchCustomer();
      ticketDashboardTaskToday.value =
          await apiServices.fetchCustomerTicketDashboardToday();
      final result = resultData!;

      customer.value = result;
      currentPlanName.value = "Hello, ${result.contactName}";
      currentSpeed.value = "100 Mbps";
      currentPrice.value = "₹899/month";
      usageProgress.value = 0.65;
      usageText.value = "65% used";
      await fetchPlanRequestStatus(userId);
    } catch (e) {
      // BaseApiService().showSnackbar("Error", "Network issue: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasActivePlan {
    final customerData = customer.value;
    if (customerData == null) return false;
    return customerData.plan != null ||
        customerData.subscriptionPlan != null ||
        customerData.fmc != null ||
        customerData.bbUserId != null;
  }

  Future<void> fetchPlanRequestStatus(int customerId) async {
    isFetchingPlanStatus.value = true;
    try {
      final status = await apiServices.getPlanRequestStatus(customerId);
      planRequestStatus.value = status;
    } catch (e) {
      // BaseApiService().showSnackbar("Error", "Failed to load plan status");
    } finally {
      isFetchingPlanStatus.value = false;
    }
  }

  final isRelocationLoading = false.obs;

  Future<void> fetchRelocationStatus() async {
    final mobile = AppSharedPref.instance.getMobileNumber();
    if (mobile == null) return;

    isRelocationLoading(true);
    try {
      final data = await apiServices.checkRelocationStatus(mobile);
      if (data != null &&
          data.containsKey('data') &&
          data['status'] == 'success') {
        relocationStatus.value = data['data'];
      } else {
        relocationStatus.value = null;
      }
    } finally {
      isRelocationLoading(false);
    }
  }

  Future<void> refreshCustomerData() async {
    isLoading.value = true;
    await fetchCustomerData();
    await fetchRelocationStatus();
    isLoading.value = false;
  }
}

// --- Main Content Widget ---
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late PageController _pageController;
  Timer? _adTimer;
  int _currentAdIndex = 0;

  final List<Map<String, dynamic>> ads = [
    {
      'title': 'Upgrade to Ultra Speed',
      'description': 'Get 500Mbps at just ?1999/month',
      'color': AppColors.primary,
      'image': 'assets/slider-01.jpg',
    },
    {
      'title': 'Refer & Earn',
      'description': 'Get ₹500 cashback for each referral',
      'color': AppColors.secondary,
      'image': 'assets/slider-02.jpg',
    },
    {
      'title': 'Family Pack Special',
      'description': 'Add 4 connections at 30% discount',
      'color': AppColors.accent2,
      'image': 'assets/slider-03.jpg',
    },
  ];

  final List<Map<String, dynamic>> ottPlans = [
    {
      'name': 'Prasar Bharati Pack',
      'originalPrice': '₹30',
      'discountedPrice': '₹30',
      'platforms': ['DD National', 'DD Sports', 'DD Regional Channels'],
      'logos': ['assets/ott/dd_national.png'],
      'color': Color(0xFF0A5C8C),
      'gradient': [Color(0xFF0A5C8C), Color(0xFF1382C4)],
    },
    {
      'name': 'Starter Pack',
      'originalPrice': '₹99',
      'discountedPrice': '₹49',
      'platforms': ['Shemaroo', 'Hungama', 'Lionsgate', 'EPIC ON'],
      'logos': [
        'assets/ott/shemaroo.png',
        'assets/ott/hungama.png',
        'assets/ott/lionsgate.png',
        'assets/ott/epic.png',
      ],
      'color': Color(0xFF8E44AD),
      'gradient': [Color(0xFF8E44AD), Color(0xFF9B59B6)],
    },
    {
      'name': 'Full Pack',
      'originalPrice': '₹199',
      'discountedPrice': '₹199',
      'platforms': ['SonyLIV Premium', 'Disney+ Hotstar'],
      'logos': ['assets/ott/sonyliv.png', 'assets/ott/hotstar.png'],
      'color': Color(0xFF27AE60),
      'gradient': [Color(0xFF27AE60), Color(0xFF2ECC71)],
    },
    {
      'name': 'Premium Pack',
      'originalPrice': '₹249',
      'discountedPrice': '₹249',
      'platforms': [
        'SonyLIV Premium',
        'Shemaroo',
        'Hungama',
        'Lionsgate',
        'Disney+ Hotstar',
      ],
      'logos': [
        'assets/ott/sonyliv.png',
        'assets/ott/shemaroo.png',
        'assets/ott/hungama.png',
        'assets/ott/lionsgate.png',
        'assets/ott/hotstar.png',
      ],
      'color': Color(0xFFE74C3C),
      'gradient': [Color(0xFFE74C3C), Color(0xFFF39C12)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAdTimer();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final nextPage = (_currentAdIndex + 1) % ads.length;
      _pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentAdIndex = nextPage;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<HomeController>()
            ? Get.find<HomeController>()
            : Get.put(HomeController());

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: controller.refreshCustomerData,
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        return _buildHomeContent(controller);
      }),
    );
  }

  Widget _buildHomeContent(HomeController controller) {
    print(controller.ticketDashboardTaskToday.value);
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              _buildAdSwiper(),
              SizedBox(height: 24.h),

              ///TODO
              if (!(controller.ticketDashboardTaskToday.value == null ||
                  controller.ticketDashboardTaskToday.value == [])) ...[
                for (
                  int i = 0;
                  i < controller.ticketDashboardTaskToday.value!.length;
                  i++
                )
                  TechnicianTaskCard(
                    ticket: controller.ticketDashboardTaskToday.value![i],
                  ),
              ],
              SizedBox(height: 24.h),
              // OTT Plans Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildOTTPlansSection(),
              ),
              SizedBox(height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(() {
                  if (controller.relocationStatus.value != null) {
                    return _buildRelocationStatusCard(
                      controller.relocationStatus.value!,
                    );
                  }
                  return SizedBox();
                }),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildPlanRequestStatus(),
              ),
              DisconnectionStatusWidget(),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildCurrentPlan(),
          ),
        ),
      ],
    );
  }

  Widget _buildOTTPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OTT Entertainment Packs',
                    style: AppText.headingMedium.copyWith(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.backgroundDark,
                    ),
                  ),
                  // Container(
                  //   padding: EdgeInsets.symmetric(
                  //     horizontal: 12.w,
                  //     vertical: 6.h,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     gradient: LinearGradient(
                  //       colors: [AppColors.primary, AppColors.secondary],
                  //       begin: Alignment.topLeft,
                  //       end: Alignment.bottomRight,
                  //     ),
                  //     borderRadius: BorderRadius.circular(20.r),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: AppColors.primary.withOpacity(0.3),
                  //         blurRadius: 8.r,
                  //         offset: Offset(0, 4.h),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         Icons.local_fire_department,
                  //         size: 16.r,
                  //         color: Colors.white,
                  //       ),
                  //       SizedBox(width: 6.w),
                  //       Text(
                  //         'Trending Now',
                  //         style: AppText.labelSmall.copyWith(
                  //           color: Colors.white,
                  //           fontWeight: FontWeight.w700,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Choose from our curated entertainment bundles',
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                  // fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Plans Carousel
        Container(
          height: 340.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: BouncingScrollPhysics(),
            itemCount: ottPlans.length,
            padding: EdgeInsets.only(left: 16.w, right: 8.w),
            itemBuilder: (context, index) {
              final plan = ottPlans[index];
              final hasDiscount =
                  plan['originalPrice'] != plan['discountedPrice'];
              final isPopular = index == 1; // Mark second item as popular

              return Container(
                width: 300.w,
                margin: EdgeInsets.only(right: 16.w, bottom: 8.h),
                child: Stack(
                  children: [
                    // Main Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              plan['gradient'][0],
                              plan['gradient'][1].withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Plan Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      plan['name'],
                                      style: AppText.headingMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        'SAVE',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              SizedBox(height: 16.h),

                              // Price Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDiscount)
                                    Row(
                                      children: [
                                        Text(
                                          plan['originalPrice'],
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6.r,
                                            ),
                                          ),
                                          child: Text(
                                            '${_calculateDiscountPercentage(plan['originalPrice'], plan['discountedPrice'])}% OFF',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: plan['color'],
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        plan['discountedPrice'],
                                        style: TextStyle(
                                          fontSize: 32.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 0.9,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: 4.h,
                                          left: 4.w,
                                        ),
                                        child: Text(
                                          '/month',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 20.h),

                              // Platforms List
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'INCLUDED PLATFORMS:',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.6),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 12.h),
                                    Flexible(
                                      child: Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: List.generate(
                                          plan['platforms'].length,
                                          (i) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12.w,
                                              vertical: 6.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Text(
                                              plan['platforms'][i],
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // SizedBox(height: 20.h),

                              // // Platform Icons
                              // Container(
                              //   height: 50.h,
                              //   decoration: BoxDecoration(
                              //     borderRadius: BorderRadius.circular(12.r),
                              //     color: Colors.white.withOpacity(0.1),
                              //   ),
                              //   child: Row(
                              //     mainAxisAlignment:
                              //         MainAxisAlignment.spaceEvenly,
                              //     children: List.generate(
                              //       min(plan['logos'].length, 4),
                              //       (i) => Container(
                              //         width: 36.w,
                              //         height: 36.h,
                              //         decoration: BoxDecoration(
                              //           shape: BoxShape.circle,
                              //           color: Colors.white,
                              //           boxShadow: [
                              //             BoxShadow(
                              //               color: Colors.black.withOpacity(
                              //                 0.1,
                              //               ),
                              //               blurRadius: 8.r,
                              //               offset: Offset(0, 4.h),
                              //             ),
                              //           ],
                              //         ),
                              //         child: Center(
                              //           child: Icon(
                              //             Icons.tv,
                              //             size: 20.r,
                              //             color: plan['color'],
                              //           ),
                              //         ),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(height: 20.h),

                              // Subscribe Button
                              ElevatedButton(
                                onPressed: () {
                                  _showRequestSendingDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: plan['color'],
                                  minimumSize: Size(double.infinity, 52.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  elevation: 4,
                                  shadowColor: plan['color'].withOpacity(0.3),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_checkout,
                                      size: 20.r,
                                      color: plan['color'],
                                    ),
                                    SizedBox(width: 10.w),
                                    Flexible(
                                      child: Text(
                                        'Subscribe Now',
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18.r,
                                      color: plan['color'],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Popular Badge
                    // if (isPopular)
                    //   Positioned(
                    //     top: -0.h,
                    //     right: 20.w,
                    //     child: Container(
                    //       padding: EdgeInsets.symmetric(
                    //         horizontal: 16.w,
                    //         vertical: 6.h,
                    //       ),
                    //       decoration: BoxDecoration(
                    //         gradient: LinearGradient(
                    //           colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    //           begin: Alignment.topLeft,
                    //           end: Alignment.bottomRight,
                    //         ),
                    //         borderRadius: BorderRadius.circular(12.r),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: Colors.orange.withOpacity(0.3),
                    //             blurRadius: 8.r,
                    //             offset: Offset(0, 4.h),
                    //           ),
                    //         ],
                    //       ),
                    //       child: Row(
                    //         mainAxisSize: MainAxisSize.min,
                    //         children: [
                    //           Icon(Icons.star, size: 14.r, color: Colors.white),
                    //           SizedBox(width: 4.w),
                    //           Text(
                    //             'MOST POPULAR',
                    //             style: TextStyle(
                    //               fontSize: 10.sp,
                    //               color: Colors.white,
                    //               fontWeight: FontWeight.w900,
                    //               letterSpacing: 0.8,
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              );
            },
          ),
        ),

        SizedBox(height: 20.h),

        //   // Info Banner
        //   Padding(
        //     padding: EdgeInsets.symmetric(horizontal: 16.w),
        //     child: Container(
        //       padding: EdgeInsets.all(16.r),
        //       decoration: BoxDecoration(
        //         gradient: LinearGradient(
        //           colors: [
        //             AppColors.primary.withOpacity(0.08),
        //             AppColors.secondary.withOpacity(0.08),
        //           ],
        //           begin: Alignment.topLeft,
        //           end: Alignment.bottomRight,
        //         ),
        //         borderRadius: BorderRadius.circular(20.r),
        //         border: Border.all(
        //           color: AppColors.primary.withOpacity(0.2),
        //           width: 1,
        //         ),
        //       ),
        //       child: Row(
        //         children: [
        //           Container(
        //             padding: EdgeInsets.all(10.r),
        //             decoration: BoxDecoration(
        //               shape: BoxShape.circle,
        //               color: AppColors.primary.withOpacity(0.1),
        //             ),
        //             child: Icon(
        //               Icons.info_outline,
        //               size: 20.r,
        //               color: AppColors.primary,
        //             ),
        //           ),
        //           SizedBox(width: 12.w),
        //           Expanded(
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text(
        //                   'Why choose our OTT packs?',
        //                   style: AppText.labelMedium.copyWith(
        //                     color: AppColors.backgroundDark,
        //                     fontWeight: FontWeight.w700,
        //                   ),
        //                 ),
        //                 SizedBox(height: 4.h),
        //                 Text(
        //                   '‚Ä¢ All packs include HD streaming ‚Ä¢ No hidden charges ‚Ä¢ Cancel anytime',
        //                   style: AppText.labelSmall.copyWith(
        //                     color: AppColors.textColorLight,
        //                     fontSize: 11.sp,
        //                   ),
        //                   maxLines: 2,
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  // Helper function to calculate discount percentage
  int _calculateDiscountPercentage(String original, String discounted) {
    try {
      final originalPrice = int.parse(original.replaceAll('₹', '').trim());
      final discountedPrice = int.parse(discounted.replaceAll('₹', '').trim());
      return (((originalPrice - discountedPrice) / originalPrice) * 100)
          .round();
    } catch (e) {
      return 0;
    }
  }

  // Dialog function
  void _showSubscriptionDialog(String planName) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 60.r, color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'Added to Cart!',
                style: AppText.headingSmall.copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '$planName has been added to your subscription cart',
                textAlign: TextAlign.center,
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textColorLight,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: Text('Continue Browsing'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        // Navigate to cart
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text('Go to Cart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.transaction_minus,
                      color: AppColors.primary,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Relocation Request',
                    style: AppText.headingSmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
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
              SizedBox(height: 16.h),
              Divider(
                color: AppColors.dividerColor.withOpacity(0.5),
                height: 1,
              ),
              SizedBox(height: 16.h),
              _item(
                Iconsax.location,
                'Old Address',
                data['old_address'] ?? 'N/A',
              ),
              _item(
                Iconsax.location,
                'New Address',
                data['new_address'] ?? 'N/A',
              ),
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
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _item(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20.r,
            color: AppColors.textColorSecondary.withOpacity(0.7),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textColorSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
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

  Widget _buildPlanRequestStatus() {
    final controller = Get.find<HomeController>();
    return Obx(() {
      final status = controller.planRequestStatus.value;
      final isFetching = controller.isFetchingPlanStatus.value;
      if (isFetching) {
        return _buildPlanStatusShimmer();
      }
      if (status == null || status.requestedPlan == null) {
        return SizedBox();
      }

      final requestedPlan = status.requestedPlan!;
      final currentPlan = status.currentPlan;
      Color statusColor;
      IconData statusIcon;
      String statusText;
      switch (status.status.toLowerCase()) {
        case 'completed':
          statusColor = AppColors.success;
          statusIcon = Icons.check_circle;
          statusText = "Approved";
          break;
        case 'rejected':
          statusColor = AppColors.error;
          statusIcon = Icons.cancel;
          statusText = "Rejected";
          break;
        case 'pending':
        default:
          statusColor = AppColors.warning;
          statusIcon = Icons.hourglass_empty;
          statusText = "Pending Approval";
      }

      return Container(
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 20.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 24.r),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Plan Change Request",
                            style: AppText.headingSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textColorPrimary,
                            ),
                          ),
                          Text(
                            statusText,
                            style: AppText.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (status.status.toLowerCase() == 'Completed')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: AppColors.warning,
                            size: 16.r,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "Processing",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              if (currentPlan != null && currentPlan.planName != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Plan",
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.textColorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.dividerColor.withOpacity(0.5),
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  currentPlan.planName!,
                                  style: AppText.labelMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textColorPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (currentPlan.price != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "₹${currentPlan.price}",
                                    style: AppText.labelMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (currentPlan.speed != null)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    size: 16.r,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    currentPlan.speed!,
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
                    SizedBox(height: 20.h),
                  ],
                ),
              Text(
                "Requested Plan",
                style: AppText.labelMedium.copyWith(
                  color: AppColors.textColorSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withOpacity(0.2),
                      statusColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            requestedPlan.planName!,
                            style: AppText.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textColorPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (requestedPlan.price != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              "₹${requestedPlan.price}",
                              style: AppText.labelMedium.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (requestedPlan.speed != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Row(
                          children: [
                            Icon(Icons.speed, size: 16.r, color: statusColor),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                requestedPlan.speed!,
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (requestedPlan.dataLimit != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.data_usage,
                              size: 16.r,
                              color: statusColor,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                requestedPlan.dataLimit!,
                                overflow: TextOverflow.clip,
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.dividerColor.withOpacity(0.5),
                    width: 1.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request Details",
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.textColorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16.r,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Requested on: ${status.addedDateTime.split(' ')[0]}",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (status.planRemark != null &&
                        status.planRemark!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note,
                              size: 16.r,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                status.planRemark!,
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (statusText != 'Approved') ...[
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final int? userId =
                              AppSharedPref.instance.getUserID();
                          if (userId != null) {
                            controller.fetchPlanRequestStatus(userId);
                            controller.fetchRelocationStatus();
                          }
                        },
                        icon: Icon(
                          Icons.refresh,
                          size: 18.r,
                          color: AppColors.backgroundLight,
                        ),
                        label: Text(
                          "Refresh Status",
                          style: AppText.button.copyWith(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 48.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    if (status.status.toLowerCase() == 'pending')
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.help_outline,
                            color: AppColors.primary,
                            size: 20.r,
                          ),
                          onPressed: () {
                            BaseApiService().showSnackbar(
                              "Need Help?",
                              "Your plan change request is being processed. Contact support if you have any questions.",
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
              SizedBox(height: 24.h),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPlanStatusShimmer() {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200.w,
                      height: 20.h,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 120.w,
                      height: 16.h,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180.w,
                    height: 20.h,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: 120.w,
                    height: 16.h,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 150.w,
                    height: 16.h,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlan() {
    final controller = Get.find<HomeController>();
    if (!controller.hasActivePlan) {
      if (controller.planRequestStatus.value == null) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.warning.withOpacity(0.05), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 1.w,
            ),
          ),
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.warning,
                    size: 28.r,
                  ),
                  SizedBox(width: 12.w),
                  Flexible(
                    child: Text(
                      "No Active Plan",
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                "You don't have an active internet plan yet. Choose a plan to get started!",
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                  overflow: TextOverflow.clip,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.bsnlPlans,
                    arguments: {"isBackBtn": true},
                  );
                },
                icon: Icon(Icons.upgrade, size: 18.r),
                label: Text(
                  "Choose a Plan",
                  style: AppText.button.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ],
          ),
        );
      }
      return SizedBox();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.03),
            AppColors.primary.withOpacity(0.01),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1.w,
        ),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  controller.currentPlanName.value,
                  style: AppText.headingSmall.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  controller.currentPrice.value,
                  style: AppText.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildPlanDetail(
                Icons.speed,
                "Speed",
                controller.currentSpeed.value,
              ),
              SizedBox(width: 20.w),
              _buildPlanDetail(Icons.data_usage, "Data", "Unlimited"),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildPlanDetail(Icons.calendar_today, "Validity", "30 days"),
              SizedBox(width: 20.w),
              _buildPlanDetail(Icons.update, "Renewal", "15 Jan 2025"),
            ],
          ),
          SizedBox(height: 24.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Data Usage",
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                  Text(
                    controller.usageText.value,
                    style: AppText.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: controller.usageProgress.value,
                  backgroundColor: AppColors.inputBackground,
                  minHeight: 10.h,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(controller.usageProgress.value),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "0 GB",
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.textColorHint,
                    ),
                  ),
                  Text(
                    "1000 GB",
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.textColorHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PremiumBsnlPlansScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    "Upgrade Plan",
                    style: AppText.button.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () {
                    controller.fetchCustomerData();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdSwiper() {
    return Column(
      children: [
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: ads.length,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(ads[index]['image']),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20.r,
                            offset: Offset(0, 10.h),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        SmoothPageIndicator(
          controller: _pageController,
          count: ads.length,
          effect: ExpandingDotsEffect(
            activeDotColor: AppColors.primary,
            dotColor: AppColors.textColorHint.withOpacity(0.3),
            dotHeight: 8.h,
            dotWidth: 8.w,
            expansionFactor: 3,
            spacing: 6.w,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10.r,
              spreadRadius: 2.r,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18.r),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppText.labelSmall.copyWith(
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                    color: AppColors.backgroundDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double value) {
    if (value < 0.5) return AppColors.success;
    if (value < 0.8) return AppColors.warning;
    return AppColors.error;
  }

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
                      // Navigator.of(
                      //   context,
                      // ).pop(); // This will close the dialog shown by _showRequestSendingDialog
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
}

// Disconnection Status Widget
class DisconnectionStatusWidget extends StatelessWidget {
  const DisconnectionStatusWidget({super.key});

  // Dummy disconnection status data
  final Map<String, dynamic> _dummyStatus = const {
    'status': 'pending',
    'request_date': '2024-01-15',
    'preferred_date': '2024-01-30',
    'reason': 'Moving to new location',
    'ticket_no': 'DCN-2024-0015',
    'remarks': 'Awaiting confirmation from technical team',
    'alternate_contact': '9876543210',
    'charges': '0',
  };

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.close;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
      default:
        return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _dummyStatus['status'];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withOpacity(0.05),
                statusColor.withOpacity(0.02),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: statusColor.withOpacity(0.1), width: 1.w),
          ),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disconnection Request',
                          style: AppText.bodyMedium.copyWith(
                            color: AppColors.textColorPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Status: $statusText',
                          style: AppText.bodySmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
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
              SizedBox(height: 16.h),
              Divider(
                color: AppColors.dividerColor.withOpacity(0.3),
                height: 1,
              ),
              SizedBox(height: 16.h),

              // Details
              _buildDetailRow(
                Icons.confirmation_number,
                'Ticket Number',
                _dummyStatus['ticket_no'],
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                Icons.calendar_today,
                'Request Date',
                _formatDate(_dummyStatus['request_date']),
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(
                Icons.event,
                'Preferred Date',
                _formatDate(_dummyStatus['preferred_date']),
              ),
              SizedBox(height: 12.h),
              _buildDetailRow(Icons.info, 'Reason', _dummyStatus['reason']),
              SizedBox(height: 12.h),
              _buildDetailRow(
                Icons.phone,
                'Alternate Contact',
                _dummyStatus['alternate_contact'],
              ),

              if (_dummyStatus['remarks'] != null &&
                  _dummyStatus['remarks'].isNotEmpty) ...[
                SizedBox(height: 12.h),
                _buildDetailRow(Icons.note, 'Remarks', _dummyStatus['remarks']),
              ],

              SizedBox(height: 12.h),
              _buildDetailRow(
                Icons.money,
                'Charges',
                '₹${_dummyStatus['charges']}',
              ),

              SizedBox(height: 20.h),

              // Action Buttons
              if (status == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Cancel request action
                          BaseApiService().showSnackbar(
                            "Info",
                            "Cancellation feature would be implemented here",
                          );
                        },
                        icon: Icon(
                          Icons.close,
                          size: 18.r,
                          color: AppColors.backgroundLight,
                        ),
                        label: Text(
                          'Cancel Request',
                          style: AppText.button.copyWith(fontSize: 14.sp),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                        onPressed: () {
                          // Refresh status action
                          BaseApiService().showSnackbar(
                            "Refreshing",
                            "Disconnection status refreshed",
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else if (status == 'rejected' || status == 'cancelled') ...[
                ElevatedButton(
                  onPressed: () {
                    // Resubmit request action
                    BaseApiService().showSnackbar(
                      "Info",
                      "Resubmit feature would be implemented here",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit New Request',
                    style: AppText.button.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ] else if (status == 'completed') ...[
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Your disconnection request has been completed. '
                          'Service was disconnected on ${_formatDate(_dummyStatus['preferred_date'])}.',
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 8.h),

              // Info Note
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.info.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16.r, color: AppColors.info),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'For any queries regarding your disconnection request, '
                        'please contact our customer support team.',
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.textColorSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20.r,
          color: AppColors.textColorSecondary.withOpacity(0.7),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
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
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
