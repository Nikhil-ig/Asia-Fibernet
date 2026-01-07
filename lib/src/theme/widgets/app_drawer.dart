// lib/src/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:badges/badges.dart' as badges;

import '../../auth/ui/scaffold_screen.dart';
import '../../auth/ui/widgets/account_switcher.dart';
import '../../chatbot/ui/chat_screen.dart';
import '../../services/sharedpref.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl = Get.find<ScaffoldController>();

    return Drawer(
      width: 300.w,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.primary.withOpacity(0.02),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _DrawerHeader(),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // spacing: 6.h,
                  children: [
                    // SizedBox(height: 24.h),

                    // Main Navigation
                    // _DrawerSection(
                    //   title: "MAIN",
                    //   children: [
                    //     // _DrawerItem(
                    //     //   icon: Iconsax.home_2,
                    //     //   label: 'Dashboard',
                    //     //   index: 0,
                    //     //   badgeCount: 0,
                    //     // ),
                    //     // _DrawerItem(
                    //     //   icon: Iconsax.clock,
                    //     //   label: 'Recent Activity',
                    //     //   index: -1, // New page
                    //     //   onTap: () {
                    //     //         Navigator.pop(context);;
                    //     //     // Navigate to activity page
                    //     //   },
                    //     // ),
                    //     // _DrawerItem(
                    //     //   icon: Iconsax.trend_up,
                    //     //   label: 'Usage Analytics',
                    //     //   index: -1, // New page
                    //     //   onTap: () {
                    //     //         Navigator.pop(context);;
                    //     //     // Navigate to analytics page
                    //     //   },
                    //     // ),
                    //   ],
                    // ),

                    // SizedBox(height: 32.h),

                    // Services Section
                    _DrawerSection(
                      title: "",
                      children: [
                        _DrawerItem(
                          icon: Iconsax.home_2,
                          label: 'Dashboard',
                          index: 0,
                          badgeCount: 0,
                        ),
                        _DrawerItem(
                          icon: Iconsax.document_text,
                          label: 'Plans & Packages',
                          index: 1,
                          // isPro: true,
                        ),
                        // _DrawerItem(
                        //   icon: Iconsax.magicpen,
                        //   label: 'AI Assistant',
                        //   index: 2,
                        //   isPro: false,
                        // ),
                        // _DrawerItem(
                        //   icon: Iconsax.message_question,
                        //   label: 'Support Tickets',
                        //   index: 3,
                        //   badgeCount: 3,
                        // ),
                        _DrawerItem(
                          icon: Iconsax.refresh_circle,
                          label: 'Service Requests',
                          index: -1,
                          // badgeCount: 2,
                          onTap: () {
                            Navigator.pop(context);
                            ;
                            scaffoldCtrl.updateIndex(3);
                            // Navigate to service requests
                          },
                        ),
                        _DrawerItem(
                          icon: Iconsax.user,
                          label: 'My Profile',
                          index: -1,
                          onTap: () {
                            Navigator.pop(context);
                            ;
                            Get.toNamed('/profile');
                          },
                        ),
                        _DrawerItem(
                          icon: Iconsax.setting_2,
                          label: 'Settings',
                          index: 4,
                        ),
                        _DrawerItem(
                          icon: Iconsax.share,
                          label: 'Refer & Earn',
                          index: -1,
                          // isPro: true,
                          onTap: () {
                            Navigator.pop(context);
                            ;
                            scaffoldCtrl.navigateToReferral();
                          },
                        ),
                      ],
                    ),

                    // SizedBox(height: 32.h),

                    // Account Section
                    // _DrawerSection(
                    //   title: "ACCOUNT",
                    //   children: [
                    //     _DrawerItem(
                    //       icon: Iconsax.user,
                    //       label: 'My Profile',
                    //       index: -1,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         Get.toNamed('/profile');
                    //       },
                    //     ),
                    //     _DrawerItem(
                    //       icon: Iconsax.wallet_3,
                    //       label: 'Billing & Payments',
                    //       index: -1,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         // Navigate to billing
                    //       },
                    //     ),
                    //     _DrawerItem(
                    //       icon: Iconsax.setting_2,
                    //       label: 'Settings',
                    //       index: 4,
                    //     ),
                    //     _DrawerItem(
                    //       icon: Iconsax.share,
                    //       label: 'Refer & Earn',
                    //       index: -1,
                    //       isPro: true,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         scaffoldCtrl.navigateToReferral();
                    //       },
                    //     ),
                    //   ],
                    // ),

                    // SizedBox(height: 32.h),

                    // Support Section
                    // _DrawerSection(
                    //   title: "SUPPORT",
                    //   children: [
                    //     _DrawerItem(
                    //       icon: Iconsax.headphone,
                    //       label: 'Help Center',
                    //       index: -1,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         // Navigate to help center
                    //       },
                    //     ),
                    //     _DrawerItem(
                    //       icon: Iconsax.info_circle,
                    //       label: 'About Us',
                    //       index: -1,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         // Navigate to about
                    //       },
                    //     ),
                    //     _DrawerItem(
                    //       icon: Iconsax.shield_tick,
                    //       label: 'Privacy Policy',
                    //       index: -1,
                    //       onTap: () {
                    //             Navigator.pop(context);;
                    //         // Navigate to privacy
                    //       },
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),

            // Footer Section
            _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl = Get.find<ScaffoldController>();

    return Container(
      padding: EdgeInsets.only(
        left: 24.w,
        right: 16.w,
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 24.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withOpacity(0.9),
            AppColors.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32.r)),
      ),
      child: Obx(() {
        final customer = scaffoldCtrl.customer.value;
        final isLoading = scaffoldCtrl.isLoading.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Asia Fibernet",
                  style: AppText.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Iconsax.close_circle,
                    color: Colors.white.withOpacity(0.8),
                    size: 24.r,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            if (isLoading)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120.w,
                            height: 16.h,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 80.w,
                            height: 12.h,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ;
                  Get.bottomSheet(
                    const AccountSwitcher(),
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundImage:
                            customer?.fullProfileImageUrl != null
                                ? NetworkImage(customer!.fullProfileImageUrl!)
                                : null,
                        child:
                            customer?.fullProfileImageUrl == null
                                ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24.r,
                                )
                                : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer?.contactName ?? "User",
                              style: AppText.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              customer?.email ?? "Premium Member",
                              style: AppText.labelSmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_swap_horizontal,
                        color: Colors.white.withOpacity(0.8),
                        size: 20.r,
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16.h),

            // Connection Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 8.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Connected • 100 Mbps",
                      style: AppText.bodySmall.copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    "Active",
                    style: AppText.labelSmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
          child: Text(
            title,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textColorSecondary.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int badgeCount;
  final bool isPro;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.index = -1,
    this.badgeCount = 0,
    this.isPro = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldCtrl = Get.find<ScaffoldController>();
    final isActive = index >= 0 && scaffoldCtrl.currentIndex.value == index;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap:
            onTap ??
            () {
              if (index >= 0) {
                scaffoldCtrl.updateIndex(index);
              }
              Navigator.pop(context);
              ;
            },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color:
                isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border:
                isActive
                    ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1.w,
                    )
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? AppColors.primary
                          : AppColors.textColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  size: 16.r,
                  color:
                      isActive
                          ? Colors.white
                          : AppColors.textColorSecondary.withOpacity(0.8),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: AppText.labelMedium.copyWith(
                        color:
                            isActive
                                ? AppColors.primary
                                : AppColors.textColorPrimary,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isPro) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "PRO",
                          style: AppText.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 8.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badgeCount > 0)
                badges.Badge(
                  badgeContent: Text(
                    badgeCount.toString(),
                    style: AppText.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                    ),
                  ),
                  badgeStyle: badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(4.r),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              if (!isActive && index >= 0)
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18.r,
                  color: AppColors.textColorSecondary.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.w),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FooterButton(
                icon: Iconsax.logout,
                label: "Logout",
                onTap: () {
                  AppSharedPref.instance.clearAllUserData();
                  Get.offAllNamed('/login');
                },
              ),
              _FooterButton(
                icon: Iconsax.magicpen,
                label: 'AI Assistant',
                onTap: () {
                  Navigator.pop(context);
                  final scaffoldCtrl = Get.find<ScaffoldController>();
                  scaffoldCtrl.updateIndex(2);
                  // Get.to(()=> ChatScreen());
                },
                // isPro: false,
              ),
              _FooterButton(icon: Iconsax.call, label: "Support", onTap: () {}),
            ],
          ),
          // SizedBox(height: 16.h),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Version 2.4.1 • © 2024 Asia Fibernet",
              style: AppText.labelSmall.copyWith(
                color: AppColors.textColorSecondary.withOpacity(0.5),
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 20.r, color: AppColors.primary),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: AppText.labelSmall.copyWith(
                  color: AppColors.textColorSecondary,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
