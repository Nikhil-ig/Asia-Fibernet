// screens/referral_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil

// controllers/referral_controller.dart
// controllers/referral_controller.dart
import '../../../../services/apis/base_api_service.dart';
import '../../../core/models/referral_data_model.dart';
import '../../../../services/apis/api_services.dart';
import '../../../../services/sharedpref.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/theme.dart';
import 'package:confetti/confetti.dart'; // For celebration effect
import 'package:shimmer/shimmer.dart'; // For skeleton loading
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:flutter/services.dart'; // For clipboard
import 'package:url_launcher/url_launcher.dart';

class ReferralController extends GetxController {
  final ApiServices _apiServices = Get.find(); // Get the ApiServices instance
  // Referral data - now fetched from API
  final RxString referralCode = ''.obs; // Initialize empty
  final RxDouble totalEarnings = 0.0.obs; // Assuming earnings calculation
  final RxInt bonusPerReferral = 200.obs; // Static or from API
  final RxInt totalReferrals = 0.obs; // Count from referredUsers list
  // Loading states
  final RxBool isLoadingCode = false.obs;
  final RxBool isLoadingReferrals = false.obs;
  // Referred users list - now fetched from API
  final referredUsers = <ReferralDataModel>[].obs; // Use the model
  final ConfettiController confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  @override
  void onInit() {
    super.onInit();
    _loadData(); // Load data when controller initializes
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await loadReferralCode(); // Load the code first
    await loadReferralData(); // Then load the referrals
  }

  Future<void> loadReferralCode() async {
    final int? customerId = AppSharedPref.instance.getUserID();
    if (customerId == null) {
      BaseApiService().showSnackbar(
        "Error",
        "Customer ID not found. Please log in.",
        isError: true,
      );
      return;
    }
    isLoadingCode(true);
    try {
      final response = await _apiServices.generateReferralCode();
      if (response != null) {
        // Check the status returned by the API
        if (response['status'] == 'success' || response['status'] == 'exists') {
          referralCode.value = response['referral_code'] ?? '';
          // You might want to differentiate UI/messages based on 'success' vs 'exists'
          if (response['status'] == 'exists') {
            // Optional: Inform user code already existed
            // BaseApiService().showSnackbar("Info", "Referral code already exists.");
          }
        } else {
          final String message =
              response['message'] ?? 'Failed to generate code.';
          BaseApiService().showSnackbar("Error", message);
        }
      } else {
        BaseApiService().showSnackbar(
          "Error",
          "Failed to get referral code response.",
        );
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Exception loading referral code: $e",
      );
    } finally {
      isLoadingCode(false);
    }
  }

  Future<void> loadReferralData() async {
    final int? customerId = await AppSharedPref.instance.getUserID();
    if (customerId == null) {
      BaseApiService().showSnackbar(
        "Error",
        "Customer ID not found. Please log in.",
      );
      return;
    }
    isLoadingReferrals(true);
    try {
      // Fetch referrals (ensure the return type matches)
      // Make sure _apiServices.getReferralData returns Future<List<ReferralDataModel>?>
      final List<ReferralDataModel>? referrals = await _apiServices
          .getReferralData(customerId);
      if (referrals != null) {
        referredUsers.assignAll(referrals);
        totalReferrals(referrals.length); // Update the count (int)
        // --- FIX: Calculate earnings correctly ---
        // Convert the integer result to double before assigning
        double calculatedEarnings =
            (referrals.length * bonusPerReferral.value).toDouble();
        totalEarnings(calculatedEarnings); // Assign the double value
        // --- Or, more concisely: ---
        // totalEarnings((referrals.length * bonusPerReferral.value).toDouble());
      } else {
        // Handle case where API returns null (e.g., no data, error)
        referredUsers.clear();
        totalReferrals(0);
        totalEarnings(0.0); // Assign 0.0 (double) when no referrals
        // Optional: Show a message if needed
        // BaseApiService().showSnackbar("Info", "No referrals found.");
      }
    } catch (e) {
      referredUsers.clear();
      totalReferrals(0);
      totalEarnings(0.0); // Assign 0.0 (double) on error
      BaseApiService().showSnackbar(
        "Error",
        "Exception loading referral data: $e",
      );
    } finally {
      isLoadingReferrals(false);
    }
  }

