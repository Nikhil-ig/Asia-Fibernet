import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:asia_fibernet/src/theme/theme.dart';
import 'package:iconsax/iconsax.dart';
import '../core/controller/otp_controller.dart';

class OTPScreen extends GetView<OTPController> {
  const OTPScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.08),
              Colors.white,
              Colors.white,
              AppColors.primary.withOpacity(0.04),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Container(
                width: 200.w,
                height: 200.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 1.0],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -100.h,
              left: -50.w,
              child: Container(
                width: 300.w,
                height: 300.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.1, 1.0],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildAppBar(),
                      SizedBox(height: 40.h),

                      // Main Content
                      _buildMainContent(),
                      SizedBox(height: 40.h),

                      // OTP Input Section
                      _buildOTPInputSection(),

                      SizedBox(height: 32.h),

                      // Delivery Method Selection
                      _buildDeliveryMethod(),

                      SizedBox(height: 40.h),

                      // Resend Section
                      _buildResendSection(),

                      // SizedBox(height: 32.h),

                      // Verify Button
                      // _buildVerifyButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Text(
          "OTP Verification",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Animated Icon Container
        Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 20.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.verified_rounded,
                  size: 60.r,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                top: 10.r,
                right: 10.r,
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 4.r,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 12.r,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),

        // Title
        Text(
          "Enter Verification Code",
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textColorPrimary,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),

        // Subtitle with phone number
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: "We've sent a 6-digit code to\n",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textColorSecondary,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: "+91 ${controller.phone}",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter Code",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textColorSecondary,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 16.h),

        // OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return _buildOTPBox(index);
          }),
        ),

        // ✅ Error message below OTP boxes
        Obx(() {
          if (controller.otpError.value.isEmpty) {
            return SizedBox(height: 12.h);
          }
          return Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16.r,
                  color: AppColors.error,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    controller.otpError.value,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOTPBox(int index) {
    return GestureDetector(
      onTap: () {
        if (!controller.isVerifying.value) {
          controller.focusNodes[index].requestFocus();
        }
      },
      child: Obx(() {
        final isFocused = controller.focusNodes[index].hasFocus;
        final hasValue = controller.otpControllers[index].text.isNotEmpty;

        return Container(
          width: 50.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color:
                  isFocused
                      ? AppColors.primary
                      : hasValue
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
              width: isFocused ? 2.w : 1.w,
            ),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: controller.otpControllers[index],
              focusNode: controller.focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              enabled: !controller.isVerifying.value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) {
                // ✅ Clear error message when user starts typing new OTP
                if (controller.otpError.value.isNotEmpty) {
                  controller.otpError.value = "";
                }

                if (value.length == 1 && index < 5) {
                  FocusScope.of(
                    Get.context!,
                  ).requestFocus(controller.focusNodes[index + 1]);
                }

                if (value.isEmpty && index > 0) {
                  FocusScope.of(
                    Get.context!,
                  ).requestFocus(controller.focusNodes[index - 1]);
                }

                // Auto verify when all fields are filled
                if (controller.otpControllers.every((c) => c.text.isNotEmpty)) {
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    controller.verifyAndLogin,
                  );
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDeliveryMethod() {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12.r,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Get OTP via",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textColorPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                // WhatsApp Toggle
                Expanded(
                  child: _buildToggleOption(
                    icon: Icons.message,
                    label: "WhatsApp",
                    isActive: controller.otpMode.value == "whatsapp",
                    onTap: () => controller.otpMode.value = "whatsapp",
                    showBadge: true,
                  ),
                ),
                SizedBox(width: 12.w),

                // SMS Toggle
                Expanded(
                  child:
                      controller.showSmsOption.value
                          ? _buildToggleOption(
                            icon: Icons.sms,
                            label: "SMS",
                            isActive: controller.otpMode.value == "sms",
                            onTap: () => controller.otpMode.value = "sms",
                          )
                          : _buildTimerBadge(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[200]!,
            width: isActive ? 1.5.w : 1.w,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  icon,
                  size: 20.r,
                  color: isActive ? AppColors.primary : Colors.grey[600],
                ),
                if (showBadge)
                  Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey[200]!, width: 1.w),
      ),
      child: Column(
        children: [
          Icon(Icons.timer_rounded, size: 20.r, color: Colors.amber[700]),
          SizedBox(height: 6.h),
          Text(
            "${Get.find<OTPController>().smsCountdownSeconds.value}s",
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Obx(
      () => Column(
        children: [
          Text(
            "Didn't receive the code?",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 12.h),

          GestureDetector(
            onTap:
                controller.resendEnabled.value
                    ? () => controller.resendOTP()
                    : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
              decoration: BoxDecoration(
                gradient:
                    controller.resendEnabled.value
                        ? LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color:
                    controller.resendEnabled.value
                        ? null
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      controller.resendEnabled.value
                          ? AppColors.primary.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 20.r,
                    color:
                        controller.resendEnabled.value
                            ? AppColors.primary
                            : Colors.grey,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    controller.resendEnabled.value
                        ? "Resend OTP"
                        : "Resend in ${controller.secondsRemaining.value}s",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          controller.resendEnabled.value
                              ? AppColors.primary
                              : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed:
              controller.isVerifying.value
                  ? null
                  : () {
                    if (controller.otpControllers.every(
                      (c) => c.text.isNotEmpty,
                    )) {
                      controller.verifyAndLogin();
                    } else {
                      Get.snackbar(
                        "Incomplete OTP",
                        "Please enter all 6 digits",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            elevation: 0,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child:
              controller.isVerifying.value
                  ? SizedBox(
                    width: 24.r,
                    height: 24.r,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Verify & Continue",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_rounded, size: 20.r),
                    ],
                  ),
        ),
      ),
    );
  }
}
