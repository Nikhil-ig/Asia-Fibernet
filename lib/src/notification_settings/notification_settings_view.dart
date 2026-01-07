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
          _buildSectionHeader(
            'Notification Channels',
            'Choose how to receive notifications',
          ),
          _buildChannelTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: 'user@example.com',
            value: controller.emailNotifications,
          ),
          _buildChannelTile(
            icon: Icons.sms_outlined,
            title: 'SMS',
            subtitle: '+1 234-567-8900',
            value: controller.smsNotifications,
          ),

          // --- START: MODIFIED PUSH NOTIFICATION TILE ---
          // This tile is now custom to call the specific controller method.
          Card(
            elevation: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: const Icon(
                Icons.push_pin_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Push Notifications',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('This device'),
              trailing: Obx(
                () => Switch(
                  value: controller.pushNotifications.value,
                  onChanged: (bool newValue) {
                    // This now calls the specific method in the controller
                    // to handle subscribing/unsubscribing from Firebase.
                    controller.togglePushNotifications(newValue);
                  },
                  activeColor: AppColors.primary,
                ),
              ),
            ),
          ),

          // --- END: MODIFIED PUSH NOTIFICATION TILE ---
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Notification Preferences',
            'Select what you want to be notified about',
          ),
          _buildPreferenceTile(
            title: 'Billing & Payments',
            subtitle: 'Payment confirmations, invoice updates',
            value: controller.billingPayments,
          ),
          _buildPreferenceTile(
            title: 'Service Outages',
            subtitle: 'Network issues, maintenance alerts',
            value: controller.serviceOutages,
          ),
          _buildPreferenceTile(
            title: 'Complaint Updates',
            subtitle: 'Status updates on your complaints',
            value: controller.complaintUpdates,
          ),
          _buildPreferenceTile(
            title: 'Plan Expiry',
            subtitle: 'Reminders before plan expiration',
            value: controller.planExpiry,
          ),
          _buildPreferenceTile(
            title: 'Offers & Promotions',
            subtitle: 'Special deals and discounts',
            value: controller.offersAndPromotions,
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            controller.savePreferences();
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
          child: const Text(
            'Save Preferences',
            style: TextStyle(color: AppColors.backgroundLight),
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

  // This reusable widget is still perfect for the other toggles.
  Widget _buildChannelTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required RxBool value,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Obx(
          () => Switch(
            value: value.value,
            onChanged: (bool newValue) {
              value.value = newValue;
            },
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String subtitle,
    required RxBool value,
  }) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Obx(
          () => Switch(
            value: value.value,
            onChanged: (bool newValue) {
              value.value = newValue;
            },
            activeColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