  void copyToClipboard() {
    if (referralCode.value.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: referralCode.value));
      BaseApiService().showSnackbar(
        'Copied!',
        'Referral code copied to clipboard',
      );
    } else {
      BaseApiService().showSnackbar(
        'Error',
        'No referral code to copy',
        isError: true,
      );
    }
  }

  // Inside ReferralController class
  // --- Updated shareReferralCode method with error handling ---
  // Inside ReferralController
  String getShareMessage(String referralCode) {
    // Using a raw string (triple quotes) can sometimes help with formatting
    // SharePlus.instance.share(
    //   ShareParams(text: 'check out my website https://example.com'),
    // );
    return '''Hey! 🌐
Check out Asia Fibernet!
Use my code: $referralCode
We both get rewarded! 🎁
#FastInternet #ReferAndEarn''';
  }

  void shareReferralCode() {
    if (referralCode.value.isNotEmpty) {
      // final String subject = "Internet Invite 💌"; // Short subject
      try {
        // Attempt to share the message
        SharePlus.instance.share(
          ShareParams(
            text: getShareMessage(referralCode.value),
          ), // Use the message getter
          // subject: subject,
        );
        // Optional: Play a sound or haptic feedback on successful share initiation
        // SystemSound.play(SystemSoundType.click); // Requires import 'package:flutter/services.dart';
      } on PlatformException catch (e) {
        // Handle errors specifically related to the platform (e.g., sharing service not available)
        print("PlatformException during share: $e"); // Log for debugging
        BaseApiService().showSnackbar(
          'Sharing Failed',
          'Unable to share right now. Please try again later.',
          isError: true,
        );
      } catch (e) {
        // Handle any other unexpected errors during the share process
        print("Unexpected error during share: $e"); // Log for debugging
        BaseApiService().showSnackbar(
          'Error',
          'An unexpected error occurred while sharing.',
          isError: true,
        );
      }
    } else {
      // Handle the case where the referral code is empty or not loaded yet
      BaseApiService().showSnackbar(
        'No Code',
        'No referral code available to share.',
      );
    }
  }

  // ✅ NEW: Share directly on WhatsApp
  Future<void> shareReferralOnWhatsApp() async {
    if (referralCode.value.isEmpty) {
      BaseApiService().showSnackbar(
        'No Code',
        'No referral code available to share.',
      );
      return;
    }
    final String message = getShareMessage(referralCode.value);
    final String whatsappUrl =
        "https://wa.me/?text=${Uri.encodeComponent(message)}";
    try {
      final Uri url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Opens WhatsApp directly
        );
      } else {
        BaseApiService().showSnackbar(
          'WhatsApp Not Found',
          'Could not open WhatsApp. Please make sure it is installed.',
        );
      }
    } catch (e) {
      print("Error launching WhatsApp: $e");
      BaseApiService().showSnackbar(
        'Launch Error',
        'Failed to open WhatsApp. Please try again.',
      );
    }
  }

  // ... rest of the controller
  // Optional: Method to refresh data
  Future<void> refreshData() async {
    await _loadData(); // Reload both code and referrals
  }
}

// The ReferralUser class can be removed if you use ReferralDataModel directly
// Or keep it if you need a UI-specific model. If keeping, you'd map
// ReferralDataModel to ReferralUser in loadReferralData.
// For this example, we'll assume ReferralDataModel is sufficient.
class ReferralUser {
  final String name;
  final String joinDate;
  final String status; // Could derive from created_at or status if API provides
  final String plan; // Could derive from desired_plan or connection_type
  final String avatarUrl;

  ReferralUser({
    required this.name,
    required this.joinDate,
    required this.status,
    required this.plan,
    required this.avatarUrl,
  });

  // Optional: Factory method to create from ReferralDataModel
  factory ReferralUser.fromReferralData(ReferralDataModel data) {
    return ReferralUser(
      name: data.fullName ?? 'Unknown User',
      joinDate: _formatDate(data.createdAt) ?? 'Unknown Date',
      status: 'Active', // Placeholder, logic needed if API provides status
      plan: data.desiredPlan ?? data.connectionType ?? 'Unknown Plan',
      avatarUrl:
          'https://ui-avatars.com/api/?name=${data.fullName ?? "U"}&background=random', // Placeholder avatar
    );
  }

