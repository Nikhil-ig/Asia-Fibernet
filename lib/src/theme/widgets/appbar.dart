import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../colors.dart';
import '../theme.dart';

class MyAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const MyAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: AppText.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left_2, color: Colors.white),
        ),
        centerTitle: true,
        actions: actions,
      ),
    );
  }
}
