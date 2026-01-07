// ui/screen/unregistered_user_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:animate_do/animate_do.dart';
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:iconsax/iconsax.dart';

import '/src/services/routes.dart';
import '../../services/apis/api_services.dart';
import '../../services/sharedpref.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/models/bsnl_plan_model.dart';
import '../core/models/unregistered_kyc_status_model.dart';
// import '../bsnl_screen.dart'; // Import for PremiumBsnlPlansScreen

class UnregisteredUserController extends GetxController {
  final ApiServices _apiService = Get.find<ApiServices>();
  final BaseApiService baseApiService = Get.find<BaseApiService>();
  // Ad Swiper State
  final currentPageIndex = 0.obs;
  late PageController pageController;
  Timer? adTimer;

  // KYC State
  final profileImage = Rx<File?>(null);
  final idFrontImage = Rx<File?>(null);
  final idBackImage = Rx<File?>(null);
  final isSubmitting = false.obs;
  final currentStep = 0.obs;
  final selectedIdType = 'Aadhaar Card'.obs;

  // Text Editing Controllers
  final nameController = TextEditingController();
  final idNumberController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Available ID types
  final List<String> idTypes = ['Aadhaar Card', 'PAN Card', 'Address Proof'];
  // Inside UnregisteredUserController class
  final RxList<BsnlPlan> newCustomerPlans = <BsnlPlan>[].obs;
  final RxBool isPlansLoading = false.obs;
  KycStatusResponse? kycStatus;
  Timer? _statusCheckTimer;
  RxBool _isCheckingStatus = false.obs;

  @override
  void onInit() async {
    super.onInit();
    pageController = PageController(viewportFraction: 0.92);

    startAdTimer();
    fetchNewCustomerPlans(); // 👈 Add this
    _startStatusChecking();

    // kycChecking();
  }

  Future<void> fetchNewCustomerPlans() async {
    isPlansLoading(true);
    try {
      final List<BsnlPlan>? allPlans = await _apiService.fetchBsnlPlan();
      if (allPlans != null) {
        // ✅ Filter only plans with "For New Customers Only"
        final filtered =
            allPlans.where((plan) {
              return plan.additionalBenefits?.trim().toLowerCase() ==
                  'for new customers only';
            }).toList();
        newCustomerPlans.assignAll(filtered);
      }
    } catch (e) {
      baseApiService.showSnackbar("Error", "Failed to load plans");
    } finally {
      isPlansLoading(false);
    }
  }

  void _startStatusChecking() {
    // Check status immediately
    _checkKycStatus();

    // Set up periodic checking every 30 seconds
    _statusCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkKycStatus();
    });
  }

  Future<void> _checkKycStatus() async {
    if (_isCheckingStatus.value) return;

    _isCheckingStatus = true.obs;
    try {
      final status = await _apiService.checkKycStatus(
        AppSharedPref.instance.getMobileNumber()!,
      );

      if (status!.data.documents.isNotEmpty) {
        // KYC is approved, navigate to main screen
        _statusCheckTimer?.cancel();
        Get.offAllNamed(AppRoutes.finalKYCReview);
        // print("GO to next page");
      } else {
        kycStatus = status;
      }
    } catch (e) {
      print("Error checking KYC status: $e");
    } finally {
      _isCheckingStatus = false.obs;
    }
  }

  // Example ads data
  final List<Map<String, dynamic>> ads = [
    {
      'title': 'Upgrade to Ultra Speed',
      'description': 'Get 500Mbps at just ₹1999/month',
      'image': 'assets/slider-01.jpg',
    },
    {
      'title': 'Refer & Earn',
      'description': 'Get ₹500 cashback for each referral',
      'image': 'assets/slider-02.jpg',
    },
    {
      'title': 'Family Pack Special',
      'description': 'Add 4 connections at 30% discount',
      'image': 'assets/slider-03.jpg',
    },
  ];

  // Plan data

  void startAdTimer() {
    adTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!pageController.hasClients) return;
      final nextPage = (currentPageIndex.value + 1) % ads.length;
      pageController.animateToPage(
        nextPage,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      currentPageIndex.value = nextPage;
    });
  }

  void onPageChanged(int index) {
    currentPageIndex.value = index;
  }

  Future<void> pickImage(ImageSource source, String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      if (type == 'profile') {
        profileImage.value = File(pickedFile.path);
      } else if (type == 'id_front') {
        idFrontImage.value = File(pickedFile.path);
      } else if (type == 'id_back') {
        idBackImage.value = File(pickedFile.path);
      }
    }
  }

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }
  // Inside UnregisteredUserController class

  // Make sure ApiServices is imported and injected
  // import '../../../services/api_services.dart'; // Adjust path
  // final ApiServices _apiService = Get.find<ApiServices>(); // Add this if not already present

  Future<void> submitKyc({
    required int selectedPlan, // Pass the selected plan
    required String fullName,
    required String idNumber,
    required String address,
    required File profileImageFile,
    required File idFrontImageFile,
    required File idAddressImageFile,
    File? idBackImageFile, // Nullable
    required String idType, // Pass the selected ID type string
  }) async {
    // Use the passed idType to determine if back image is required
    if (idType == 'Aadhaar Card' && idBackImageFile == null) {
      baseApiService.showSnackbar(
        "Incomplete",
        "Please upload the back side of your Aadhaar card.",
      );
      return; // Stop submission
    }

    isSubmitting.value = true;
    try {
      // Get mobile number - adjust based on how you store it
      // Example: String? mobileNumber = await AppSharedPref.instance.getMobileNumber();
      String mobileNumber =
          AppSharedPref.instance
              .getMobileNumber()!; // Placeholder - Replace with actual logic to get mobile

      // Determine the document type for the API based on idType
      String apiDocumentType = idType; // Often the same, but map if needed
      if (idType == 'PAN Card') {
        apiDocumentType = 'PAN';
      } else if (idType == 'Driving License') {
        apiDocumentType = 'Driving License';
      } else if (idType == 'Passport') {
        apiDocumentType = 'Passport';
      } else if (idType == 'Aadhaar Card') {
        apiDocumentType = 'Aadhar'; // API expects 'Aadhar'
      }

      // Call the API service method (assuming it's correctly implemented in ApiServices)
      final int? registrationId = await _apiService.uploadNewCustomerDocuments(
        mobileNo: mobileNumber,
        fullName: fullName,
        idNo: idNumber,
        address: address,
        profileImage: profileImageFile,
        idFrontImage: idFrontImageFile,
        idBackImage: idBackImageFile, // Can be null
        addressProofImage: idAddressImageFile, // Add logic if needed
        desiredPlan: "Plan",
        idType: apiDocumentType,
      );

      if (registrationId != null) {
        // Success!
        baseApiService.showSnackbar(
          "Success",
          "KYC submitted successfully! Your documents are under verification.",
        );
        // Close the KYC screen
        Get.toNamed(AppRoutes.kycReview);
        Get.back(result: true); // Indicate success if needed
      } else {
        // Error already handled by ApiServices, but log for debugging
        print("Controller: KYC submission failed, registration ID was null.");
      }
    } catch (e) {
      print("Controller Exception during KYC submission: $e");
      baseApiService.showSnackbar(
        "Error",
        "An unexpected error occurred during submission. Please try again.",
      );
    } finally {
      isSubmitting.value = false; // Always reset submitting state
    }
  }

  void logOut() async {
    await _apiService.logOutDialog();
  }

  @override
  void onClose() {
    pageController.dispose();
    adTimer?.cancel();
    nameController.dispose();
    idNumberController.dispose();
    addressController.dispose();
    super.onClose();
  }
}

