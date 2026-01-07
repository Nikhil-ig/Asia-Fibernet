import 'package:get/get.dart';
import '../../../services/apis/technician_api_service.dart';

class WireInstallationCustomersController extends GetxController {
  final TechnicianAPI _api = TechnicianAPI();

  var customers = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWireInstallationCustomers();
  }

  Future<void> fetchWireInstallationCustomers() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _api.fetchWireInstallationCustomers();
      if (result != null) {
        customers.assignAll(result);
      } else {
        error.value = 'No wire installation customers found.';
      }
    } catch (e) {
      error.value = 'Failed to load customers. Please try again.';
      print("WireInstallationCustomersController Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
