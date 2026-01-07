import 'package:asia_fibernet/src/technician/ui/screens/wire_installation/upload_installation_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/colors.dart';
import '../../../core/controller/wire_installation_details_controller.dart';

class WireInstallationDetailsScreen extends StatelessWidget {
  const WireInstallationDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WireInstallationDetailsController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Installation Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return _buildLoadingState();
          }

          if (controller.error.value.isNotEmpty) {
            return _buildErrorState(controller.error.value);
          }

          final data = controller.customerDetails.value;
          final customer = data['customer'] as Map<String, dynamic>?;
          final wire = data['wire_installation'] as Map<String, dynamic>?;

          if (customer == null) {
            return _buildErrorState('Customer data not available.');
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header with customer name
                _buildCustomerHeader(customer),

                const SizedBox(height: 16),

                // Main content cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Customer Information Card
                      _buildInfoCard(
                        title: 'Customer Information',
                        icon: Icons.person_outline,
                        color: AppColors.primary,
                        children: [
                          _buildInfoItem(
                            'Full Name',
                            customer['full_name'] ?? '–',
                          ),
                          _buildInfoItem(
                            'Mobile',
                            customer['mobile_number'] ?? '–',
                          ),
                          // _buildInfoItem('Email', customer['email'] ?? '–'),
                          _buildInfoItem('Address', customer['address'] ?? '–'),
                          _buildInfoItem(
                            'Plan',
                            customer['desired_plan'] ?? '–',
                          ),
                          // _buildInfoItem(
                          //   'Requested Hours',
                          //   customer['pending_from_hrs'] ?? '–',
                          // ),
                          _buildInfoItem(
                            'Assigned by',
                            customer['admin'] ?? '–',
                          ),
                          // _buildStatusRow(
                          //   'Aadhar Verified',
                          //   customer['aadhar_verified'] == 1,
                          // ),
                          // _buildStatusRow(
                          //   'Address Verified',
                          //   customer['address_verified'] == 1,
                          // ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Wire Installation Card
                      if (wire != null)
                        _buildInfoCard(
                          title: 'Wire Installation Details',
                          icon: Icons.cable,
                          color: Colors.green,
                          children: [
                            _buildInfoItem(
                              'Wire Type',
                              wire['wire_type']?.toString().isNotEmpty == true
                                  ? wire['wire_type']
                                  : 'Not specified',
                            ),
                            _buildInfoItem(
                              'Length',
                              '${wire['wire_length'] ?? '–'} km',
                            ),
                            _buildInfoItem(
                              'No. of Points',
                              wire['no_of_points']?.toString() ?? '–',
                            ),
                            _buildInfoItem(
                              'Cable Route',
                              wire['route_of_cables']?.toString().isNotEmpty ==
                                      true
                                  ? wire['route_of_cables']
                                  : 'Not specified',
                            ),
                            _buildInfoItem(
                              'Existing Wiring',
                              wire['existing_wiring'] ?? '–',
                            ),
                            _buildInfoItem(
                              'Account No.',
                              wire['account_no'] ?? '–',
                            ),
                            _buildInfoItem(
                              'Installed At',
                              _formatDate(wire['installed_at'] ?? '–'),
                            ),
                            _buildInfoItem(
                              'Remarks',
                              wire['remarks']?.toString().isNotEmpty == true
                                  ? wire['remarks']
                                  : 'No remarks',
                            ),
                          ],
                        )
                      else
                        _buildNoWireInstallationCard(),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Assuming 'customer' is a map available in your widget's scope
                          // that contains the 'registration_id'.
                          final registrationId = customer['registration_id'];

                          Get.to(
                            () => UploadInstallationScreen(),
                            arguments: {'customerId': registrationId},
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              Theme.of(
                                context,
                              ).primaryColor, // Or any color you prefer
                          elevation: 4.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Text(
                          'ADD SPLITTER INFO',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Installation Details...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final controller =
                    Get.find<WireInstallationDetailsController>();
                if (controller.customerId != null) {
                  controller.fetchDetails(controller.customerId!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(Map<String, dynamic> customer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Customer Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white.withOpacity(0.8),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          // Customer Name
          Text(
            customer['full_name']?.toString().trim().isNotEmpty == true
                ? customer['full_name']
                : 'Customer',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Customer ID
          Text(
            'ID: ${customer['registration_id'] ?? 'N/A'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Wire Installation Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVerified ? Colors.green[100]! : Colors.red[100]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.check_circle : Icons.cancel,
                        color: isVerified ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Verified' : 'Not Verified',
                        style: TextStyle(
                          color: isVerified ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWireInstallationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cable, color: Colors.orange[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'No Wire Installation Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Technician task is pending. Wire installation details will appear here once completed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