  static String? _formatDate(String? dateString) {
    if (dateString == null) return null;
    try {
      final DateTime date = DateTime.parse(dateString);
      return "${date.day} ${_getMonthName(date.month)} ${date.year}";
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}

// --- Update the ReferralScreen Widget ---
// ... (imports remain the same) ...
class ReferralScreen extends StatelessWidget {
  final ReferralController _controller = Get.find<ReferralController>();
  // final ReferralController _controller = Get.put(ReferralController());

  @override
  Widget build(BuildContext context) {
    // Wrap the content with ScreenUtilInit to provide sizing context
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Use your design's base size
      minTextAdapt: true, // Enable text adaptation
      splitScreenMode: true, // Enable for split screen if needed
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              "Referrals",
              style: TextStyle(
                color: AppColors.backgroundLight,
                fontSize: 18.sp, // Responsive font size for app bar title
              ),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: AppColors.backgroundLight),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // Background Decoration
                // Positioned(
                // top: 50,
                // right: -50,
                //   child: Container(
                //     width: 200,
                //     height: 200,
                //     decoration: BoxDecoration(
                //       shape: BoxShape.circle,
                //       gradient: RadialGradient(
                //         colors: [
                //           AppColors.primary.withOpacity(0.1),
                //           Colors.transparent,
                //         ],
                //         stops: [0.1, 1.0],
                //       ),
                //     ),
                //   ),
                // ),
                // Main Content
                RefreshIndicator(
                  onRefresh: _controller.refreshData,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // App Bar with Gradient
                      // SliverAppBar(
                      //   expandedHeight: 240,
                      //   flexibleSpace: FlexibleSpaceBar(
                      //     background: Container(
                      //       decoration: BoxDecoration(
                      //         gradient: LinearGradient(
                      //           colors: [AppColors.primary, AppColors.primaryDark],
                      //           begin: Alignment.topLeft,
                      //           end: Alignment.bottomRight,
                      //         ),
                      //         boxShadow: [
                      //           BoxShadow(
                      //             color: AppColors.primary.withOpacity(0.3),
                      //             blurRadius: 20,
                      //             spreadRadius: 2,
                      //           ),
                      //         ],
                      //       ),
                      //       child: Padding(
                      //         padding: const EdgeInsets.all(20),
                      //         child: Column(
                      //           mainAxisAlignment: MainAxisAlignment.end,
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             const Icon(
                      //               Icons.people_alt_outlined,
                      //               size: 40,
                      //               color: Colors.white,
                      //             ),
                      //             const SizedBox(height: 10),
                      //             Text(
                      //               'Refer & Earn',
                      //               style: AppText.headingLarge.copyWith(
                      //                 color: Colors.white,
                      //                 fontWeight: FontWeight.bold,
                      //                 shadows: [
                      //                   Shadow(
                      //                     color: Colors.black.withOpacity(0.1),
                      //                     blurRadius: 4,
                      //                     offset: const Offset(1, 1),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //             const SizedBox(height: 8),
                      //             Obx(
                      //               () => Text(
                      //                 'Invite friends and earn ₹${_controller.bonusPerReferral.value} for each successful referral',
                      //                 style: AppText.bodyMedium.copyWith(
                      //                   color: Colors.white.withOpacity(0.9),
                      //                 ),
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      //   pinned: true,
                      //   elevation: 0,
                      //   actions: [
                      //     IconButton(
                      //       icon: const Icon(Icons.info_outline, color: Colors.white),
                      //       onPressed: () => _showReferralInfoDialog(context),
                      //     ),
                      //   ],
                      // ),
                      // Main Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.r), // Responsive padding
                          child: Column(
                            children: [
                              // Referral Code Card
                              _buildReferralCard(context, _controller),
                              SizedBox(height: 24.h), // Responsive height
                              // Earnings Summary
                              _buildEarningsSummary(context, _controller),
                              SizedBox(height: 24.h), // Responsive height
                              // Referred Users Header
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.r,
                                ), // Responsive padding
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your Referrals',
                                      style: AppText.headingMedium.copyWith(
                                        color: AppColors.textColorPrimary,
                                      ),
                                    ),
                                    Obx(
                                      () =>
                                          _controller.isLoadingReferrals.value
                                              ? _buildShimmerCounter(context)
                                              : Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      12.w, // Responsive padding
                                                  vertical:
                                                      4.h, // Responsive padding
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ), // Responsive radius
                                                ),
                                                child: Text(
                                                  'Total: ${_controller.referredUsers.length}',
                                                  style: AppText.bodyMedium
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h), // Responsive height
                            ],
                          ),
                        ),
                      ),
                      // Referred Users List
                      Obx(() {
                        if (_controller.isLoadingReferrals.value) {
                          return SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildUserSkeleton(context),
                              childCount: 5,
                            ),
                          );
                        }
                        if (_controller.referredUsers.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(
                                40.r, // Responsive padding
                              ).copyWith(
                                bottom: 300.h,
                              ), // Responsive bottom padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.close_circle,
                                    size: 84.r, // Responsive icon size
                                    color: AppColors.textColorSecondary,
                                  ),
                                  SizedBox(height: 24.h), // Responsive height
                                  Text(
                                    'No referrals yet',
                                    style: AppText.headingMedium.copyWith(
                                      color: AppColors.textColorSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 12.h), // Responsive height
                                  Text(
                                    'Share your referral code to invite friends\nand start earning rewards!',
                                    textAlign: TextAlign.center,
                                    style: AppText.bodyMedium.copyWith(
                                      color: AppColors.textColorHint,
                                    ),
                                  ),
                                  SizedBox(height: 20.h), // Responsive height
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_controller
                                          .referralCode
                                          .value
                                          .isNotEmpty) {
                                        // Implement share functionality
                                        _controller.shareReferralCode();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ), // Responsive radius
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24.w, // Responsive padding
                                        vertical: 12.h, // Responsive padding
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text('Share Referral Code'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final referralData =
                                _controller.referredUsers[index];
                            final uiUser = ReferralUser.fromReferralData(
                              referralData,
                            );
                            return _buildUserCard(context, uiUser, index);
                          }, childCount: _controller.referredUsers.length),
                        );
                      }),
                      SliverToBoxAdapter(
                        child: SizedBox(height: 150.h),
                      ), // Responsive height
                    ],
                  ),
                ),
                // Confetti Effect
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _controller.confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      AppColors.primary,
                      AppColors.accent1,
                      AppColors.secondary,
                      Colors.white,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralCard(
    BuildContext context,
    ReferralController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r), // Responsive radius
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryDark.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15.r, // Responsive blur
            spreadRadius: 2.r, // Responsive spread
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r), // Responsive padding
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r), // Responsive padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 18.r, // Responsive icon size
                      ),
                    ),
                    SizedBox(width: 10.w), // Responsive width
                    Text(
                      'Your Unique Code',
                      style: AppText.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: Colors.white.withAlpha(225),
                    size: 20.r, // Responsive icon size
                  ),
                  onPressed: () => _showReferralInfoDialog(context),
                ),
              ],
            ),
            SizedBox(height: 16.h), // Responsive height
            Obx(
              () =>
                  controller.isLoadingCode.value
                      ? _buildCodeSkeleton(context)
                      : Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 16.h, // Responsive padding
                          horizontal: 24.w, // Responsive padding
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // Responsive radius
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: SelectableText(
                          selectionControls:
                              controller.referralCode.value.isNotEmpty
                                  ? null
                                  : EmptyTextSelectionControls(),
                          controller.referralCode.value.isNotEmpty
                              ? controller.referralCode.value
                              : '------',
                          style: TextStyle(
                            fontSize: 28.sp, // Responsive font size for code
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.w, // Responsive letter spacing
                            fontFamily: 'RobotoMono',
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4.r, // Responsive blur
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
            SizedBox(height: 24.h), // Responsive height
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => ElevatedButton.icon(
                      icon: Icon(
                        Icons.copy,
                        size: 20.sp,
                      ), // Responsive icon size
                      label: Text('Copy Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                        ), // Responsive padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // Responsive radius
                        ),
                        elevation: 2,
                      ),
                      onPressed:
                          controller.isLoadingCode.value ||
                                  controller.referralCode.value.isEmpty
                              ? null
                              : () {
                                controller.copyToClipboard();
                                _controller.confettiController.play();
                              },
                    ),
                  ),
                ),
                SizedBox(width: 15.w), // Responsive width
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.share,
                      size: 20.sp, // Responsive icon size
                      color: AppColors.backgroundLight,
                    ),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.backgroundLight,
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                      ), // Responsive padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12.r,
                        ), // Responsive radius
                        side: BorderSide(
                          color: AppColors.backgroundLight,
                          width: 1.w, // Responsive border width
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (controller.referralCode.value.isNotEmpty) {
                        // Implement share functionality
                        controller.shareReferralCode();
                        print("Tap");
                      } else {
                        BaseApiService().showSnackbar(
                          "Error",
                          "No referral code available to share.",
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h), // Responsive height
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 20.sp, // Responsive icon size
                  color: AppColors.backgroundLight,
                ),
                label: Text('What\'s App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.backgroundLight,
                  padding: EdgeInsets.symmetric(
                    vertical: 14.h,
                  ), // Responsive padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12.r,
                    ), // Responsive radius
                    side: BorderSide(
                      color: AppColors.backgroundLight,
                      width: 1.w, // Responsive border width
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  if (controller.referralCode.value.isNotEmpty) {
                    // Implement share functionality
                    controller.shareReferralOnWhatsApp();
                    print("Tap");
                  } else {
                    BaseApiService().showSnackbar(
                      "Error",
                      "No referral code available to share.",
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummary(
    BuildContext context,
    ReferralController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(20.r), // Responsive padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r), // Responsive radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15.r, // Responsive blur
            spreadRadius: 2.r, // Responsive spread
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(
        () =>
            controller.isLoadingReferrals.value
                ? _buildStatsSkeleton(context)
                : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          context,
                          'Total Earnings',
                          '₹${controller.totalEarnings.value.toStringAsFixed(0)}',
                          Icons.account_balance_wallet_rounded,
                          AppColors.primary,
                        ),
                        _buildStatItem(
                          context,
                          'Per Referral',
                          '₹${controller.bonusPerReferral.value}',
                          Icons.monetization_on_rounded,
                          AppColors.secondary,
                        ),
                        _buildStatItem(
                          context,
                          'Referrals',
                          '${controller.totalReferrals.value}',
                          Icons.people_alt_rounded,
                          AppColors.accent2,
                        ),
                      ],
                    ),
                    // const SizedBox(height: 16),
                    // LinearProgressIndicator(
                    //   value: controller.totalReferrals.value / 10,
                    //   // Example: 10 referrals = 100%
                    //   backgroundColor: AppColors.backgroundLight,
                    //   color: AppColors.primary,
                    //   minHeight: 8,
                    //   borderRadius: BorderRadius.circular(10),
                    // ),
                    // const SizedBox(height: 8),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(
                    //       'Progress',
                    //       style: AppText.labelSmall.copyWith(
                    //         color: AppColors.textColorSecondary,
                    //       ),
                    //     ),
                    //     Text(
                    //       '${(controller.totalReferrals.value / 10 * 100).toStringAsFixed(0)}%',
                    //       style: AppText.labelSmall.copyWith(
                    //         color: AppColors.primary,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.r), // Responsive padding
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24.r), // Responsive icon size
        ),
        SizedBox(height: 8.h), // Responsive height
        Text(
          value,
          style: AppText.headingSmall.copyWith(
            color: AppColors.textColorPrimary,
          ),
        ),
        SizedBox(height: 4.h), // Responsive height
        Text(
          title,
          style: AppText.labelSmall.copyWith(
            color: AppColors.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, ReferralUser user, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(
        horizontal: 16.w, // Responsive margin
        vertical: 8.h, // Responsive margin
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16.r), // Responsive radius
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r), // Responsive radius
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(16.r), // Responsive padding
            child: Row(
              children: [
                Container(
                  width: 50.w, // Responsive width
                  height: 50.h, // Responsive height
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.secondary.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0] : '?',
                      style: TextStyle(
                        fontSize: 20.sp, // Responsive font size for initials
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w), // Responsive width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppText.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp, // Adjusted responsive size
                        ),
                      ),
                      SizedBox(height: 4.h), // Responsive height
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14.sp, // Responsive icon size
                            color: AppColors.textColorHint,
                          ),
                          SizedBox(width: 4.w), // Responsive width
                          Text(
                            user.joinDate,
                            style: AppText.labelSmall.copyWith(
                              color: AppColors.textColorHint,
                              fontSize: 10.sp, // Adjusted responsive size
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h), // Responsive height
                      Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14.sp, // Responsive icon size
                            color: AppColors.textColorHint,
                          ),
                          SizedBox(width: 4.w), // Responsive width
                          Text(
                            user.plan,
                            style: AppText.labelSmall.copyWith(
                              color: AppColors.textColorHint,
                              fontSize: 10.sp, // Adjusted responsive size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w, // Responsive padding
                    vertical: 6.h, // Responsive padding
                  ),
                  decoration: BoxDecoration(
                    color:
                        user.status == 'Active'
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      20.r,
                    ), // Responsive radius
                  ),
                  child: Text(
                    user.status,
                    style: AppText.labelSmall.copyWith(
                      color:
                          user.status == 'Active'
                              ? AppColors.success
                              : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp, // Adjusted responsive size
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

  // Skeleton Loading Widgets
  Widget _buildCodeSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 180.w, // Responsive width
        height: 48.h, // Responsive height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r), // Responsive radius
        ),
      ),
    );
  }

  Widget _buildStatsSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (index) => Column(
                children: [
                  Container(
                    width: 50.w, // Responsive width
                    height: 50.h, // Responsive height
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(height: 8.h), // Responsive height
                  Container(
                    width: 40.w, // Responsive width
                    height: 20.h, // Responsive height
                    color: Colors.white,
                  ),
                  SizedBox(height: 4.h), // Responsive height
                  Container(
                    width: 60.w, // Responsive width
                    height: 16.h, // Responsive height
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h), // Responsive height
          Container(
            height: 8.h, // Responsive height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r), // Responsive radius
            ),
          ),
          SizedBox(height: 8.h), // Responsive height
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60.w, // Responsive width
                height: 12.h, // Responsive height
                color: Colors.white,
              ),
              Container(
                width: 40.w, // Responsive width
                height: 12.h, // Responsive height
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserSkeleton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.w, // Responsive margin
        vertical: 8.h, // Responsive margin
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 50.w, // Responsive width
              height: 50.h, // Responsive height
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w), // Responsive width
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120.w, // Responsive width
                    height: 16.h, // Responsive height
                    color: Colors.white,
                  ),
                  SizedBox(height: 8.h), // Responsive height
                  Container(
                    width: 80.w, // Responsive width
                    height: 12.h, // Responsive height
                    color: Colors.white,
                  ),
                  SizedBox(height: 4.h), // Responsive height
                  Container(
                    width: 100.w, // Responsive width
                    height: 12.h, // Responsive height
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Container(
              width: 60.w, // Responsive width
              height: 24.h, // Responsive height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r), // Responsive radius
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCounter(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 80.w, // Responsive width
        height: 20.h, // Responsive height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r), // Responsive radius
        ),
      ),
    );
  }

  void _showReferralInfoDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading referral info..."),
              ],
            ),
          ),
    );
    final referralResponse = await ApiServices().getReferralMessage();
    Navigator.pop(context); // Close loading dialog
    if (referralResponse == null) return;
    // Show actual dialog with data
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r), // Responsive radius
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24.r), // Responsive padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        color: AppColors.primary,
                        size:
                            28, // Keep icon size static or make responsive if needed
                      ),
                      SizedBox(width: 12.w), // Responsive width
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontSize: 18.sp, // Responsive font size
                          fontWeight: FontWeight.w600,
                        ), // Replace AppText.headingSmall if needed
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h), // Responsive height
                  if (referralResponse.steps.isNotEmpty)
                    ...referralResponse.steps
                        .map(
                          (step) => Column(
                            children: [
                              _buildInfoStep(
                                context,
                                step.stepOrder,
                                step.stepDescription,
                              ),
                              SizedBox(height: 16.h), // Responsive height
                            ],
                          ),
                        )
                        .toList()
                        .sublist(
                          0,
                          referralResponse.steps.length - 1,
                        ) // avoid last extra SizedBox
                  else
                    const Text("Loading referral info..."),
                  if (referralResponse.steps.isNotEmpty)
                    _buildInfoStep(
                      context,
                      referralResponse.steps.last.stepOrder,
                      'You earn ₹${_controller.bonusPerReferral.value} per referral!',
                    ),
                  SizedBox(height: 24.h), // Responsive height
                  Text(
                    'Terms and conditions apply',
                    style: TextStyle(
                      fontSize: 12.sp, // Responsive font size
                      color: Colors.grey, // Replace AppColors.textColorHint
                    ),
                  ),
                  SizedBox(height: 16.h), // Responsive height
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // Responsive radius
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 14.h,
                        ), // Responsive padding
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoStep(BuildContext context, int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.w, // Responsive width
          height: 28.h, // Responsive height
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Keep static or make responsive if needed
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w), // Responsive width
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h), // Responsive padding
            child: Text(
              text,
              style: AppText.bodyMedium.copyWith(
                fontSize: 12.sp,
                overflow: TextOverflow.clip,
              ),
            ), // Responsive text size
          ),
        ),
      ],
    );
  }
}
