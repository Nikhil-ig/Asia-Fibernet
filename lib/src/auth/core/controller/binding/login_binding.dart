import 'package:get/get.dart';

import '../../../../services/apis/api_services.dart';
import '../login_controller.dart';

/// Binding class to manage dependencies for the LoginScreen.
class LoginBinding implements Bindings {
  @override
  void dependencies() {
    // Use Get.lazyPut with permanent: true to prevent disposal on route change
    // This prevents "TextEditingController used after dispose" errors
    Get.lazyPut<LoginController>(
      () => LoginController(),
      fenix: true, // Recreates the controller if it was deleted
    );
    Get.lazyPut<ApiServices>(() => ApiServices());
  }
}
