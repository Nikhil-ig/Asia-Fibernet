import 'dart:convert';
import 'dart:io';
import 'package:asia_fibernet/src/services/sharedpref.dart';
import 'package:asia_fibernet/src/technician/core/models/find_customer_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/core/model/customer_details_model.dart';
import '../../../customer/core/models/ticket_category_model.dart';
import '../../../services/apis/api_services.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/theme.dart';

class CustomerDetailsController extends GetxController {
  final TechnicianAPI apiService = TechnicianAPI();

  final Rx<FindCustomerDetail> customerDetails = FindCustomerDetail().obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final ticketCategory = ''.obs;
  final ticketSubCategory = ''.obs;
  final ticketDescription = ''.obs;
  final isCreatingTicket = false.obs;
  final ticketImage = Rx<File?>(null);

  // ✅ For customer details update
  final isUpdatingDetails = false.obs;
  late TextEditingController emailController;
  late TextEditingController addressController;
  bool _isDisposed = false;

  int? _customerId;

  @override
  void onInit() {
    super.onInit();
    _isDisposed = false;
    emailController = TextEditingController();
    addressController = TextEditingController();

    final args = Get.arguments;
    if (args is Map && args['customerId'] is int) {
      _customerId = args['customerId'];
      fetchFindCustomerDetail();
    } else {
      errorMessage.value = 'Customer ID not provided.';
      BaseApiService().showSnackbar(
        "Error",
        "Customer ID is missing.",
        isError: true,
      );
      Get.back();
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    try {
      emailController.dispose();
    } catch (_) {}
    try {
      addressController.dispose();
    } catch (_) {}
    super.onClose();
  }

  Future<void> fetchFindCustomerDetail() async {
    if (_customerId == null) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      final details = await apiService.fetchCustomerById(_customerId!);
      if (details != null) {
        customerDetails.value = details;
      } else {
        errorMessage.value = 'Customer details could not be loaded.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      print("Error in CustomerDetailsController: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createTicket() async {
    if (_customerId == null) return;

    if (ticketCategory.value.isEmpty ||
        ticketSubCategory.value.isEmpty ||
        ticketDescription.value.isEmpty) {
      BaseApiService().showSnackbar(
        "Validation Error",
        "Please fill all required fields",
      );
      return;
    }
    String _formatDateTime(DateTime dt) {
      return "${dt.year % 100}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}-${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}";
    }

    final now = DateTime.now();
    try {
      isCreatingTicket.value = true;
      final ticketNo =
          'TKT-T-${_formatDateTime(now)}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';

      final ticketData = {
        "customer_id": _customerId,
        "registered_mobile": customerDetails.value.workphnumber ?? "",
        "ticket_no": ticketNo,
        "category": ticketCategory.value,
        "sub_category": ticketSubCategory.value,
        "description": ticketDescription.value,
        "status": "Assigned",
        "image_base64":
            ticketImage.value != null
                ? base64Encode(ticketImage.value!.readAsBytesSync())
                : null,
        "assign_to": AppSharedPref.instance.getUserID(),
      };

      await apiService.createTicket(ticketData);

      BaseApiService().showSnackbar("Success", "Ticket created successfully");

      // Reset form
      ticketCategory.value = '';
      ticketSubCategory.value = '';
      ticketDescription.value = '';
      ticketImage.value = null;

      // Close the bottom sheet
      Navigator.pop(Get.context!);
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to create ticket: $e",
        isError: true,
      );
    } finally {
      isCreatingTicket.value = false;
    }
  }

  void clearTicketImage() {
    ticketImage.value = null;
  }

  /// ✅ Update customer email and address
  Future<void> updateCustomerDetails() async {
    if (_customerId == null) return;

    final email = emailController.text.trim();
    final address = addressController.text.trim();

    if (email.isEmpty && address.isEmpty) {
      BaseApiService().showSnackbar(
        "Validation Error",
        "Please fill at least one field",
      );
      return;
    }

    try {
      isUpdatingDetails.value = true;

      // Prepare update data
      final updateData = <String, dynamic>{"customer_id": _customerId};

      if (email.isNotEmpty) updateData["email"] = email;
      if (address.isNotEmpty) updateData["address"] = address;

      // Call API using BaseApiService
      final apiResponse = await BaseApiService(
        BaseApiService.api,
      ).post("edit_customer_details.php", body: updateData);

      if (apiResponse.statusCode == 200) {
        // Refresh customer details from API
        await fetchFindCustomerDetail();

        BaseApiService().showSnackbar(
          "Success",
          "Customer details updated successfully",
        );
        Get.back();
      } else {
        BaseApiService().showSnackbar(
          "Error",
          "Failed to update details",
          isError: true,
        );
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "An error occurred: $e",
        isError: true,
      );
      print("Error updating customer details: $e");
    } finally {
      isUpdatingDetails.value = false;
    }
  }
}

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({Key? key}) : super(key: key);

