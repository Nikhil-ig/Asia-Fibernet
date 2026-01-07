// screens/scaffold_screen.dart
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../chatbot/ui/chat_screen.dart';
import '../../customer/ui/screen/pages/referral_screen.dart';
import '../../customer/ui/screen/settings_screen.dart';
import '../../services/apis/api_services.dart';
import '../../services/sharedpref.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../../customer/ui/screen/pages/complaints_page.dart';
import '../../customer/ui/screen/pages/home_page.dart';
import '../../theme/widgets/app_drawer.dart';
import 'widgets/account_switcher.dart';
import '../core/model/customer_details_model.dart';
import '../../customer/ui/screen/bsnl_screen.dart';

// lib/src/controllers/scaffold_controller.dart

class ScaffoldController extends GetxController {
  ApiServices apiServices =
      Get.isRegistered<ApiServices>()
          ? Get.find<ApiServices>()
          : Get.put(ApiServices());
  BaseApiService baseApiService =
      Get.isRegistered<BaseApiService>()
          ? Get.find<BaseApiService>()
          : Get.put(BaseApiService());
  var currentIndex = 0.obs;
  final isLoading = true.obs;
  Rx<CustomerDetails?> customer = Rx<CustomerDetails?>(null);
  RxString custName = ''.obs;

  // New properties for account management
  RxList<DisplayAccount> allAccounts = <DisplayAccount>[].obs;
  Rx<DisplayAccount?> currentAccount = Rx<DisplayAccount?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchcustomerDetails();
  }

  void updateIndex(int index) {
    currentIndex.value = index;
  }

  void navigateToReferral() {
    currentIndex.value = 5;
  }

  void switchAccount(DisplayAccount account) {
    // If the selected account is already the current one, do nothing.
    // if (account.id == currentAccount.value?.id) {
    //   Get.back();
    //   return;
    // }
    apiServices.switchAccount(id: account.id);

    // In a real application, you would trigger an API call here to fetch
    // the full details for the selected account and then refresh the app's state.
    // For this example, we'll just show a snackbar and close the sheet.
    print("Switching to account ID: ${account.id}");
    baseApiService.showSnackbar(
      'Account Switching',
      'This is a demo. In a real app, data for ${account.name} would be loaded.',
    );

    // You would typically update a shared preference with the new user ID
    // and then call `fetchcustomerDetails()` again.
    // e.g., AppSharedPref.instance.setUserID(account.id.toString());
    // fetchcustomerDetails();

    // For now, we just close the bottom sheet. The UI won't update to the new user
    // without a full data refresh.
    Get.back();
  }

  Future<void> fetchcustomerDetails() async {
    isLoading.value = true;
    try {
      final userId = AppSharedPref.instance.getUserID();
      if (userId == null) {
        print("❌ No user ID found in shared prefs!");
        return;
      }

      print("🔍 Fetching customer data for user ID: $userId");

      final customerData = await apiServices.fetchCustomer();
      final customerDetails = customerData;
      final moreAccounts = customerData?.moreAccount ?? [];

      if (customerDetails == null) {
        print("❌ API returned null customer data");
        baseApiService.showSnackbar(
          'Error',
          'Failed to load profile. Please log in again.',
          isError: true,
        );
        return;
      }

      print("✅ Customer loaded: ${customerDetails.contactName}");

      custName.value = customerDetails.contactName ?? "User";
      customer.value = customerDetails;

      // --- NEW: Populate account list for switcher ---
      final accounts = <DisplayAccount>[];

      // 1. Add the primary/current account
      if (customerDetails.id != null) {
        final primaryAccount = DisplayAccount(
          id: customerDetails.id!,
          name: customerDetails.contactName ?? 'Main User',
          subtitle: customerDetails.bbUserId ?? 'Primary Account',
          imageUrl: customerDetails.fullProfileImageUrl,
          isPrimary: true,
        );
        accounts.add(primaryAccount);
        currentAccount.value = primaryAccount;
      }

      // 2. Add other available accounts
      for (final accInfo in moreAccounts) {
        if (accInfo.id != null) {
          accounts.add(
            DisplayAccount(
              id: accInfo.id!,
              name: accInfo.ladlineno ?? 'Account #${accInfo.id}',
              subtitle: 'Tap to switch',
            ),
          );
        }
      }

      allAccounts.value = accounts;
      // --- End new logic ---
    } catch (e, stack) {
      print("🔥 Error fetching customer: $e");
      print("Stack: $stack");
      baseApiService.showSnackbar(
        'Error',
        "Unable to load your profile. Try again later.",
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

// screens/scaffold_screen.dart
// ... (Keep your existing ScaffoldController code as is)

// screens/scaffold_screen.dart
class ScaffoldScreen extends StatelessWidget {
  const ScaffoldScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl =
        Get.isRegistered<ScaffoldController>()
            ? Get.find<ScaffoldController>()
            : Get.put(ScaffoldController());

    final screens = [
      HomeScreenContent(),
      PremiumBsnlPlansScreen(),
      const ChatScreen(),
      ComplaintsScreen(),
      const SettingsScreen(),
      ReferralScreen(),
    ];

    return Obx(() {
      final currentIndex = scaffoldCtrl.currentIndex.value;

      return Scaffold(
        extendBody: true,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: Builder(
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(left: 16.w),
                child: Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Icon(
                      Iconsax.menu_1,
                      size: 22.r,
                      color: AppColors.primary,
                    ),
                    splashRadius: 20.r,
                  ),
                ),
              );
            },
          ),
          title: _AppBarGreeting(),
          centerTitle: false,
          // actions: [_QuickActionsButton()],
        ),
        body: screens[currentIndex],
        // Remove floating action button and bottom navigation bar
      );
    });
  }
}