class UnregisteredUserScreen extends StatefulWidget {
  const UnregisteredUserScreen({Key? key}) : super(key: key);

  @override
  State<UnregisteredUserScreen> createState() => _UnregisteredUserScreenState();
}

class _UnregisteredUserScreenState extends State<UnregisteredUserScreen> {
  late UnregisteredUserController controller; // Local controller instance

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      UnregisteredUserController(),
    ); // Initialize and put controller
  }

  @override
  void dispose() {
    Get.delete<UnregisteredUserController>(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Obx to rebuild when controller state changes if needed, or directly access controller properties
    return Scaffold(body: SafeArea(child: _buildNoPlanView()));
  }

  Widget _buildAdSwiper() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller.pageController,
            itemCount: controller.ads.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller.pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (controller.pageController.position.haveDimensions) {
                    value = controller.pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 5),
                          ),
                        ],
                        image: DecorationImage(
                          image: AssetImage(controller.ads[index]['image']),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          // Obx to update indicator
          child: SmoothPageIndicator(
            controller: controller.pageController,
            count: controller.ads.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.textColorHint.withOpacity(0.3),
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPlanView() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          // Welcome header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeIn(
                  duration: Duration(milliseconds: 600),
                  child: Text(
                    'Welcome to',
                    style: AppText.bodyLarge.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
                FadeIn(
                  duration: Duration(milliseconds: 800),
                  child: Text(
                    'Asia Fibernet!',
                    style: AppText.headingLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                FadeIn(
                  duration: Duration(milliseconds: 1000),
                  child: Text(
                    'Choose a plan to get started with high-speed internet',
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Ad Swiper
          _buildAdSwiper(),
          SizedBox(height: 30),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Plans Section
                FadeIn(
                  duration: Duration(milliseconds: 1200),
                  child: Text(
                    'Featured Plans',
                    style: AppText.headingMedium.copyWith(
                      color: AppColors.textColorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Plan Cards
                _buildPlanCards(),
                SizedBox(height: 40),
                // Benefits Section
                _buildBenefitsSection(),
                SizedBox(height: 40),
                // Testimonials
                _buildTestimonialsSection(),
                SizedBox(height: 30),
                // Logout button
                Center(
                  child: FadeIn(
                    duration: Duration(milliseconds: 1500),
                    child: OutlinedButton.icon(
                      onPressed:
                          () => controller.logOut(), // Use controller method
                      icon: Icon(Iconsax.logout, size: 18),
                      label: Text("Log out"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textColorSecondary,
                        side: BorderSide(color: AppColors.dividerColor),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    return Obx(() {
      if (controller.isPlansLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.newCustomerPlans.isEmpty) {
        return Center(
          child: Text(
            "No plans available for new customers",
            style: AppText.bodyMedium.copyWith(color: AppColors.textColorHint),
          ),
        );
      }

      return Column(
        children:
            controller.newCustomerPlans.map((plan) {
              return FadeIn(
                duration: Duration(
                  milliseconds:
                      1000 + controller.newCustomerPlans.indexOf(plan) * 200,
                ),
                child: _buildPlanCardFromModel(plan),
              );
            }).toList(),
      );
    });
  }

  Widget _buildPlanCardFromModel(BsnlPlan plan) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15.r,
            spreadRadius: 2.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Plan header
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.planName ?? 'New Customer Plan',
                        style: AppText.headingSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        plan.formattedPrice,
                        style: AppText.bodyLarge.copyWith(
                          color: AppColors.primary,
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
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "NEW",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Plan details
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                _buildPlanFeature(
                  Iconsax.speedometer,
                  "Speed",
                  plan.formattedSpeed,
                  AppColors.primary,
                ),
                SizedBox(height: 15.h),
                _buildPlanFeature(
                  Iconsax.data,
                  "Data",
                  plan.formattedDataLimit,
                  AppColors.primary,
                ),
                SizedBox(height: 20.h),
                Divider(color: AppColors.dividerColor),
                SizedBox(height: 15.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Benefits:",
                      style: AppText.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...plan.benefitsList.map((benefit) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.tick_circle,
                              color: AppColors.primary,
                              size: 18.r,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                benefit,
                                style: AppText.bodySmall.copyWith(
                                  color: AppColors.textColorSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
          // Select button
          Container(
            width: double.infinity,
            height: 50.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Color.lerp(AppColors.primary, Colors.black, 0.1)!,
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(18.r),
              ),
            ),
            child: TextButton(
              onPressed: () => _showPlanConfirmationDialog(plan),
              child: Text(
                "Select Plan",
                style: AppText.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeIn(
          duration: Duration(milliseconds: 1200),
          child: Text(
            'Why Choose Us?',
            style: AppText.headingMedium.copyWith(
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
        FadeIn(
          duration: Duration(milliseconds: 1400),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  Iconsax.speedometer,
                  "Blazing Fast Speeds",
                  "Experience seamless browsing, streaming, and gaming",
                  AppColors.primary,
                ),
                SizedBox(height: 20),
                _buildBenefitItem(
                  Iconsax.shield_tick,
                  "Secure Connection",
                  "Advanced security features to keep your data safe",
                  AppColors.success,
                ),
                SizedBox(height: 20),
                _buildBenefitItem(
                  Iconsax.headphone,
                  "24/7 Support",
                  "Our technical team is always available to assist you",
                  AppColors.secondary,
                ),
                SizedBox(height: 20),
                _buildBenefitItem(
                  Iconsax.receipt,
                  "No Hidden Charges",
                  "Transparent pricing with no surprises on your bill",
                  AppColors.accent1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeIn(
          duration: Duration(milliseconds: 1200),
          child: Text(
            'What Our Customers Say',
            style: AppText.headingMedium.copyWith(
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
        FadeIn(
          duration: Duration(milliseconds: 1400),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: 8),
                _buildTestimonialCard(
                  "Rahul Sharma",
                  "Excellent service! The internet speed is consistently high even during peak hours.",
                  5,
                ),
                SizedBox(width: 15),
                _buildTestimonialCard(
                  "Priya Patel",
                  "The installation was quick and the customer support is very responsive.",
                  5,
                ),
                SizedBox(width: 15),
                _buildTestimonialCard(
                  "Amit Kumar",
                  "Great value for money. I'm very satisfied with my broadband connection.",
                  4,
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard(String name, String review, int stars) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Iconsax.star1,
                color: index < stars ? Colors.amber : Colors.grey[300],
                size: 18,
              );
            }),
          ),
          SizedBox(height: 15),
          Text(
            review,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorPrimary,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 15),
          Text(
            "- $name",
            style: AppText.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          // ✅ WRAP COLUMN IN EXPANDED
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                  overflow: TextOverflow.ellipsis, // Optional safety
                ),
                Text(
                  value,
                  style: AppText.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                  overflow: TextOverflow.clip, // Prevents overflow
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // void _showPlanConfirmationDialog(Map<String, dynamic> plan) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         child: Container(
  //           padding: EdgeInsets.all(25),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 80,
  //                 height: 80,
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary.withOpacity(0.1),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: Icon(
  //                   Iconsax.verify,
  //                   color: AppColors.primary,
  //                   size: 40,
  //                 ),
  //               ),
  //               SizedBox(height: 20),
  //               Text(
  //                 "Complete Your KYC",
  //                 style: AppText.headingSmall.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                   color: AppColors.textColorPrimary,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: 10),
  //               Text(
  //                 "Your KYC is pending verification",
  //                 style: AppText.bodyMedium.copyWith(
  //                   color: AppColors.textColorSecondary,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: 20),
  //               Container(
  //                 padding: EdgeInsets.all(15),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary.withOpacity(0.05),
  //                   borderRadius: BorderRadius.circular(15),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Iconsax.speedometer, color: AppColors.primary),
  //                     SizedBox(width: 10),
  //                     Expanded(
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             plan['name'],
  //                             style: AppText.bodyLarge.copyWith(
  //                               fontWeight: FontWeight.bold,
  //                               color: AppColors.textColorPrimary,
  //                             ),
  //                           ),
  //                           Text(
  //                             plan['price'],
  //                             style: AppText.bodyMedium.copyWith(
  //                               color: AppColors.primary,
  //                               fontWeight: FontWeight.w600,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(height: 20),
  //               Text(
  //                 "Complete KYC verification to activate your plan",
  //                 style: AppText.bodyMedium.copyWith(
  //                   color: AppColors.textColorSecondary,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //               SizedBox(height: 25),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: OutlinedButton(
  //                       onPressed: () => Navigator.pop(context),
  //                       style: OutlinedButton.styleFrom(
  //                         foregroundColor: AppColors.textColorSecondary,
  //                         padding: EdgeInsets.symmetric(vertical: 15),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                       ),
  //                       child: Text(
  //                         "Later",
  //                         style: AppText.bodySmall.copyWith(
  //                           color: AppColors.textColorSecondary,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(width: 15),
  //                   Expanded(
  //                     child: ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         Get.to(
  //                           () => EnhancedKycVerificationScreen(
  //                             selectedPlan: plan,
  //                             onKycSuccess: () {
  //                               // Handle success if needed
  //                             },
  //                           ),
  //                         );
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: AppColors.primary,
  //                         foregroundColor: Colors.white,
  //                         padding: EdgeInsets.symmetric(vertical: 15),
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                       ),
  //                       child: Text(
  //                         "Complete Now",
  //                         style: AppText.bodySmall.copyWith(
  //                           color: AppColors.backgroundLight,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showPlanConfirmationDialog(BsnlPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Container(
            padding: EdgeInsets.all(25.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.verify,
                    color: AppColors.primary,
                    size: 40.r,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Complete Your KYC",
                  style: AppText.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColorPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  "Your KYC is pending verification",
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Iconsax.speedometer, color: AppColors.primary),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.planName ?? 'Plan',
                              style: AppText.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                            Text(
                              plan.formattedPrice,
                              style: AppText.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Complete KYC verification to activate your plan",
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textColorSecondary,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Later",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.textColorSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Get.to(
                            () => EnhancedKycVerificationScreen(
                              selectedPlan: {
                                'name': plan.planName,
                                'price': plan.formattedPrice,
                                'speed': plan.formattedSpeed,
                              },
                              billingName:
                                  controller
                                      .kycStatus!
                                      .data
                                      .registration
                                      .fullName,
                              installationAddress:
                                  controller
                                      .kycStatus!
                                      .data
                                      .registration
                                      .streetAddress,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          "Complete Now",
                          style: AppText.bodySmall.copyWith(
                            color: AppColors.backgroundLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// lib/src/customer/ui/screen/enhanced_kyc_verification_screen.dart
// Enhanced KYC Controller with beautiful animations
class EnhancedKycController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final ApiServices _apiService = Get.find<ApiServices>();
  final BaseApiService baseApiService = Get.find<BaseApiService>();

  // State
  var profileImage = Rx<File?>(null);
  var idFrontImage = Rx<File?>(null);
  var idBackImage = Rx<File?>(null);
  var idAddressImage = Rx<File?>(null);
  var idRentAddresImage = Rx<File?>(null);
  var profileImageType = ''.obs;
  var idFrontImageType = ''.obs;
  var idBackImageType = ''.obs;
  var idAddressImageType = ''.obs;
  var idRentAddresImageType = ''.obs;
  var isSubmitting = false.obs;
  var currentStep = 0.obs;
  var selectedIdType = 'Aadhaar Card'.obs;
  var name = ''.obs;
  var idNumber = ''.obs;
  var billingAddress = ''.obs;
  var isBillingSameAsInstallation = true.obs;
  var isIDRentAddresImage = false.obs;
  KycStatusResponse? checkKycStatus;

  // Animation controllers
  late AnimationController _stepAnimationController;
  late Animation<double> _stepSlideAnimation;
  late Animation<double> _stepFadeAnimation;

  // ID Types with icons
  final List<Map<String, dynamic>> idTypes = [
    {
      'name': 'Aadhaar Card',
      'icon': Iconsax.card,
      'description': '12-digit unique identity number',
    },
    // {
    //   'name': 'PAN Card',
    //   'icon': Iconsax.card_pos,
    //   'description': 'Permanent Account Number',
    // },
    {
      'name': 'Driving License',
      'icon': Iconsax.driving,
      'description': 'Government issued license',
    },
    {
      'name': 'Passport',
      'icon': Iconsax.card,
      'description': 'International travel document',
    },
  ];

  @override
  void onInit() async {
    super.onInit();
    _stepAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _stepSlideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _stepFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _stepAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    ever(currentStep, (_) {
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    });

    checkKycStatus = await _apiService.checkKycStatus(
      AppSharedPref.instance.getMobileNumber()!,
    );
  }

  @override
  void onClose() {
    _stepAnimationController.dispose();
    super.onClose();
  }

  // Validation
  String? validateIdNumber(String idType, String value) {
    if (value.isEmpty) return 'Required';

    switch (idType) {
      case 'Aadhaar Card':
        if (!RegExp(r'^\d{12}$').hasMatch(value)) {
          return 'Aadhaar must be 12 digits';
        }
        break;

      case 'PAN Card':
        if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
          return 'Invalid PAN format (e.g., ABCDE1234F)';
        }
        break;

      case 'Driving License':
        if (value.length < 10) {
          return 'DL number seems too short';
        }
        break;

      case 'Passport':
        // Indian Passport format: 1 letter followed by 7 digits (e.g., A1234567)
        if (!RegExp(r'^[A-PR-WYa-pr-wy][0-9]{7}$').hasMatch(value)) {
          return 'Invalid Passport format (e.g., A1234567)';
        }
        break;
    }

    return null;
  }

  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> submitKyc({
    required Map<String, dynamic> selectedPlan,
    required String installationAddress,
  }) async {
    // Validate all steps
    if (!_validateCurrentStep()) return;

    isSubmitting.value = true;
    try {
      final mobile = AppSharedPref.instance.getMobileNumber()!;
      String apiDocType = selectedIdType.value;
      if (apiDocType == 'Aadhaar Card')
        apiDocType = 'Aadhar';
      else if (apiDocType == 'PAN Card')
        apiDocType = 'PAN';

      final regId = await _apiService.uploadNewCustomerDocuments(
        mobileNo: mobile,
        fullName: name.value,
        idNo: idNumber.value,
        address:
            isBillingSameAsInstallation.value
                ? installationAddress
                : billingAddress.value,
        profileImage: profileImage.value!,
        idFrontImage: idFrontImage.value!,
        idBackImage: idBackImage.value,
        addressProofImage: idAddressImage.value!,
        addressRentProofImage: idRentAddresImage.value,
        desiredPlan: selectedPlan['name'] ?? 'Plan',
        idType: apiDocType,
      );

      if (regId != null) {
        // Show success animation
        _showSuccessAnimation();
      } else {
        baseApiService.showSnackbar("Error", "Submission failed. Try again.");
      }
    } catch (e) {
      baseApiService.showSnackbar("Error", "$e");
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        if (name.value.isEmpty) {
          baseApiService.showSnackbar(
            "Incomplete",
            "Please enter your full name",
          );
          return false;
        }
        if (idNumber.value.isEmpty) {
          baseApiService.showSnackbar("Incomplete", "Please enter ID number");
          return false;
        }
        final error = validateIdNumber(selectedIdType.value, idNumber.value);
        if (error != null) {
          baseApiService.showSnackbar("Invalid", error);
          return false;
        }
        break;
      case 1:
        if (profileImage.value == null) {
          baseApiService.showSnackbar("Incomplete", "Please upload your photo");
          return false;
        }
        if (idFrontImage.value == null) {
          baseApiService.showSnackbar("Incomplete", "Please upload ID front");
          return false;
        }
        if (selectedIdType.value == 'Aadhaar Card' &&
            idBackImage.value == null) {
          baseApiService.showSnackbar(
            "Incomplete",
            "Please upload Aadhaar back",
          );
          return false;
        }
        if (idAddressImage.value == null) {
          baseApiService.showSnackbar(
            "Incomplete",
            "Please upload address proof",
          );
          return false;
        }
        break;
    }
    return true;
  }

  void _showSuccessAnimation() {
    Get.dialog(
      _SuccessAnimationDialog(
        onComplete: () {
          Get.offAllNamed(AppRoutes.kycReview);
        },
      ),
    );
  }
}

// Beautiful KYC Verification Screen
class EnhancedKycVerificationScreen extends StatelessWidget {
  final Map<String, dynamic> selectedPlan;
  final String? installationAddress;
  final String? billingName;

  const EnhancedKycVerificationScreen({
    Key? key,
    required this.selectedPlan,
    this.installationAddress,
    this.billingName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EnhancedKycController>(
      init: EnhancedKycController(),
      builder: (controller) {
        installationAddress ??
            controller.checkKycStatus?.data.registration.streetAddress;
        // Initialize billing address
        if (controller.billingAddress.value.isEmpty &&
            installationAddress != null) {
          controller.billingAddress.value = installationAddress!;
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: _EnhancedKycView(
            controller: controller,
            selectedPlan: selectedPlan,
            installationAddress: installationAddress,
            billingName: billingName,
          ),
        );
      },
    );
  }
}

class _EnhancedKycView extends StatefulWidget {
  final EnhancedKycController controller;
  final Map<String, dynamic> selectedPlan;
  final String? installationAddress;
  final String? billingName;

  const _EnhancedKycView({
    required this.controller,
    required this.selectedPlan,
    this.installationAddress,
    this.billingName,
  });

  @override
  State<_EnhancedKycView> createState() => _EnhancedKycViewState();
}

class _EnhancedKycViewState extends State<_EnhancedKycView> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Beautiful Header
        _buildHeader(),

        // Animated Step Indicator
        _buildStepIndicator(),

        // Content Area
        Expanded(
          child: Obx(() {
            return AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: _buildCurrentStep(),
            );
          }),
        ),

        // Navigation Buttons
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 60.h,
        bottom: 30.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.arrow_left,
                    color: Colors.white,
                    size: 22.w,
                  ),
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Verification',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Complete your identity verification',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.security_safe,
                  color: Colors.white,
                  size: 22.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Progress text
          Obx(() {
            final steps = ['Personal Info', 'Documents', 'Review'];
            return Text(
              'Step ${widget.controller.currentStep.value + 1} of 3: ${steps[widget.controller.currentStep.value]}',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Obx(() {
        return Row(
          children: List.generate(3, (index) {
            final isActive = index <= widget.controller.currentStep.value;
            final isCompleted = index < widget.controller.currentStep.value;

            return Expanded(
              child: Row(
                children: [
                  // if (index > 0)
                  Expanded(
                    child: Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        gradient:
                            isActive
                                ? LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                )
                                : null,
                        color: isActive ? null : AppColors.dividerColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),

                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient:
                          isCompleted
                              ? LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.successDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : isActive
                              ? LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color: isActive ? null : AppColors.dividerColor,
                      shape: BoxShape.circle,
                      boxShadow:
                          isActive
                              ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? Icon(
                                Iconsax.tick_circle,
                                color: Colors.white,
                                size: 18.w,
                              )
                              : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color:
                                      isActive
                                          ? Colors.white
                                          : AppColors.textColorSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (widget.controller.currentStep.value) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildDocumentUploadStep();
      case 2:
        return _buildReviewStep();
      default:
        return SizedBox();
    }
  }

  Widget _buildPersonalInfoStep() {
    return SizedBox(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // Personal Info Card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Iconsax.user,
                    title: 'Personal Information',
                    subtitle: 'Tell us about yourself',
                  ),
                  SizedBox(height: 25.h),

                  // Name Field
                  _buildAnimatedTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Iconsax.user,
                    onChanged: (v) => widget.controller.name.value = v,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 20.h),

                  // ID Type Selection
                  Text(
                    'Identity Document Type',
                    style: AppText.labelMedium.copyWith(
                      color: AppColors.textColorPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Obx(() {
                    return Column(
                      spacing: 10.w,
                      // runSpacing: 10.h,
                      children:
                          widget.controller.idTypes.map((idType) {
                            final isSelected =
                                widget.controller.selectedIdType.value ==
                                idType['name'];
                            return GestureDetector(
                              onTap:
                                  () =>
                                      widget.controller.selectedIdType.value =
                                          idType['name'],
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  gradient:
                                      isSelected
                                          ? LinearGradient(
                                            colors: [
                                              AppColors.primary.withOpacity(
                                                0.1,
                                              ),
                                              AppColors.primaryLight
                                                  .withOpacity(0.05),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                          : null,
                                  color:
                                      isSelected
                                          ? null
                                          : AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(15.r),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textColorHint,
                                    width: isSelected ? 2 : .5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.textColorSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        idType['icon'],
                                        color: Colors.white,
                                        size: 16.w,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          idType['name'],
                                          style: AppText.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : AppColors
                                                        .textColorPrimary,
                                          ),
                                        ),
                                        Text(
                                          idType['description'],
                                          style: AppText.bodySmall.copyWith(
                                            color: AppColors.textColorSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  }),
                  SizedBox(height: 20.h),

                  // ID Number Field
                  _buildAnimatedTextField(
                    label: 'ID Number',
                    hint: 'Enter your ID number',
                    icon: Iconsax.card,
                    onChanged: (v) => widget.controller.idNumber.value = v,
                    validator:
                        (v) => widget.controller.validateIdNumber(
                          widget.controller.selectedIdType.value,
                          v ?? '',
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Address Card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Iconsax.location,
                    title: 'Billing Address',
                    subtitle: 'Where should we send your bills?',
                  ),
                  SizedBox(height: 20.h),

                  Obx(() {
                    return Column(
                      children: [
                        // Same as installation checkbox
                        _buildCheckboxOption(
                          value:
                              widget
                                  .controller
                                  .isBillingSameAsInstallation
                                  .value,
                          onChanged: (v) {
                            widget
                                .controller
                                .isBillingSameAsInstallation
                                .value = v!;
                            if (v && widget.installationAddress != null) {
                              widget.controller.billingAddress.value =
                                  widget.installationAddress!;
                            }
                          },
                          title: 'Same as installation address',
                          subtitle:
                              widget.installationAddress ?? 'Not provided',
                        ),

                        if (!widget
                            .controller
                            .isBillingSameAsInstallation
                            .value) ...[
                          SizedBox(height: 20.h),
                          _buildAnimatedTextField(
                            label: 'Billing Address',
                            hint: 'Enter your billing address',
                            icon: Iconsax.map,
                            maxLines: 3,
                            onChanged:
                                (v) =>
                                    widget.controller.billingAddress.value = v,
                            validator:
                                (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ] else ...[
                          SizedBox(height: 15.h),
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  color: AppColors.success,
                                  size: 20.w,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Installation Address',
                                        style: AppText.labelSmall.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        widget.installationAddress ?? 'N/A',
                                        style: AppText.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadStep() {
    return AnimatedBuilder(
      animation: widget.controller._stepAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.controller._stepSlideAnimation.value),
          child: Opacity(
            opacity: widget.controller._stepFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Iconsax.gallery,
                    title: 'Document Upload',
                    subtitle: 'Upload clear images of your documents',
                  ),
                  SizedBox(height: 25.h),

                  _buildImageUploadCard(
                    title: 'Profile Photo',
                    subtitle: 'Clear front-facing photo',
                    file: widget.controller.profileImage.value,
                    type: 'profile',
                    isRequired: true,
                  ),
                  SizedBox(height: 20.h),

                  _buildImageUploadCard(
                    title: 'ID Front Side',
                    subtitle:
                        'Front of your ${widget.controller.selectedIdType.value}',
                    file: widget.controller.idFrontImage.value,
                    type: 'id_front',
                    isRequired: true,
                    isPdf: true,
                  ),
                  SizedBox(height: 20.h),

                  if (!widget.controller.idFrontImageType.value.contains(
                        'pdf',
                      ) ||
                      (widget.controller.selectedIdType.value ==
                          'Aadhaar Card'))
                    Column(
                      children: [
                        _buildImageUploadCard(
                          title: 'ID Back Side',
                          subtitle: 'Back of your Aadhaar card',
                          file: widget.controller.idBackImage.value,
                          type: 'id_back',
                          isRequired: true,
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),

                  _buildImageUploadCard(
                    title: 'Address Proof',
                    subtitle: 'Utility bill, bank statement, etc.',
                    file: widget.controller.idAddressImage.value,
                    type: 'id_address',
                    isRequired: true,
                    isPdf: true,
                  ),
                  SizedBox(height: 20.h),

                  _buildCheckboxOption(
                    value: widget.controller.isIDRentAddresImage.value,
                    onChanged:
                        (v) => widget.controller.isIDRentAddresImage.value = v!,
                    title: 'Rent address',
                    // subtitle: '',
                  ),
                  if (widget.controller.isIDRentAddresImage.value) ...[
                    SizedBox(height: 20.h),
                    _buildImageUploadCard(
                      title: 'Address Proof Back',
                      subtitle: 'Utility bill, bank statement, etc.',
                      file: widget.controller.idRentAddresImage.value,
                      type: 'id_rent_address',
                      isRequired: widget.controller.isIDRentAddresImage.value,
                      isPdf: true,
                    ),
                  ],
                ],
              ),
            ),

            // Upload Tips
            SizedBox(height: 20.h),
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: AppColors.warning,
                        size: 20.w,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Upload Tips',
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  _buildTipItem('Ensure all text is clear and readable'),
                  _buildTipItem('Avoid glare and shadows'),
                  _buildTipItem('Upload original documents, not screenshots'),
                  _buildTipItem('File size should be less than 5MB'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return AnimatedBuilder(
      animation: widget.controller._stepAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, widget.controller._stepSlideAnimation.value),
          child: Opacity(
            opacity: widget.controller._stepFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    icon: Iconsax.document_1,
                    title: 'Review Information',
                    subtitle: 'Verify all details before submission',
                  ),
                  SizedBox(height: 25.h),

                  // Personal Info Review
                  _buildReviewSection(
                    title: 'Personal Information',
                    items: [
                      _buildReviewItem(
                        'Full Name',
                        widget.controller.name.value,
                      ),
                      _buildReviewItem(
                        'ID Type',
                        widget.controller.selectedIdType.value,
                      ),
                      _buildReviewItem(
                        'ID Number',
                        widget.controller.idNumber.value,
                      ),
                    ],
                  ),

                  SizedBox(height: 25.h),

                  // Address Review
                  _buildReviewSection(
                    title: 'Billing Address',
                    items: [
                      _buildReviewItem(
                        'Address',
                        widget.controller.isBillingSameAsInstallation.value
                            ? 'Same as installation'
                            : widget.controller.billingAddress.value,
                      ),
                    ],
                  ),

                  SizedBox(height: 25.h),

                  // Documents Review
                  _buildReviewSection(
                    title: 'Documents',
                    items: [
                      _buildDocumentStatus(
                        'Profile Photo',
                        widget.controller.profileImage.value != null,
                      ),
                      _buildDocumentStatus(
                        'ID Front',
                        widget.controller.idFrontImage.value != null,
                      ),
                      if (!widget.controller.idFrontImageType.value.contains(
                            'pdf',
                          ) ||
                          (widget.controller.selectedIdType.value !=
                              'Driving License'))
                        _buildDocumentStatus(
                          'ID Back',
                          widget.controller.idBackImage.value != null,
                        ),
                      _buildDocumentStatus(
                        'Address Proof',
                        widget.controller.idAddressImage.value != null,
                      ),
                      if (widget.controller.isIDRentAddresImage.value)
                        _buildDocumentStatus(
                          'Address Proof back',
                          widget.controller.idRentAddresImage.value != null,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Selected Plan Info
            SizedBox(height: 20.h),
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.box, color: AppColors.primary, size: 20.w),
                      SizedBox(width: 10.w),
                      Text(
                        'Selected Plan',
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primaryLight.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.wifi,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.selectedPlan['name'] ?? 'Plan',
                                style: AppText.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (widget.selectedPlan['speed'] != null)
                                Text(
                                  '${widget.selectedPlan['speed']} • ${widget.selectedPlan['duration'] ?? ""}',
                                  style: AppText.bodySmall.copyWith(
                                    color: AppColors.textColorSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${widget.selectedPlan['price'] ?? ''}',
                          style: AppText.headingSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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
  }

  // Helper Widgets
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20.w),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hint,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
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
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            onChanged: onChanged,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Container(
                margin: EdgeInsets.only(right: 12.w, left: 16.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18.w),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption({
    required bool value,
    required Function(bool?) onChanged,
    required String title,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              value
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: value ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: value ? AppColors.primary : AppColors.dividerColor,
                  width: 2,
                ),
              ),
              child:
                  value
                      ? Icon(
                        Iconsax.tick_circle,
                        color: Colors.white,
                        size: 14.w,
                      )
                      : null,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textColorSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required String type,
    required bool isRequired,
    bool isPdf = false,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: file != null ? AppColors.success : AppColors.dividerColor,
          width: file != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
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
                  color: file != null ? AppColors.success : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  file != null ? Iconsax.tick_circle : Iconsax.gallery,
                  color: Colors.white,
                  size: 16.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppText.bodySmall.copyWith(
                        color: AppColors.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRequired)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Required',
                    style: AppText.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 15.h),

          // Image Preview/Upload Area
          GestureDetector(
            onTap: () => _showImageSourceDialog(type),
            child: Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12.r),
                image:
                    file != null
                        ? DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        )
                        : null,
                border: Border.all(
                  color:
                      file != null ? AppColors.success : AppColors.dividerColor,
                  width: 2,
                ),
              ),
              child:
                  file == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.gallery_add,
                              color: AppColors.primary,
                              size: 30.w,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tap to Upload',
                              style: AppText.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      : null,
            ),
          ),

          SizedBox(height: 15.h),

          // Upload Options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera, type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: Icon(Iconsax.camera, size: 18.w),
                  label: Text('Camera'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery, type),

                  style: ElevatedButton.styleFrom(
                    iconColor: AppColors.secondary,
                    backgroundColor: AppColors.secondary.withOpacity(0.1),
                    foregroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: Icon(Iconsax.gallery, size: 18.w),
                  label: Text('Gallery'),
                ),
              ),
            ],
          ),
          if (isPdf) ...[
            SizedBox(height: 10.h),
            ElevatedButton.icon(
              onPressed: () => _pickPdf(type),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(Get.width, 50),
                backgroundColor: AppColors.primaryLight.withOpacity(0.1),
                foregroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              icon: Icon(Iconsax.document, size: 18.w),
              label: Text('PDF'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 4.h),
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textColorSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
        ),
        SizedBox(height: 15.h),
        ...items,
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
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
                  value.isEmpty ? 'Not provided' : value,
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textColorPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatus(String label, bool uploaded) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Icon(
            uploaded ? Iconsax.tick_circle : Iconsax.close_circle,
            color: uploaded ? AppColors.success : AppColors.error,
            size: 20.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textColorPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color:
                  uploaded
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              uploaded ? 'Uploaded' : 'Missing',
              style: AppText.labelSmall.copyWith(
                color: uploaded ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            if (widget.controller.currentStep.value > 0)
              Expanded(
                child: Container(
                  height: 55.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.controller.previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.arrow_left,
                          color: Colors.grey.shade700,
                          size: 20.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'BACK',
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
            if (widget.controller.currentStep.value > 0) SizedBox(width: 15.w),
            Expanded(
              child: Container(
                height: 55.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      widget.controller.isSubmitting.value
                          ? null
                          : () {
                            if (widget.controller.currentStep.value < 2) {
                              if (widget.controller._validateCurrentStep()) {
                                widget.controller.nextStep();
                              }
                            } else {
                              widget.controller.submitKyc(
                                selectedPlan: widget.selectedPlan,
                                installationAddress:
                                    widget.installationAddress ?? '',
                              );
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                  child:
                      widget.controller.isSubmitting.value
                          ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.controller.currentStep.value < 2
                                    ? 'CONTINUE'
                                    : 'SUBMIT KYC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                widget.controller.currentStep.value < 2
                                    ? Iconsax.arrow_right
                                    : Iconsax.send_2,
                                color: Colors.white,
                                size: 20.w,
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showImageSourceDialog(String type) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.gallery_add,
                      color: AppColors.primary,
                      size: 24.w,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Upload Image',
                      style: AppText.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Iconsax.camera, color: AppColors.primary),
                title: Text('Take Photo'),
                onTap: () {
                  Get.back();
                  _pickImage(ImageSource.camera, type);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.gallery, color: AppColors.primary),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Get.back();
                  _pickImage(ImageSource.gallery, type);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final file = File(picked.path);
      String type0 = "jpg";

      switch (type) {
        case 'profile':
          widget.controller.profileImage.value = file;
          widget.controller.profileImageType.value = type0;
          break;
        case 'id_front':
          widget.controller.idFrontImage.value = file;
          widget.controller.idFrontImageType.value = type0;
          break;
        case 'id_back':
          widget.controller.idBackImage.value = file;
          widget.controller.idBackImageType.value = type0;
          break;
        case 'id_address':
          widget.controller.idAddressImage.value = file;
          widget.controller.idAddressImageType.value = type0;
          break;
        case 'id_rent_address':
          widget.controller.idRentAddresImage.value = file;
          widget.controller.idRentAddresImageType.value = type0;
          break;
      }
    }
  }

  Future<void> _pickPdf(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      String type0 = "pdf";

      switch (type) {
        case 'profile':
          widget.controller.profileImage.value = file;
          widget.controller.profileImageType.value = type0;
          break;
        case 'id_front':
          widget.controller.idFrontImage.value = file;
          widget.controller.idFrontImageType.value = type0;
          break;
        case 'id_back':
          widget.controller.idBackImage.value = file;
          widget.controller.idBackImageType.value = type0;
          break;
        case 'id_address':
          widget.controller.idAddressImage.value = file;
          widget.controller.idAddressImageType.value = type0;
          break;
        case 'id_rent_address':
          widget.controller.idRentAddresImage.value = file;
          widget.controller.idRentAddresImageType.value = type0;
          break;
      }
    } else {
      print('No PDF selected');
    }
  }
}

// Success Animation Dialog
class _SuccessAnimationDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _SuccessAnimationDialog({required this.onComplete});

  @override
  __SuccessAnimationDialogState createState() =>
      __SuccessAnimationDialogState();
}

class __SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      Future.delayed(Duration(seconds: 2), () {
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: EdgeInsets.all(40.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(30.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success, AppColors.successDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.tick_circle,
                    color: Colors.white,
                    size: 50.w,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  'KYC Submitted!',
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColorPrimary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Your documents are under verification.\nYou will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: AppColors.textColorSecondary,
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  width: double.infinity,
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success, AppColors.successDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                    ),
                    child: Text(
                      'GOT IT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
