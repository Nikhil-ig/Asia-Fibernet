import 'package:asia_fibernet/src/auth/ui/scaffold_screen.dart';
import 'package:asia_fibernet/src/services/apis/api_services.dart';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../theme/colors.dart';
import '../../../theme/theme.dart';

class AccountSwitcher extends StatelessWidget {
  const AccountSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final ScaffoldController scaffoldCtrl = Get.find<ScaffoldController>();
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Switch Account",
            style: AppText.headingMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Obx(
            () => Column(
              children:
                  scaffoldCtrl.allAccounts.map((account) {
                    final isSelected =
                        account.id == scaffoldCtrl.currentAccount.value?.id;
                    return _buildAccountTile(
                      name: account.name,
                      subtitle: account.subtitle ?? '',
                      imageUrl: account.imageUrl,
                      isSelected: isSelected,
                      onTap: () => scaffoldCtrl.switchAccount(account),
                    );
                  }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          // _buildActionButton(
          //   icon: Iconsax.add,
          //   title: "Add Another Account",
          //   onTap: () {},
          // ),
          _buildActionButton(
            icon: Iconsax.logout,
            title: "Logout",
            onTap: () {
              ApiServices().logOutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required String name,
    required String subtitle,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24.r,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        foregroundImage:
            imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
        child:
            imageUrl == null || imageUrl.isEmpty
                ? Icon(Iconsax.user, color: AppColors.primary, size: 24.r)
                : null,
      ),
      title: Text(
        name,
        style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle, style: AppText.bodySmall),
      trailing:
          isSelected
              ? Icon(Iconsax.tick_circle, color: AppColors.primary)
              : null,
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textColorSecondary),
      title: Text(title, style: AppText.bodyMedium),
      onTap: onTap,
    );
  }
}
