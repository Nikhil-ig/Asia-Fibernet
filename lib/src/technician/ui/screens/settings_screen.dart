import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/colors.dart';
import '../../../theme/theme.dart';
import 'technician_profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppText.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
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
                  onTap: () => Get.to(() => TechnicianProfileScreen()),
                ),
                _buildSettingsItem(
                  icon: Iconsax.notification,
                  title: "Notifications",
                  onTap: () => Get.to(() => NotificationScreen()),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // _buildSettingsCard(
            //   context,
            //   title: "Support & Requests",
            //   children: [
            //     _buildSettingsItem(
            //       icon: Iconsax.flash_1,
            //       title: "Request Disconnection",
            //       onTap: () {
            //         // TODO: Implement disconnection request
            //       },
            //     ),
            //     _buildSettingsItem(
            //       icon: Iconsax.location,
            //       title: "Relocation Request",
            //       onTap: () {
            //         // TODO: Implement relocation request
            //       },
            //     ),
            //   ],
            // ),
            SizedBox(height: 20.h),
            _buildSettingsCard(
              context,
              title: "Danger Zone",
              children: [
                _buildSettingsItem(
                  icon: Iconsax.trash,
                  title: "Delete Account",
                  color: Colors.red,
                  onTap: () {
                    // TODO: Implement delete account
                  },
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
