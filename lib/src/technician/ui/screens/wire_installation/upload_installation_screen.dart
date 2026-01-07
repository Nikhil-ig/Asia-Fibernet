import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/colors.dart';
import '../../../core/controller/upload_wire_installation_details_controller.dart';

class UploadInstallationScreen extends StatelessWidget {
  const UploadInstallationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<UploadInstallationController>(
      init: UploadInstallationController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Upload Installation Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            centerTitle: true,
            actions: [
              if (controller.isSubmitting.value)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          body: Obx(() {
            return _buildBody(controller);
          }),
        );
      },
    );
  }

  Widget _buildBody(UploadInstallationController controller) {
    if (controller.isDropdownLoading.value) {
      return _buildLoadingState();
    }

    if (controller.error.value.isNotEmpty && controller.oltIps.isEmpty) {
      return _buildErrorState(controller);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 20),

          // OLT Configuration Card
          _buildOLTConfigurationCard(controller),
          const SizedBox(height: 16),

          // PON & Splitter Card
          _buildPONSplitterCard(controller),
          const SizedBox(height: 16),

          // Cable & Patch Card
          _buildCablePatchCard(controller),
          const SizedBox(height: 16),

          // Location & Remarks Card
          _buildLocationRemarksCard(controller),
          const SizedBox(height: 24),

          // Submit Button
          _buildSubmitButton(controller),
          const SizedBox(height: 20),
        ],
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
            'Loading Installation Data...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(UploadInstallationController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.error.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.fetchDropdownData,
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

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installation Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill all the technical details for installation',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOLTConfigurationCard(UploadInstallationController controller) {
    return _buildSectionCard(
      title: 'OLT Configuration',
      icon: Icons.settings_input_component,
      color: Colors.blue,
      children: [
        _buildDropdownField(
          label: 'OLT IP Address *',
          value: controller.selectedOltIp.value,
          items: controller.oltIps,
          onChanged: (value) => controller.selectedOltIp.value = value!,
        ),
        _buildDropdownField(
          label: 'OLT Type *',
          value: controller.selectedOltType.value,
          items: controller.oltTypes,
          onChanged: (value) => controller.selectedOltType.value = value!,
        ),
        _buildDropdownField(
          label: 'OLT Vendor *',
          value: controller.selectedOltVendor.value,
          items: controller.oltVendors,
          onChanged: (value) => controller.selectedOltVendor.value = value!,
        ),
      ],
    );
  }

  Widget _buildPONSplitterCard(UploadInstallationController controller) {
    return _buildSectionCard(
      title: 'PON & Splitter',
      icon: Icons.account_tree,
      color: Colors.green,
      children: [
        _buildDropdownField(
          label: 'PON Number *',
          value: controller.selectedPonNumber.value,
          items: controller.ponNumbers,
          onChanged: (value) => controller.selectedPonNumber.value = value!,
        ),
        _buildDropdownField(
          label: 'PON ODB *',
          value: controller.selectedPonOdb.value,
          items: controller.ponOdb,
          onChanged: (value) => controller.selectedPonOdb.value = value!,
        ),
        _buildDropdownField(
          label: 'Splitter Number *',
          value: controller.selectedSplitterNumber.value.toString(),
          items: controller.splitterNumbers.map((e) => e.toString()).toList(),
          onChanged:
              (value) =>
                  controller.selectedSplitterNumber.value = int.parse(value!),
        ),
        _buildDropdownField(
          label: 'ODB Port *',
          value: controller.selectedOdbPort.value.toString(),
          items: controller.odbPorts.map((e) => e.toString()).toList(),
          onChanged:
              (value) => controller.selectedOdbPort.value = int.parse(value!),
        ),
      ],
    );
  }

  Widget _buildCablePatchCard(UploadInstallationController controller) {
    return _buildSectionCard(
      title: 'Cable & Patch Details',
      icon: Icons.cable,
      color: Colors.orange,
      children: [
        _buildDropdownField(
          label: 'Cable Type *',
          value: controller.selectedCableType.value,
          items: controller.cableTypes,
          onChanged: (value) => controller.selectedCableType.value = value!,
        ),
        _buildDropdownField(
          label: 'Customer End Box *',
          value: controller.selectedCustomerEndBox.value.toString(),
          items: controller.customerEndBoxes.map((e) => e.toString()).toList(),
          onChanged:
              (value) =>
                  controller.selectedCustomerEndBox.value = int.parse(value!),
        ),
        _buildDropdownField(
          label: 'Patch Card *',
          value: controller.selectedPatchCard.value,
          items: controller.patchCards,
          onChanged: (value) => controller.selectedPatchCard.value = value!,
        ),
        _buildDropdownField(
          label: 'No. of Patch Cards *',
          value: controller.selectedNoOfPatchCards.value.toString(),
          items: controller.noOfPatchCards.map((e) => e.toString()).toList(),
          onChanged:
              (value) =>
                  controller.selectedNoOfPatchCards.value = int.parse(value!),
        ),
        _buildTextField(
          label: 'Cable Meter *',
          hintText: 'Enter cable length in meters',
          controller: TextEditingController(text: controller.cableMeter.value),
          onChanged: controller.updateCableMeter,
          keyboardType: TextInputType.number,
        ),
        _buildTextField(
          label: 'Power Level *',
          hintText: 'Enter power level',
          controller: TextEditingController(text: controller.powerLevel.value),
          onChanged: controller.updatePowerLevel,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildLocationRemarksCard(UploadInstallationController controller) {
    return _buildSectionCard(
      title: 'Location & Remarks',
      icon: Icons.location_on,
      color: Colors.purple,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Latitude',
                hintText: 'Latitude',
                controller: TextEditingController(
                  text: controller.latitude.value,
                ),
                onChanged: (value) => controller.latitude.value = value,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Longitude',
                hintText: 'Longitude',
                controller: TextEditingController(
                  text: controller.longitude.value,
                ),
                onChanged: (value) => controller.longitude.value = value,
                readOnly: true,
              ),
            ),
          ],
        ),

        // const SizedBox(height: 4),
        Obx(() {
          // Show a loading indicator while the address is being fetched
          if (controller.currentAddress.value.isEmpty &&
              controller.latitude.value.isNotEmpty) {
            return Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
                SizedBox(width: 8),
                Text("Fetching address..."),
              ],
            );
          }

          // Display the address once it's available
          return controller.currentAddress.value.isNotEmpty
              ? _buildTextField(
                label: "Current Address",
                controller: TextEditingController(
                  text: controller.currentAddress.value,
                ),
                hintText: controller.currentAddress.value,
                onChanged: (v) {},
                readOnly: true,
              )
              : const SizedBox.shrink(); // Hide if no address
        }),
        Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              'Location auto-detected',
              style: TextStyle(color: Colors.green[600], fontSize: 12),
            ),
            const Spacer(),
            TextButton(
              onPressed: controller.getCurrentLocation,
              child: Text(
                'Refresh Location',
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Remarks',
          hintText: 'Enter any additional remarks...',
          controller: TextEditingController(text: controller.remark.value),
          onChanged: controller.updateRemark,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
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
            // Section Header
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
                    fontSize: 16,
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items:
                      items.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: readOnly ? Colors.grey[100] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              maxLines: maxLines,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(UploadInstallationController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            controller.isSubmitting.value
                ? null
                : controller.submitInstallationDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            controller.isSubmitting.value
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  'Submit Installation Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
