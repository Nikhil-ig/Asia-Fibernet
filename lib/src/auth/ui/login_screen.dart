import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:asia_fibernet/src/theme/theme.dart';
import 'package:asia_fibernet/src/customer/ui/widgets/app_textfield.dart';

import '../core/controller/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key})
    : super(key: key); // Use Key? and super(key: key)

  @override
  Widget build(BuildContext context) {
    // Local form key, as it was in the original code
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundGradientEnd.withOpacity(0.9),
            ],
            stops: const [0.1, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w, // Use .w for horizontal padding
              vertical: 16.h, // Use .h for vertical padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated Logo Section
                Container(
                  margin: EdgeInsets.only(top: 20.h), // Responsive margin
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow effect
                      Container(
                        height: 140.r, // Use .r for size
                        width: 140.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 25.r, // Responsive blur
                              spreadRadius: 5.r, // Responsive spread
                            ),
                          ],
                        ),
                      ),
                      // Logo container
                      Container(
                        height: 120.r, // Use .r for size
                        width: 120.r,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 15.r, // Responsive blur
                              spreadRadius: 2.r, // Responsive spread
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80.r, // Use .r for radius
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage(
                            "assets/asia-logo.png", // Ensure asset path is correct
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 0.02.sh,
                ), // Use .sh for percentage of screen height
                // Welcome Text Section (Reusable Widget)
                _WelcomeTextSection(controller: controller),

                SizedBox(height: 0.04.sh), // Responsive spacing
                // Login Card Section (Reusable Widget)
                _LoginCard(
                  controller: controller,
                  formKey: _formKey, // Pass the local form key
                ),

                // SizedBox(height: 0.02.sh), // Responsive spacing
                // Sign Up Section (Reusable Widget)
                // _SignUpSection(),
                // SizedBox(height: 0.02.sh), // Responsive spacing
                // Footer text
                // Text(
                //   "© 2025 Asia Fibernet. All rights reserved",
                //   style: AppText.bodySmall.copyWith(
                //     color: AppColors.textColorHint,
                //     fontSize: 12.sp, // Use .sp for text size
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable Widget: Welcome Text Section
class _WelcomeTextSection extends StatelessWidget {
  final LoginController controller;

  const _WelcomeTextSection({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Welcome to Asia Fibernet",
          style: AppText.headingLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
            overflow: TextOverflow.clip,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.01.sh), // Responsive spacing
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w, // Responsive horizontal padding
          ),
          child: Text(
            "Ultra-fast internet solutions for your home and business",
            textAlign: TextAlign.center,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
              fontSize: 16.sp, // Responsive text size
            ),
          ),
        ),
      ],
    );
  }
}

// Reusable Widget: Login Card Section
class _LoginCard extends StatelessWidget {
  final LoginController controller;
  final GlobalKey<FormState> formKey; // Accept the form key as a parameter

  const _LoginCard({Key? key, required this.controller, required this.formKey})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r), // Responsive border radius
      ),
      elevation: 8.r, // Responsive elevation
      shadowColor: AppColors.primary.withOpacity(0.2),
      color: AppColors.cardBackground,
      child: Padding(
        padding: EdgeInsets.all(24.r), // Responsive padding
        child: Form(
          key: formKey, // Use the passed local form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Customer Login",
                style: AppText.headingSmall.copyWith(
                  fontSize: 22.sp, // Responsive text size
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.008.sh), // Responsive spacing
              Text(
                "Login with your mobile number",
                style: AppText.bodySmall.copyWith(
                  color: AppColors.textColorSecondary,
                ),
              ),
              SizedBox(height: 0.03.sh), // Responsive spacing
              // Mobile Number Input Section (Reusable Widget)
              _MobileNumberInput(controller: controller),

              SizedBox(height: 0.03.sh), // Responsive spacing
              // Send OTP Button (Reusable Widget)
              _SendOtpButton(
                controller: controller,
                formKey: formKey, // Pass form key to button logic
              ),

              SizedBox(height: 0.025.sh), // Responsive spacing
              // Forgot Password (Reusable Widget)
              // _ForgotPassword(),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Widget: Mobile Number Input

class _MobileNumberInput extends StatelessWidget {
  final LoginController controller;

  const _MobileNumberInput({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: AppText.labelMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 0.01.sh),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.dividerColor.withOpacity(0.2),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  "+91",
                  style: AppText.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 30.h,
                width: 1.w,
                color: AppColors.dividerColor.withOpacity(0.3),
              ),
              Expanded(
                child: AppTextField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: "Enter your 10-digit number",
                  prefixIcon: null,
                  obscureText: false,
                  isEnabled: true,
                  maxLength: 10,
                  // 🔒 Only allow digits
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your number';
                    }
                    if (value.length != 10) {
                      return 'Enter a valid 10-digit number';
                    }
                    return null;
                  },
                  // Remove internal border since it's wrapped in a container
                  borderWidth: 0,
                  enabledBorderColor: Colors.transparent,
                  focusedBorderColor: Colors.transparent,
                  errorBorderColor: Colors.transparent,
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reusable Widget: Send OTP Button
class _SendOtpButton extends StatelessWidget {
  final LoginController controller;
  final GlobalKey<FormState> formKey; // Accept the form key

  const _SendOtpButton({
    Key? key,
    required this.controller,
    required this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56.h, // Responsive height
        child: ElevatedButton(
          onPressed:
              controller.isLoading.value
                  ? null // Disable when loading
                  : () {
                    if (formKey.currentState!.validate()) {
                      // Use the passed form key
                      controller.login();
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12.r,
              ), // Responsive border radius
            ),
            elevation: 2.r, // Responsive elevation
            shadowColor: AppColors.primary.withOpacity(0.4),
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          ),
          child:
              controller.isLoading.value
                  ? SizedBox(
                    height: 20.r, // Responsive size
                    width: 20.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w, // Responsive stroke width
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                  : Text(
                    "SEND OTP",
                    style: AppText.button.copyWith(
                      fontSize: 16.sp, // Responsive text size
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }
}

// Reusable Widget: Sign Up Section
class _SignUpSection extends StatelessWidget {
  const _SignUpSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SizedBox(height: 0.02.sh), // Responsive spacing
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Get.toNamed(AppRoutes.signup);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary,
                width: 1.5.w, // Responsive border width
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12.r,
                ), // Responsive border radius
              ),
              padding: EdgeInsets.symmetric(
                vertical: 16.h,
              ), // Responsive padding
            ),
            child: Text(
              "APPLY FOR NEW CONNECTION",
              style: AppText.button.copyWith(
                color: AppColors.backgroundLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
