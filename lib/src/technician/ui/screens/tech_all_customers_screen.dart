// src/screens/customers/all_customers_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../theme/colors.dart';
import '../../core/models/customer_model.dart';
import 'customer_detail_screen.dart';

// src/screens/customers/all_customers_controller.dart

class AllCustomersController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  var customers = <CustomerModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  var searchTerm = ''.obs; // ✅ For search

  // @override
  // void onInit() {
  //   super.onInit();
  //   // fetchCustomers();
  // }
  // Future<void> fetchCustomers() async {
  //   try {
  //     isLoading.value = true;
  //     error.value = '';
  //     final result = await _api.fetchAllCustomers();
  //     if (result != null) {
  //       customers.assignAll(result);
  //     } else {
  //       error.value = 'No customers found.';
  //     }
  //   } catch (e) {
  //     error.value = 'Failed to load customers. Please try again.';
  //     print("CustomersController Error: $e");
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }
  // ✅ NEW: Search by mobile or name
  // src/screens/customers/all_customers_controller.dart
  // (Assuming this is inside the AllCustomersController class)
  // ✅ NEW: Search by mobile or name (Corrected API call)
  Future<void> searchCustomers(String query) async {
    // if (query.trim().isEmpty) {
    //   await fetchCustomers(); // Reset to all
    //   return;
    // }

    try {
      isLoading.value = true;
      error.value = '';
      // Explicitly pass the named parameter
      final result = query != '' ? await _api.searchCustomers(query) : null;
      if (result != null) {
        // API returned a list (potentially empty)
        customers.assignAll(result);
        // Optional: Set a specific message if result is empty?
        // if (result.isEmpty) {
        //   error.value = 'No customers found matching "$query".';
        // }
      } else {
        // API returned null, indicating an error
        // error.value = 'Search failed. Please try again.';
        // Optionally clear the list to reflect the error state visually
        // customers.clear();
      }
    } catch (e) {
      // Catch any unexpected errors during the process (though API method should handle most)
      error.value = 'An unexpected error occurred during search.';
      print("Unexpected Search Error in Controller: $e");
      // Optionally clear the list
      // customers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Debounce logic remains the same
  void onSearchChanged(String value) {
    searchTerm.value = value;
    debounceSearch(value);
  }

  Timer? _debounce;
  void debounceSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchCustomers(value); // This call is now clearer
    });
  }

  // Refresh logic
  Future<void> refreshData() async {
    searchTerm.value = ''; // ✅ Clear search on refresh
    // await fetchCustomers(); // Fetch all again
    // Clear any error state on manual refresh?
    // error.value = '';
  }

  // onClose remains the same
  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}

class AllCustomersScreen extends StatelessWidget {
  AllCustomersScreen({Key? key}) : super(key: key);

  final AllCustomersController controller = Get.put(AllCustomersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Search Bar
            _buildSearchBar(controller),

            // ✅ Results
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return _buildLoading();
                }

                // if (controller.error.value.isNotEmpty) {
                //   return _buildError();
                // }

                if (controller.customers.isEmpty) {
                  return _buildEmpty();
                }

                return _buildCustomerList();
              }),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Raise Ticket',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // centerTitle: false,
      backgroundColor: AppColors.primary,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.white),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.refresh, color: Colors.white),
      //     onPressed: () => controller.refreshData(),
      //   ),
      // ],
    );
  }

  // ✅ NEW: Search Bar
  Widget _buildSearchBar(AllCustomersController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.backgroundLight,
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: Obx(
            () =>
                controller.searchTerm.value.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        controller.searchTerm.value = '';
                        // controller.fetchCustomers();
                      },
                    )
                    : SizedBox(),
          ),
          hintText: 'Search by name or mobile...',
          hintStyle: TextStyle(color: AppColors.textColorHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        style: TextStyle(color: AppColors.textColorPrimary),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          backgroundColor: AppColors.primaryLight,
        ),
      ),
    );
  }

  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 80, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => controller.refreshData(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 60,
            color: AppColors.textColorHint,
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              controller.searchTerm.value.isNotEmpty
                  ? 'No customers match "${controller.searchTerm.value}"'
                  : 'No customers assigned yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColorHint, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return RefreshIndicator(
      onRefresh: () => controller.refreshData(),
      displacement: 60,
      color: AppColors.primary,
      backgroundColor: AppColors.backgroundLight,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.customers.length,
        separatorBuilder:
            (_, __) => Divider(
              color: AppColors.dividerColor,
              indent: 60,
              endIndent: 16,
            ),
        itemBuilder: (context, index) {
          final customer = controller.customers[index];
          return _buildCustomerCard(customer);
        },
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    return InkWell(
      onTap: () {
        // Assuming you have the customerId
        int customerId =
            customer
                .findCustomerId; // Or customer.id based on your CustomerModel
        Get.to(
          () => const CustomerDetailsScreen(),
          arguments: {'customerId': customerId},
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.primaryLight.withOpacity(0.2),
            width: 1,
          ),
        ),
        shadowColor: AppColors.primary.withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.primaryLight.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      customer.contactName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColorPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              _buildDetail(Icons.business, 'ID: ${customer.findCustomerId}'),
              _buildDetail(Icons.phone, customer.displayPhone),
              _buildDetail(Icons.email, customer.displayEmail),
              if (customer.area != null && customer.area!.isNotEmpty)
                _buildDetail(Icons.location_on, customer.displayArea),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColorSecondary,
                height: 1.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
