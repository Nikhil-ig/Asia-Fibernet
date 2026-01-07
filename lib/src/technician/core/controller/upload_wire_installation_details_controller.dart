import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/apis/technician_api_service.dart';

class UploadInstallationController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  // Dropdown data
  var oltIps = <String>[].obs;
  var oltTypes = <String>[].obs;
  var oltVendors = <String>[].obs;
  var ponNumbers = <String>[].obs;
  var ponOdb = <String>[].obs;
  var splitterNumbers = <int>[].obs;
  var odbPorts = <int>[].obs;
  var cableTypes = <String>[].obs;
  var customerEndBoxes = <int>[].obs;
  var patchCards = <String>[].obs;
  var noOfPatchCards = <int>[].obs;

  // Selected values
  var selectedOltIp = RxString('');
  var selectedOltType = RxString('');
  var selectedOltVendor = RxString('');
  var selectedPonNumber = RxString('');
  var selectedPonOdb = RxString('');
  var selectedSplitterNumber = RxInt(0);
  var selectedOdbPort = RxInt(0);
  var selectedCableType = RxString('');
  var selectedCustomerEndBox = RxInt(0);
  var selectedPatchCard = RxString('');
  var selectedNoOfPatchCards = RxInt(0);

  // Text fields
  var cableMeter = ''.obs;
  var powerLevel = ''.obs;
  var latitude = ''.obs;
  var longitude = ''.obs;
  var currentAddress = ''.obs; // To store the fetched address
  var remark = ''.obs;

  // State
  var isLoading = false.obs;
  var isDropdownLoading = false.obs;
  var error = ''.obs;
  var isSubmitting = false.obs;

  int? customerId;

  @override
  void onInit() {
    super.onInit();
    customerId = Get.arguments?['customerId'];
    fetchDropdownData();
    getCurrentLocation();
  }

  Future<void> fetchDropdownData() async {
    try {
      isDropdownLoading.value = true;
      error.value = '';
      final result = await _api.fetchOltIpList();

      if (result != null && result['status'] == true) {
        // --- CORRECT PARSING LOGIC FOR THE NEW API STRUCTURE ---
        // Safely parse the lists from the response map
        oltIps.assignAll(
          (result['olt_ips'] as List? ?? []).map((e) => e.toString()).toList(),
        );
        oltTypes.assignAll(
          (result['olt_types'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
        oltVendors.assignAll(
          (result['olt_vendors'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
        ponNumbers.assignAll(
          (result['pon_numbers'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
        ponOdb.assignAll(
          (result['pon_odb'] as List? ?? []).map((e) => e.toString()).toList(),
        );
        cableTypes.assignAll(
          (result['cable_types'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );
        patchCards.assignAll(
          (result['patch_cards'] as List? ?? [])
              .map((e) => e.toString())
              .toList(),
        );

        // Safely parse integer lists
        splitterNumbers.assignAll(
          (result['splitter_numbers'] as List? ?? []).whereType<int>().toList(),
        );
        odbPorts.assignAll(
          (result['odb_ports'] as List? ?? []).whereType<int>().toList(),
        );
        customerEndBoxes.assignAll(
          (result['customer_end_boxes'] as List? ?? [])
              .whereType<int>()
              .toList(),
        );
        noOfPatchCards.assignAll(
          (result['no_of_patch_cards'] as List? ?? [])
              .whereType<int>()
              .toList(),
        );

        // Set default values if the lists are not empty
        if (oltIps.isNotEmpty) selectedOltIp.value = oltIps.first;
        if (oltTypes.isNotEmpty) selectedOltType.value = oltTypes.first;
        if (oltVendors.isNotEmpty) selectedOltVendor.value = oltVendors.first;
        if (ponNumbers.isNotEmpty) selectedPonNumber.value = ponNumbers.first;
        if (ponOdb.isNotEmpty) selectedPonOdb.value = ponOdb.first;
        if (splitterNumbers.isNotEmpty)
          selectedSplitterNumber.value = splitterNumbers.first;
        if (odbPorts.isNotEmpty) selectedOdbPort.value = odbPorts.first;
        if (cableTypes.isNotEmpty) selectedCableType.value = cableTypes.first;
        if (customerEndBoxes.isNotEmpty)
          selectedCustomerEndBox.value = customerEndBoxes.first;
        if (patchCards.isNotEmpty) selectedPatchCard.value = patchCards.first;
        if (noOfPatchCards.isNotEmpty)
          selectedNoOfPatchCards.value = noOfPatchCards.first;
      } else {
        error.value =
            result?['message']?.toString() ?? 'Failed to load dropdown data.';
      }
    } catch (e, s) {
      error.value = 'An error occurred while loading data.';
      // Log the error and stack trace for detailed debugging
      print("UploadInstallationController Error: $e");
      print("Stack Trace: $s");
    } finally {
      isDropdownLoading.value = false;
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        error.value = 'Location services are disabled. Please enable them.';
        BaseApiService().showSnackbar(
          'Location Error',
          'Location services are disabled.',
          isError: true,
        );
        return;
      }

      // 2. Check for permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // 3. Request permissions if denied
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          error.value = 'Location permissions are denied.';
          _api.showSnackbar(
            'Location Error',
            'Permission denied. Please grant location access.',
          );
          return;
        }
      }

      // 4. Handle permanently denied permissions
      if (permission == LocationPermission.deniedForever) {
        error.value = 'Location permissions are permanently denied.';
        BaseApiService().showSnackbar(
          'Permissions Required',
          'Location access is permanently denied. Please enable it in app settings.',
          mainButton: TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('OPEN SETTINGS'),
          ),
        );
        return;
      }

      // 5. If permissions are granted, get the location and address
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      latitude.value = position.latitude.toStringAsFixed(6);
      longitude.value = position.longitude.toStringAsFixed(6);

      // Fetch the address from coordinates
      await _getAddressFromLatLng(position);
    } catch (e) {
      print("Location error: $e");
      error.value = 'Failed to get location.';
      // Set to a default or last known location if necessary
      latitude.value = '0.0';
      longitude.value = '0.0';
    }
  }

  // Helper method to get address from coordinates
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAddress.value =
            "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      } else {
        currentAddress.value = "Address not found";
      }
    } catch (e) {
      print("Address error: $e");
      currentAddress.value = "Could not fetch address";
    }
  }

  Future<void> submitInstallationDetails() async {
    try {
      isSubmitting.value = true;
      error.value = '';

      // Validate required fields
      if (cableMeter.value.isEmpty || powerLevel.value.isEmpty) {
        error.value = 'Please fill all required fields';
        return;
      }

      final data = {
        'customer_id': customerId,
        'olt_ip': selectedOltIp.value,
        'olt_type': selectedOltType.value,
        'olt_vendor': selectedOltVendor.value,
        'pon_number': selectedPonNumber.value,
        'pon_odb': selectedPonOdb.value,
        'splitter_number': selectedSplitterNumber.value,
        'odb_port': selectedOdbPort.value,
        'cable_type': selectedCableType.value,
        'customer_end_box': selectedCustomerEndBox.value,
        'patch_card': selectedPatchCard.value,
        'no_of_patch_cards': selectedNoOfPatchCards.value,
        'cable_meter': cableMeter.value,
        'power_level': powerLevel.value,
        'lat': latitude.value,
        'long': longitude.value,
        'remark': remark.value,
      };

      final result = await _api.updateWireInstallation(data);

      if (result) {
        Get.back(result: true);
        BaseApiService().showSnackbar(
          'Success',
          'Installation details submitted successfully!',
        );
      } else {
        error.value = 'Failed to submit details.';
      }
    } catch (e) {
      error.value = 'An error occurred while submitting data.';
      print("Submit Installation Error: $e");
    } finally {
      isSubmitting.value = false;
    }
  }

  void updateCableMeter(String value) => cableMeter.value = value;
  void updatePowerLevel(String value) => powerLevel.value = value;
  void updateRemark(String value) => remark.value = value;
}
