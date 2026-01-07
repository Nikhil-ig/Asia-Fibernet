import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import '../../core/controller/settings_controller.dart';
import '../../../auth/ui/widgets/account_switcher.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppText.headingMedium.copyWith(
            color: AppColors.backgroundLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: AppColors.backgroundLight,
        iconTheme: IconThemeData(color: AppColors.backgroundLight),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundLight.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSettingsCard(
              context,
              title: "Account",
              children: [
                _buildSettingsItem(
                  icon: Iconsax.user,
                  title: "Profile",
                  onTap: () => Get.toNamed(AppRoutes.profile),
                ),
                _buildSettingsItem(
                  icon: Iconsax.document,
                  title: "Plans",
                  onTap: () => Get.toNamed(AppRoutes.bsnlPlans),
                ),
                // _buildSettingsItem(
                //   icon: Iconsax.notification,
                //   title: "Notifications",
                //   onTap: () => Get.toNamed(AppRoutes.notificationSettings),
                // ),
                // _buildSettingsItem(
                //   icon: Iconsax.money,
                //   title: "Refferral",
                //   onTap: () {
                //     Get.toNamed(AppRoutes.referral);
                //   },
                // ),
                _buildSettingsItem(
                  icon: Iconsax.arrow_swap_horizontal,
                  title: "Switch Account",
                  onTap: () {
                    Get.bottomSheet(
                      const AccountSwitcher(),
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildSettingsCard(
              context,
              title: "Support & Requests",
              children: [
                _buildSettingsItem(
                  icon: Iconsax.flash_1,
                  title: "Request Disconnection",
                  onTap: controller.showDisconnectionSheet,
                ),
                _buildSettingsItem(
                  icon: Iconsax.location,
                  title: "Relocation Request",
                  onTap: controller.showRelocationSheet,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildSettingsCard(
              context,
              title: "Danger Zone",
              children: [
                _buildSettingsItem(
                  icon: Iconsax.trash,
                  title: "Delete Account",
                  color: Colors.red,
                  onTap: controller.showDeleteAccountDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text(
                title,
                style: AppText.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        title,
        style: AppText.bodyMedium.copyWith(
          color: color ?? AppColors.textColorPrimary,
        ),
      ),
      trailing: const Icon(
        Iconsax.arrow_right_3,
        color: AppColors.textColorSecondary,
      ),
      onTap: onTap,
    );
  }
}
