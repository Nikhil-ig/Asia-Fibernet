import 'package:get/get.dart';
import '../../../services/apis/technician_api_service.dart';

class WireInstallationDetailsController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  var customerDetails = <String, dynamic>{}.obs; // will hold full response data
  var isLoading = false.obs;
  var error = ''.obs;

  int? customerId;

  @override
  void onInit() {
    super.onInit();
    customerId = Get.arguments?['customerId'];
    if (customerId != null) {
      fetchDetails(customerId!);
    }
  }

  Future<void> fetchDetails(int id) async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _api.fetchWireInstallationCustomersDetails(id);
      if (result != null && result['status'] == true) {
        customerDetails.assignAll(result); // assign full JSON response
      } else {
        error.value = 'Failed to fetch details.';
      }
    } catch (e) {
      error.value = 'An error occurred while loading data.';
      print("WireInstallationDetailsController Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