class _AppBarGreeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl = Get.find<ScaffoldController>();

    return Obx(() {
      if (scaffoldCtrl.isLoading.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              width: 180.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ],
        );
      }

      final name = scaffoldCtrl.custName.value.trim();
      final displayName = name.isEmpty ? "User" : name;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$displayName 👋",
            style: AppText.headingSmall.copyWith(
              color: AppColors.textColorPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                "Connected • Fast Speed",
                style: AppText.labelSmall.copyWith(
                  color: AppColors.textColorSecondary.withOpacity(0.8),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _QuickActionsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl = Get.find<ScaffoldController>();

    return Obx(() {
      if (scaffoldCtrl.isLoading.value) {
        return Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: CircleAvatar(
            radius: 18.r,
            backgroundColor: Colors.grey.shade300,
          ),
        );
      }

      return Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Get.toNamed('/profile');
                break;
              case 'support':
                scaffoldCtrl.updateIndex(3);
                break;
              case 'settings':
                scaffoldCtrl.updateIndex(4);
                break;
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Iconsax.user, size: 20.r, color: AppColors.primary),
                      SizedBox(width: 12.w),
                      Text("My Profile"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'support',
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.headphone,
                        size: 20.r,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12.w),
                      Text("Support"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.setting_2,
                        size: 20.r,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12.w),
                      Text("Settings"),
                    ],
                  ),
                ),
              ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Icon(Iconsax.more, color: Colors.white, size: 20.r),
          ),
        ),
      );
    });
  }
}

class _BeautifulBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const _BeautifulBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20.r,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: Container(
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade100, width: 1.w),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side items
              _BottomNavItem(
                icon: Iconsax.home,
                activeIcon: Iconsax.home_15,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onIndexChanged,
              ),
              _BottomNavItem(
                icon: Iconsax.document,
                activeIcon: Iconsax.document5,
                label: 'Plans',
                index: 1,
                currentIndex: currentIndex,
                onTap: onIndexChanged,
              ),

              // Spacer for FAB
              SizedBox(width: 40.w),

              // Right side items
              _BottomNavItem(
                icon: Iconsax.message,
                activeIcon: Iconsax.message5,
                label: 'Support',
                index: 3,
                currentIndex: currentIndex,
                onTap: onIndexChanged,
              ),
              _BottomNavItem(
                icon: Iconsax.setting_2,
                activeIcon: Iconsax.setting_4,
                label: 'Settings',
                index: 4,
                currentIndex: currentIndex,
                onTap: onIndexChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNavItem({
    Key? key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: 24.r,
                    color: isActive ? AppColors.primary : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label,
                  style: AppText.labelSmall.copyWith(
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.primary : Colors.grey.shade600,
                    height: 1.2,
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

class _FloatingActionCenterButton extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onTap;

  const _FloatingActionCenterButton({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == 2;

    return FloatingActionButton(
      onPressed: onTap,
      elevation: 4,
      backgroundColor: isActive ? AppColors.primary : Colors.white,
      foregroundColor: isActive ? Colors.white : AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2.w),
      ),
      child: Container(
        width: 56.r,
        height: 56.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient:
              isActive
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  )
                  : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isActive ? 0.3 : 0.1),
              blurRadius: 12.r,
              spreadRadius: 1.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isActive ? Iconsax.magicpen5 : Iconsax.magicpen,
          size: 24.r,
          color: isActive ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

// ... (Keep your existing _AppBarGreeting and _ProfileAvatarButton code as is)
// Reusable Widgets

// class _AppBarGreeting extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final scaffoldCtrl =
//         Get.isRegistered<ScaffoldController>()
//             ? Get.find<ScaffoldController>()
//             : Get.put(ScaffoldController());
//     return Obx(() {
//       if (scaffoldCtrl.isLoading.value) {
//         // Skeleton loading
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(width: 120.w, height: 20.h, color: Colors.grey.shade300),
//             SizedBox(height: 4.h),
//             Container(width: 180.w, height: 16.h, color: Colors.grey.shade200),
//           ],
//         );
//       }

//       // ✅ Single source of truth
//       final name = scaffoldCtrl.custName.value.trim();
//       final displayName = name.isEmpty ? "User" : name;

//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Hello, $displayName!",
//             style: AppText.headingMedium.copyWith(
//               color: AppColors.textColorPrimary,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           Text(
//             "Welcome to Asia Fibernet",
//             style: AppText.bodySmall.copyWith(
//               color: AppColors.textColorSecondary.withOpacity(0.8),
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }

class _ProfileAvatarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl =
        Get.isRegistered<ScaffoldController>()
            ? Get.find<ScaffoldController>()
            : Get.put(ScaffoldController());

    return Obx(() {
      if (scaffoldCtrl.isLoading.value) {
        return Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.grey.shade500, size: 20.r),
          ),
        );
      }

      final profileImageUrl = scaffoldCtrl.customer.value?.fullProfileImageUrl;

      return GestureDetector(
        onTap: () {
          Get.bottomSheet(
            const AccountSwitcher(),
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
          );
        },
        child: Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            foregroundImage:
                profileImageUrl != null && profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : null,
            child:
                profileImageUrl == null || profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: AppColors.primary, size: 20.r)
                    : null,
          ),
        ),
      );
    });
  }
}

class DisplayAccount {
  final int id;
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final bool isPrimary;

  DisplayAccount({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.isPrimary = false,
  });
}
