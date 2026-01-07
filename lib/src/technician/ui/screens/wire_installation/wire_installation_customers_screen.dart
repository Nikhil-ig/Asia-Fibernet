import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/colors.dart';
import '../../../core/controller/wire_installation_customers_controller.dart';
import 'wire_installation_details_screen.dart';
// import 'wire_installation_details_screen.dart';
// import 'wire_installation_customers_controller.dart';

class WireInstallationCustomersScreen extends StatelessWidget {
  const WireInstallationCustomersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WireInstallationCustomersController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wire Installation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.customers.isEmpty) {
            return const Center(
              child: Text(
                'No wire installation jobs assigned.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: controller.customers.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.dividerColor),
            itemBuilder: (context, index) {
              final customer = controller.customers[index];
              return _buildCustomerCard(customer);
            },
          );
        }),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cable, color: AppColors.primary),
        ),
        title: Text(
          customer['full_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(customer['mobile_number'] ?? ''),
        
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.primary,
        ),
        onTap: () {
          Get.to(
            () => const WireInstallationDetailsScreen(),
            arguments: {'customerId': customer['id']},
          );
        },
      ),
    );
  }
}
