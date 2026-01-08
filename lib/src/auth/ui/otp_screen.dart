import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputType.number
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:asia_fibernet/src/theme/colors.dart'; // Ensure path is correct
import 'package:asia_fibernet/src/theme/theme.dart';

import '../core/controller/otp_controller.dart'; // Ensure AppText is defined here

class OTPScreen extends GetView<OTPController> {
  const OTPScreen({Key? key}) : super(key: key); // Use Key? and super(key: key)

  @override
  Widget build(BuildContext context) {
    // ScreenUtil.init(context, designSize: Size(375, 812)); // Example design size, adjust if different

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundLight,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
            ), // Use .w for horizontal padding
            child: Column(
              children: [
                SizedBox(height: 40.h), // Use .h for spacing
                Icon(
                  Icons.verified_user,
                  size: 80.r, // Use .r for size
                  color: AppColors.primary,
                ),
                SizedBox(height: 24.h), // Use .h for spacing
                Text(
                  "Verify Your Number",
                  style:
                      AppText
                          .headingMedium, // Ensure AppText is responsive or adjust here
                ),
                SizedBox(height: 16.h), // Use .h for spacing
                // --- FIX: Access phone number from controller ---
                RichText(
                  text: TextSpan(
                    text: "Enter the OTP sent to ",
                    style: AppText.bodyMedium.copyWith(
                      color: AppColors.textColorSecondary,
                    ),
                    children: [
                      TextSpan(
                        // --- Use controller.phone ---
                        text: "+91 ${controller.phone}", // <-- Changed here
                        style: AppText.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h), // Use .h for spacing
                // OTP Input Fields Section (Reusable Widget)
                _OtpInputFields(controller: controller),

                SizedBox(height: 24.h), // Use .h for spacing
                // Resend OTP Section (Reusable Widget)
                _ResendOtpSection(controller: controller),
                // Spacer(),
                // Padding(
                //   padding: EdgeInsets.only(
                //     bottom: 40.h,
                //   ), // Use .h for bottom padding
                //   child: ElevatedButton(
                //     onPressed: () {
                //       controller.verifyAndLogin();
                //     },
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColors.primary,
                //       foregroundColor:
                //           Colors.white, // Add foreground color for text
                //       minimumSize: Size(
                //         double.infinity,
                //         56.h,
                //       ), // Use .h for button height
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(
                //           12.r,
                //         ), // Use .r for border radius
                //       ),
                //       elevation: 0,
                //     ),
                //     child: Text(
                //       "VERIFY & LOGIN",
                //       style:
                //           AppText
                //               .button, // Ensure AppText.button is responsive or adjust here
                //     ),
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

// Reusable Widget: OTP Input Fields
class _OtpInputFields extends StatelessWidget {
  final OTPController controller;

  const _OtpInputFields({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50.w,
          height: 60.h,
          child:
          // Inside _OtpInputFields build:
          RawKeyboardListener(
            focusNode: FocusNode(), // Temporary, disposable
            onKey: (RawKeyEvent event) {
              if (event is RawKeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  controller.focusNodes[index].hasFocus) {
                if (controller.otpControllers[index].text.isEmpty &&
                    index > 0) {
                  Future.microtask(() {
                    FocusScope.of(
                      context,
                    ).requestFocus(controller.focusNodes[index - 1]);
                  });
                }
              }
            },
            child: TextField(
              controller: controller.otpControllers[index],
              focusNode: controller.focusNodes[index], // Only here!
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppText.headingSmall.copyWith(
                color: AppColors.textColorPrimary,
                fontSize: 24.sp,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: EdgeInsets.zero,
              ),
              maxLength: 1,
              onChanged: (value) {
                if (value.length == 1 && index < 5) {
                  FocusScope.of(
                    context,
                  ).requestFocus(controller.focusNodes[index + 1]);
                }
                if (controller.otpControllers.every((c) => c.text.isNotEmpty)) {
                  Future.delayed(
                    const Duration(milliseconds: 100),
                    controller.verifyAndLogin,
                  );
                }
              },
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              enableSuggestions: false,
              autocorrect: false,
            ),
          ),
        );
      }),
    );
  }
}

// Reusable Widget: Resend OTP Section
class _ResendOtpSection extends StatelessWidget {
  final OTPController controller;

  const _ResendOtpSection({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn't receive OTP? ",
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          TextButton(
            onPressed:
                controller.resendEnabled.value
                    ? () {
                      controller.resendOTP();
                    }
                    : null,
            child: Text(
              controller.resendEnabled.value
                  ? "Resend OTP"
                  : "Resend in ${controller.secondsRemaining.value} s",
              style: TextStyle(
                color:
                    controller.resendEnabled.value
                        ? AppColors.primary
                        : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp, // Use .sp for text size - adjust as needed
              ),
            ),
          ),
        ],
      ),
    );
  }
}
