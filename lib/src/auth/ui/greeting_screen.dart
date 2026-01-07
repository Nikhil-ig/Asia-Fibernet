// lib/src/auth/ui/greeting_screen.dart
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';

class GreetingScreen extends StatelessWidget {
  const GreetingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Enhanced Background with Multiple Gradients
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.success.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated Floating Elements
          _buildFloatingElements(),

          // Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation Container
                  _buildSuccessAnimation(),
                  SizedBox(height: 40.h),

                  // Title with Gradient
                  _buildGradientTitle(),
                  SizedBox(height: 16.h),

                  // Subtitle
                  _buildSubtitle(),
                  SizedBox(height: 52.h),

                  // Enhanced Login Button
                  _buildLoginButton(),

                  // Subtle hint with icon
                  SizedBox(height: 24.h),
                  _buildHintText(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Top Right Circle
        Positioned(
          top: -100.h,
          right: -80.w,
          child: Container(
            width: 280.w,
            height: 280.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
                stops: [0.1, 0.8],
              ),
            ),
          ),
        ),

        // Bottom Left Circle
        Positioned(
          bottom: -120.h,
          left: -90.w,
          child: Container(
            width: 320.w,
            height: 320.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.success.withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: [0.1, 0.7],
              ),
            ),
          ),
        ),

        // Small Floating Circles
        Positioned(
          top: 120.h,
          left: 40.w,
          child: _buildFloatingCircle(40, AppColors.primary.withOpacity(0.1)),
        ),
        Positioned(
          bottom: 180.h,
          right: 50.w,
          child: _buildFloatingCircle(32, AppColors.success.withOpacity(0.08)),
        ),
      ],
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return AnimatedContainer(
      duration: Duration(seconds: 3),
      curve: Curves.easeInOut,
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildSuccessAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Background Circle
        AnimatedContainer(
          duration: Duration(milliseconds: 2000),
          curve: Curves.easeInOut,
          width: 160.w,
          height: 160.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.success.withOpacity(0.2),
                AppColors.success.withOpacity(0.05),
              ],
            ),
          ),
        ),

        // Main Checkmark Container
        Container(
          width: 140.w,
          height: 140.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.white.withOpacity(0.9)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.25),
                blurRadius: 25.r,
                spreadRadius: 5.r,
                offset: Offset(0, 8.h),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10.r,
                spreadRadius: 2.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated Checkmark
              Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 80.sp,
                    color: AppColors.success,
                  ),
                ),
              ),

              // Sparkle Effects
              Positioned(
                top: 25.h,
                right: 25.w,
                child: Icon(
                  Icons.star_rounded,
                  size: 16.sp,
                  color: AppColors.success.withOpacity(0.7),
                ),
              ),
              Positioned(
                bottom: 30.h,
                left: 25.w,
                child: Icon(
                  Icons.star_rounded,
                  size: 12.sp,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradientTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [AppColors.primary, AppColors.success],
          stops: [0.3, 0.8],
        ).createShader(bounds);
      },
      child: Text(
        'Congratulations!',
        style: AppText.headingLarge.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 32.sp,
          height: 1.2,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 2.h),
              blurRadius: 4.r,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Text(
        'Your KYC and installation process has been completed successfully. You\'re all set to start using the application.',
        style: AppText.bodyMedium.copyWith(
          color: AppColors.textColorSecondary,
          height: 1.6,
          fontWeight: FontWeight.w500,
          fontSize: 16.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20.r,
            spreadRadius: 2.r,
            offset: Offset(0, 8.h),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 2.r,
            spreadRadius: 1.r,
            offset: Offset(0, -1.h),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Get.offAllNamed(AppRoutes.login);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 32.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size(double.infinity, 68.h),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Login Again',
              style: AppText.button.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(width: 12.w),
            // for (int i = 0; i <= 2; i++)
            Icon(
              Icons.arrow_forward_ios,
              size: 20.sp,
              color: AppColors.backgroundLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16.sp,
          color: AppColors.textColorHint.withOpacity(0.7),
        ),
        SizedBox(width: 8.w),
        Text(
          'You may now access your account',
          style: AppText.labelSmall.copyWith(
            color: AppColors.textColorHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