  /// ✅ Show edit customer details dialog
  void _showEditDetailsDialog(CustomerDetailsController controller) {
    // ✅ Safety check: ensure controller is not disposed
    if (controller._isDisposed) {
      BaseApiService().showSnackbar(
        "Error",
        "Controller has been disposed. Please try again.",
        isError: true,
      );
      return;
    }

    // Initialize text controllers with current values
    try {
      controller.emailController.text =
          controller.customerDetails.value.email ?? '';
      controller.addressController.text =
          controller.customerDetails.value.address ?? '';
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to initialize form fields",
        isError: true,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Update Customer Details',
                      style: AppText.headingMedium,
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Email Field
                Text('Email', style: AppText.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 20),

                // Address Field
                Text('Address', style: AppText.labelMedium),
                SizedBox(height: 8),
                TextField(
                  controller: controller.addressController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppText.labelMedium.copyWith(
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => ElevatedButton(
                          onPressed:
                              controller.isUpdatingDetails.value
                                  ? null
                                  : () => controller.updateCustomerDetails(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.5),
                          ),
                          child:
                              controller.isUpdatingDetails.value
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : Text('Update', style: AppText.button),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerDetailsController());

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Gradient
          SliverAppBar(
            // expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Customer Profile',
                style: AppText.headingMedium.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      // AppColors.primary.withOpacity(0.8),
                      AppColors.primaryDark.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background decorative elements
                    Positioned(
                      top: -50,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      left: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            iconTheme: IconThemeData(color: AppColors.backgroundLight),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              } else if (controller.errorMessage.isNotEmpty) {
                return _buildErrorState(controller);
              } else {
                return _buildCustomerContent(context, controller);
              }
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTicketCreationSheet(context, controller),
        label: Text("Raise Ticket", style: AppText.button),
        icon: Icon(Icons.add, size: 24, color: AppColors.backgroundLight),

        //         child: GestureDetector(
        //   onTap: () => _showTicketCreationSheet(context, controller),

        //   child: Container(
        //     margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        //     padding: EdgeInsets.all(10),
        //     alignment: Alignment.center,
        //     width: double.infinity,
        //     decoration: BoxDecoration(
        //       gradient: LinearGradient(
        //         begin: Alignment.topLeft,
        //         end: Alignment.bottomRight,
        //         colors: [
        //           AppColors.primary.withOpacity(0.9),
        //           AppColors.primaryDark.withOpacity(0.8),
        //         ],
        //       ),
        //       borderRadius: BorderRadius.circular(25),
        //       boxShadow: [
        //         BoxShadow(
        //           color: AppColors.primary.withOpacity(0.3),
        //           blurRadius: 20,
        //           offset: Offset(0, 10),
        //         ),
        //       ],
        //     ),
        //     child: Row(
        //       crossAxisAlignment: CrossAxisAlignment.center,
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       spacing: 8,
        //       children: [

        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading Customer Details...',
              style: AppText.bodyLarge.copyWith(
                color: AppColors.textColorSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CustomerDetailsController controller) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 50, color: AppColors.error),
          ),
          SizedBox(height: 20),
          Text(
            'Oops!',
            style: AppText.headingLarge.copyWith(color: AppColors.error),
          ),
          SizedBox(height: 10),
          Text(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            style: AppText.bodyLarge.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: controller.fetchFindCustomerDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
            ),
            child: Text('Try Again', style: AppText.button),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerContent(context, CustomerDetailsController controller) {
    final customer = controller.customerDetails.value;

    return Column(
      children: [
        // Profile Card
        _buildProfileCard(customer),

        // Raise Ticket Card
        // _buildRaiseTicketCard(context, controller),

        // // Quick Stats (if available)
        // _buildQuickStats(customer),
        _buildInfoSection(
          title: 'Service Information',
          icon: Icons.settings_rounded,
          children: [
            if (customer.frServiceCode?.isNotEmpty ?? false)
              _buildInfoItem(
                Icons.code_rounded,
                'Service Code',
                customer.frServiceCode!,
              ),
            if (customer.serviceNumber?.isNotEmpty ?? false)
              _buildInfoItem(
                Icons.fiber_pin_rounded,
                'FTTH Number',
                customer.serviceNumber!,
              ),
            if (customer.subscriptionPlan?.isNotEmpty ?? false)
              _buildInfoItem(
                Icons.receipt_long_rounded,
                'Plan',
                customer.subscriptionPlan!,
              ),
          ],
        ),

        // Information Sections
        _buildInfoSection(
          title: 'Contact Information',
          icon: Icons.contact_phone_rounded,
          onEdit: () => _showEditDetailsDialog(controller),
          children: [
            if (customer.email?.isNotEmpty ?? false)
              _buildInfoItem(Icons.email_rounded, 'Email', customer.email!),
            if (customer.workphnumber != null)
              _buildInfoItem(
                Icons.work_rounded,
                'Work Phone',
                customer.workphnumber.toString(),
              ),
            // if (customer.cellPhone?.isNotEmpty ?? false)
            //   _buildInfoItem(
            //     Icons.phone_iphone_rounded,
            //     'Mobile',
            //     customer.cellPhone!,
            //   ),
          ],
        ),

        _buildInfoSection(
          title: 'Address Details',
          icon: Icons.location_pin,
          onEdit: () => _showEditDetailsDialog(controller),
          children: [
            if (customer.address?.isNotEmpty ?? false)
              _buildInfoItem(Icons.home_rounded, 'Address', customer.address!),
            if ((customer.city?.isNotEmpty ?? false) ||
                (customer.state?.isNotEmpty ?? false))
              _buildInfoItem(
                Icons.location_city_rounded,
                'Location',
                '${customer.city ?? ''}${(customer.city?.isNotEmpty ?? false) && (customer.state?.isNotEmpty ?? false) ? ', ' : ''}${customer.state ?? ''}',
              ),
          ],
        ),

        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProfileCard(FindCustomerDetail customer) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primaryDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  customer.profilePhoto != null
                      ? Image.network(
                        customer.profilePhoto!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.white.withOpacity(0.2),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
            ),
          ),

          SizedBox(width: 20),

          // Customer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.contactName ?? 'Unnamed Customer',
                  style: AppText.headingLarge.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 8),

                if (customer.accountId != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ID: ${customer.accountId}',
                      style: AppText.labelMedium.copyWith(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaiseTicketCard(context, CustomerDetailsController controller) {
    return GestureDetector(
      onTap: () => _showTicketCreationSheet(context, controller),

      child: Container(
        margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
        padding: EdgeInsets.all(10),
        alignment: Alignment.center,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primaryDark.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(Icons.add, size: 24, color: AppColors.backgroundLight),
            Text(
              "Raise Ticket",
              style: AppText.button,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(CustomerDetails customer) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.phone_in_talk_rounded,
              value: 'Active',
              label: 'Status',
              color: AppColors.success,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.calendar_today_rounded,
              value: 'Member',
              label: 'Since 2024',
              color: AppColors.warning,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star_rounded,
              value: 'Premium',
              label: 'Tier',
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: AppText.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textColorPrimary,
            ),
          ),
          Text(
            label,
            style: AppText.labelSmall.copyWith(
              color: AppColors.textColorSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    if (children.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Text(title, style: AppText.headingMedium),
                ],
              ),
              // ✅ Edit button
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: AppColors.primary),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.textColorSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColorPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketCreationSheet(
    BuildContext context,
    CustomerDetailsController controller,
  ) {
    final customerId = controller._customerId;
    final mobile = controller.customerDetails.value.workphnumber;

    if (customerId == null || mobile == null) {
      BaseApiService().showSnackbar(
        "Error",
        "Customer info incomplete.",
        isError: true,
      );
      return;
    }

    Get.lazyPut(
      () => TicketCreationController(
        customerId: customerId,
        customerMobile: mobile.toString(),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .85,
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => TicketCreationBottomSheet(),
    );
  }
}

// lib/controllers/ticket_creation_controller.dart=
class TicketCreationController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  // Customer data (passed from outside)
  final int? customerId;
  final String customerMobile;

  // State
  final Rx<CategoryData?> selectedCategory = Rx<CategoryData?>(null);
  final Rx<SubCategory?> selectedSubcategory = Rx<SubCategory?>(null);
  final RxString selectedDescription = ''.obs; // NEW: For selected description
  final RxString description = ''.obs;
  final Rx<File?> uploadedImage = Rx<File?>(null);
  final RxBool isSubmitting = false.obs;
  final RxBool isCategoriesLoading = true.obs;
  final RxList<CategoryData> ticketCategories = <CategoryData>[].obs;

  // Validation
  bool get isCategoryValid => selectedCategory.value != null;
  bool get isSubcategoryValid => selectedSubcategory.value != null;
  bool get isDescriptionValid => description.value.trim().isNotEmpty;
  bool get canSubmit =>
      isCategoryValid && isSubcategoryValid && isDescriptionValid;

  // Constructor to accept customer info
  TicketCreationController({
    required this.customerId,
    required this.customerMobile,
  });

  @override
  void onInit() {
    super.onInit();
    if (customerId == null) {
      BaseApiService().showSnackbar("Error", "Customer ID is missing.");
      Get.back();
      return;
    }
    fetchTicketCategories();
  }

  Future<void> fetchTicketCategories() async {
    isCategoriesLoading.value = true;
    try {
      final response = await ApiServices().getTicketCategory();
      if (response?.data != null) {
        ticketCategories.assignAll(response!.data);
      } else {
        BaseApiService().showSnackbar("Error", "Could not load categories");
      }
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to load categories. Please check your connection.",
      );
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void clear() {
    selectedCategory.value = null;
    selectedSubcategory.value = null;
    selectedDescription.value = ''; // NEW: Clear description
    description.value = '';
    uploadedImage.value = null;
  }

  void setImage(File? file) => uploadedImage.value = file;
  void setDescription(String value) => description.value = value;
  void setSelectedDescription(String value) =>
      selectedDescription.value = value; // NEW

  // ✅ NEW: createTicket using new state variables
  Future<void> createTicket() async {
    if (customerId == null) {
      BaseApiService().showSnackbar("Error", "Customer ID is missing.");
      return;
    }

    if (!canSubmit) {
      BaseApiService().showSnackbar(
        "Validation Error",
        "Please fill all required fields",
      );
      return;
    }

    String _formatDateTime(DateTime dt) {
      return "${dt.year % 100}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}-${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}";
    }

    final now = DateTime.now();
    final ticketNo =
        'TKT-T-${_formatDateTime(now)}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';

    final base64 =
        uploadedImage.value != null
            ? base64Encode(
              await uploadedImage.value!.readAsBytes(),
            ) // Use async read
            : null;

    try {
      isSubmitting.value = true;

      final ticketData = {
        "customer_id": customerId,
        "registered_mobile": customerMobile,
        "ticket_no": ticketNo,
        "category":
            selectedCategory
                .value!
                .categoryName, // assuming CategoryData has 'name'
        "sub_category":
            selectedSubcategory
                .value!
                .subcategoryName, // assuming SubCategory has 'name'
        "description": description.value.trim(),
        "status": "Assigned",
        "image_base64": base64,
        "assign_to": AppSharedPref.instance.getUserID(),
      };

      await _api.createTicket(ticketData);

      BaseApiService().showSnackbar("Success", "Ticket created successfully");

      // Reset form
      clear();

      // Close the bottom sheet or navigate back
      Navigator.pop(Get.context!);
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to create ticket: ${e.toString()}",
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearTicketImage() {
    uploadedImage.value = null;
  }
}

// lib/screens/complaints/ticket_creation_bottom_sheet.dart
class TicketCreationBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TicketCreationController>();

    final mobile =
        AppSharedPref.instance.getMobileNumber(); // Or however you get mobile

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    // AppColors.primary.withOpacity(0.8),
                    AppColors.primaryDark,
                  ], //[Color(0xFF6366F1), Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Create New Ticket",
                        style: AppText.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Obx(
                      () => _buildDropdownField(
                        label: "Category",
                        hint: "Select a category",
                        value: controller.selectedCategory.value?.categoryName,
                        isLoading: controller.isCategoriesLoading.value,
                        onTap: () => _showCategoryDialog(context, controller),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Subcategory
                    Obx(() {
                      if (controller.selectedCategory.value == null)
                        return SizedBox.shrink();
                      final subs =
                          controller.selectedCategory.value!.subcategories;
                      if (subs.isEmpty) return SizedBox.shrink();
                      return _buildDropdownField(
                        label: "Sub Category",
                        hint: "Select subcategory",
                        value:
                            controller
                                .selectedSubcategory
                                .value
                                ?.subcategoryName,
                        isLoading: false,
                        onTap:
                            () => _showSubcategoryDialog(context, controller),
                      );
                    }),

                    SizedBox(height: 16),

                    // Description - Dropdown if available, TextField otherwise
                    Obx(() {
                      final hasDescriptions =
                          controller.selectedSubcategory.value?.descriptions !=
                              null &&
                          controller
                              .selectedSubcategory
                              .value!
                              .descriptions
                              .isNotEmpty;

                      if (hasDescriptions) {
                        return _buildDropdownField(
                          label: "Description",
                          hint: "Select a description",
                          value:
                              controller.selectedDescription.value.isEmpty
                                  ? null
                                  : controller.selectedDescription.value,
                          isLoading: false,
                          onTap:
                              () => _showDescriptionDialog(context, controller),
                        );
                      } else {
                        return _buildTextField(
                          controller: controller.description,
                          label: "Description",
                          hint: "Describe your issue in detail...",
                          maxLines: 4,
                        );
                      }
                    }),

                    SizedBox(height: 20),

                    // Image
                    _buildImageSection(controller),

                    SizedBox(height: 30),

                    // Submit Button
                    Obx(
                      () => _buildSubmitButton(
                        controller,
                        mobile: mobile,
                        onPressed: () => controller.createTicket(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable UI Helpers (same as before) ---
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelMedium),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: AppText.bodyMedium.copyWith(
                      color:
                          value != null
                              ? AppColors.textColorPrimary
                              : AppColors.textColorHint,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required RxString controller,
    required String label,
    required String hint,
    required int maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.labelMedium),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (v) => controller.value = v,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.bodyMedium.copyWith(
                color: AppColors.textColorHint,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(TicketCreationController controller) {
    return Obx(() {
      if (controller.uploadedImage.value == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Attach Image (Optional)", style: AppText.labelMedium),
            SizedBox(height: 12),
            Row(
              children: [
                _buildImageOption(
                  "Camera",
                  Icons.camera_alt_outlined,
                  () => _pickImage(ImageSource.camera, controller),
                ),
                SizedBox(width: 12),
                _buildImageOption(
                  "Gallery",
                  Icons.photo_library_outlined,
                  () => _pickImage(ImageSource.gallery, controller),
                ),
              ],
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Preview", style: AppText.labelMedium),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                controller.uploadedImage.value!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => _pickImage(ImageSource.gallery, controller),
                    icon: Icon(Icons.refresh, size: 18),
                    label: Text("Change"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => controller.setImage(null),
                    icon: Icon(Icons.delete, size: 18),
                    label: Text("Remove"),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    });
  }

  Widget _buildImageOption(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.primary, size: 24),
          label: Text(
            label,
            style: AppText.labelMedium.copyWith(color: AppColors.primary),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.all(8),
            alignment: Alignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(
    TicketCreationController controller, {
    required String? mobile,
    required VoidCallback onPressed,
  }) {
    final enabled =
        mobile != null &&
        controller.canSubmit &&
        !controller.isSubmitting.value;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.primary : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child:
            controller.isSubmitting.value
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text("Submit Ticket", style: AppText.button),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    TicketCreationController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Obx(() {
            if (controller.isCategoriesLoading.value)
              return Center(child: CircularProgressIndicator());
            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: controller.ticketCategories.length,
              itemBuilder: (context, index) {
                final cat = controller.ticketCategories[index];
                return ListTile(
                  title: Text(cat.categoryName, style: AppText.bodyLarge),
                  onTap: () {
                    controller.selectedCategory.value = cat;
                    controller.selectedSubcategory.value = null;
                    Navigator.pop(context);
                  },
                );
              },
            );
          }),
    );
  }

  void _showSubcategoryDialog(
    BuildContext context,
    TicketCreationController controller,
  ) {
    final subcategories =
        controller.selectedCategory.value?.subcategories ?? [];
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16),
            itemCount: subcategories.length,
            itemBuilder: (context, index) {
              final sub = subcategories[index];
              return ListTile(
                title: Text(sub.subcategoryName, style: AppText.bodyLarge),
                onTap: () {
                  controller.selectedSubcategory.value = sub;
                  Navigator.pop(context);
                },
              );
            },
          ),
    );
  }

  // ✅ NEW: Show description dialog
  void _showDescriptionDialog(
    BuildContext context,
    TicketCreationController controller,
  ) {
    final descriptions =
        controller.selectedSubcategory.value?.descriptions ?? [];

    // If no descriptions from API, allow manual entry
    if (descriptions.isEmpty) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Enter Description", style: AppText.headingSmall),
              content: TextField(
                controller: TextEditingController(
                  text: controller.selectedDescription.value,
                ),
                onChanged: (value) {
                  controller.setSelectedDescription(value);
                  controller.setDescription(value);
                },
                decoration: InputDecoration(
                  hintText: "Describe the issue...",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Done"),
                ),
              ],
            ),
      );
      return;
    }

    // Show as bottom sheet with predefined descriptions
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text("Select Description", style: AppText.headingSmall),
              ),
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: descriptions.length,
                  itemBuilder: (context, index) {
                    final desc = descriptions[index];
                    return ListTile(
                      title: Text(desc, style: AppText.bodyLarge),
                      onTap: () {
                        controller.setSelectedDescription(desc);
                        controller.setDescription(desc);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _pickImage(
    ImageSource source,
    TicketCreationController controller,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) controller.setImage(File(picked.path));
    } catch (e) {
      BaseApiService().showSnackbar(
        "Error",
        "Failed to pick image",
        isError: true,
      );
    }
  }
}
