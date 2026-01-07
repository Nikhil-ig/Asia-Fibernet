// lib/src/ui/screen/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; // 👈 Added Iconsax

import '../../customer/ui/widgets/app_textfield.dart';
import '../../theme/colors.dart';
import '../../theme/theme.dart';
import '../core/controller/signup_controller.dart';

class SignUpScreen extends GetView<SignUpController> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Obx(() {
          return Stack(
            children: [
              // Background Elements
              _buildBackgroundElements(),

              // Content
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // App Bar
                  SliverAppBar(
                    title: Text(
                      "New Connection",
                      style: AppText.headingMedium.copyWith(
                        color: AppColors.backgroundLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.backgroundLight,
                        ),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Form Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Welcome Card
                            _buildWelcomeCard(),
                            const SizedBox(height: 32),

                            // Form Container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Progress Indicator
                                  _buildProgressIndicator(),
                                  const SizedBox(height: 24),

                                  // Personal Details Section
                                  _buildSectionHeader(
                                    "Personal Details",
                                    Iconsax.user,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.fullNameController,
                                    labelText: "Full Name",
                                    prefixIcon: Icon(
                                      Iconsax.user,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.name,
                                    validator:
                                        (value) =>
                                            (value?.isEmpty ?? true)
                                                ? 'Please enter your full name'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller:
                                        controller.mobileNumberController,
                                    labelText: "Mobile Number",
                                    prefixIcon: Icon(
                                      Iconsax.call,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value?.isEmpty ?? true)
                                        return 'Please enter mobile number';
                                      if (value!.length != 10)
                                        return 'Invalid mobile number';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.emailController,
                                    labelText: "Email Address",
                                    prefixIcon: Icon(
                                      Iconsax.sms,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true)
                                        return 'Please enter email';
                                      if (!GetUtils.isEmail(value!))
                                        return 'Invalid email address';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Address Section
                                  _buildSectionHeader(
                                    "Installation Address",
                                    Iconsax.location,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.addressController,
                                    labelText: "Full Address",
                                    prefixIcon: Icon(
                                      Iconsax.home,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    validator:
                                        (value) =>
                                            (value?.isEmpty ?? true)
                                                ? 'Please enter address'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.stateController,
                                    labelText: "State",
                                    prefixIcon: Icon(
                                      Iconsax.global,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.text,
                                    validator:
                                        (value) =>
                                            (value?.isEmpty ?? true)
                                                ? 'Please enter state'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.cityController,
                                    labelText: "City",
                                    prefixIcon: Icon(
                                      Iconsax.location,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.text,
                                    validator:
                                        (value) =>
                                            (value?.isEmpty ?? true)
                                                ? 'Please enter city'
                                                : null,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller: controller.pincodeController,
                                    labelText: "Pincode",
                                    prefixIcon: Icon(
                                      Iconsax.arrange_square,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    maxLength: 6,
                                  ),
                                  const SizedBox(height: 24),

                                  // Referral Section
                                  _buildSectionHeader(
                                    "Referral Code (Optional)",
                                    Iconsax.ticket,
                                  ),
                                  const SizedBox(height: 16),

                                  AppTextField(
                                    controller:
                                        controller.referralCodeController,
                                    labelText: "Enter referral code",
                                    prefixIcon: Icon(
                                      Iconsax.gift,
                                      color: AppColors.primary,
                                    ),
                                    keyboardType: TextInputType.text,
                                  ),
                                  const SizedBox(height: 32),

                                  // Submit Button
                                  _buildSubmitButton(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Loading Overlay
              if (controller.isRegistering.value) _buildLoadingOverlay(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primaryDark.withOpacity(0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryDark.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return ScaleTransition(
      scale: controller.cardAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ultra-Fast Fiber Connection",
                    style: AppText.headingSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Get connected within 48 hours • Free installation",
                    style: AppText.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.clock, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            "Takes only 2 minutes",
            style: AppText.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppText.labelMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed:
            controller.isRegistering.value
                ? null
                : () {
                  if (_formKey.currentState!.validate()) {
                    controller.registerCustomer();
                  }
                },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child:
            controller.isRegistering.value
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.send, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "SUBMIT APPLICATION",
                      style: AppText.button.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                "Processing your application...",
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.textColorPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
