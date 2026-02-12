import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import './controller/notification_settings_controller.dart';

class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: AppColors.primary, // As seen in the image
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.backgroundLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Container(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            alignment: Alignment.centerLeft,
            child: Text(
              'Manage how you receive updates',
              style: TextStyle(
                color: AppColors.backgroundLight.withAlpha(200),
                fontSize: 14,
              ),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.backgroundLight),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ========== LANGUAGE & NOTIFICATION STATUS SECTION ==========
          _buildSectionHeader(
            'General Settings',
            'Manage language and notification status',
          ),

          // Language Selection
          Obx(
            () => Card(
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.language,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Language',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.userPrefLanguage.value == 'en'
                                    ? 'English'
                                    : 'ಕನ್ನಡ (Kannada)',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.updateUserPreference(
                                language: 'en',
                                notifStatus:
                                    controller.notificationStatus.value,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  controller.userPrefLanguage.value == 'en'
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                              side: BorderSide(
                                color:
                                    controller.userPrefLanguage.value == 'en'
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              'English',
                              style: TextStyle(
                                color:
                                    controller.userPrefLanguage.value == 'en'
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.updateUserPreference(
                                language: 'ka',
                                notifStatus:
                                    controller.notificationStatus.value,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  controller.userPrefLanguage.value == 'ka'
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                              side: BorderSide(
                                color:
                                    controller.userPrefLanguage.value == 'ka'
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              'ಕನ್ನಡ',
                              style: TextStyle(
                                color:
                                    controller.userPrefLanguage.value == 'ka'
                                        ? AppColors.primary
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Notification Status Toggle
          if (AppSharedPref.instance.getRole() == 'customer')
            Card(
              elevation: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Obx(
                  () => Text(
                    controller.notificationStatus.value
                        ? 'All notifications enabled'
                        : 'All notifications disabled',
                  ),
                ),
                trailing: Obx(
                  () => Switch(
                    value: controller.notificationStatus.value,
                    onChanged: (bool newValue) {
                      controller.updateUserPreference(
                        language: controller.userPrefLanguage.value,
                        notifStatus: newValue,
                      );
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
              ),
            ),

          // const SizedBox(height: 24),

          // // ========== NOTIFICATION CHANNELS SECTION ==========
          // _buildSectionHeader(
          //   'Notification Channels',
          //   'Choose how to receive notifications',
          // ),
          // _buildChannelTile(
          //   icon: Icons.email_outlined,
          //   title: 'Email',
          //   subtitle: 'user@example.com',
          //   value: controller.emailNotifications,
          // ),
          // _buildChannelTile(
          //   icon: Icons.sms_outlined,
          //   title: 'SMS',
          //   subtitle: '+1 234-567-8900',
          //   value: controller.smsNotifications,
          // ),

          // Card(
          //   elevation: 0.5,
          //   margin: const EdgeInsets.symmetric(vertical: 4.0),
          //   child: ListTile(
          //     leading: const Icon(
          //       Icons.push_pin_outlined,
          //       color: AppColors.primary,
          //     ),
          //     title: const Text(
          //       'Push Notifications',
          //       style: TextStyle(fontWeight: FontWeight.w500),
          //     ),
          //     subtitle: const Text('This device'),
          //     trailing: Obx(
          //       () => Switch(
          //         value: controller.pushNotifications.value,
          //         onChanged: (bool newValue) {
          //           controller.togglePushNotifications(newValue);
          //         },
          //         activeColor: AppColors.primary,
          //       ),
          //     ),
          //   ),
          // ),

          // const SizedBox(height: 24),

          // // ========== NOTIFICATION PREFERENCES SECTION ==========
          // _buildSectionHeader(
          //   'Notification Preferences',
          //   'Select what you want to be notified about',
          // ),
          // _buildPreferenceTile(
          //   title: 'Billing & Payments',
          //   subtitle: 'Payment confirmations, invoice updates',
          //   value: controller.billingPayments,
          // ),
          // _buildPreferenceTile(
          //   title: 'Service Outages',
          //   subtitle: 'Network issues, maintenance alerts',
          //   value: controller.serviceOutages,
          // ),
          // _buildPreferenceTile(
          //   title: 'Complaint Updates',
          //   subtitle: 'Status updates on your complaints',
          //   value: controller.complaintUpdates,
          // ),
          // _buildPreferenceTile(
          //   title: 'Plan Expiry',
          //   subtitle: 'Reminders before plan expiration',
          //   value: controller.planExpiry,
          // ),
          // _buildPreferenceTile(
          //   title: 'Offers & Promotions',
          //   subtitle: 'Special deals and discounts',
          //   value: controller.offersAndPromotions,
          // ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => ElevatedButton(
            onPressed:
                controller.isLoading.value
                    ? null
                    : () {
                      controller.updateUserPreference(
                        language: controller.userPrefLanguage.value,
                        notifStatus: controller.notificationStatus.value,
                      );
                      Navigator.pop(Get.context!);
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.backgroundLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                controller.isLoading.value
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.backgroundLight,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Save Preferences',
                      style: TextStyle(color: AppColors.backgroundLight),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
