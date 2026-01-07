import 'package:get/get.dart';

import '../../../../services/apis/api_services.dart';
import '../login_controller.dart';

/// Binding class to manage dependencies for the LoginScreen.
class LoginBinding implements Bindings {
  @override
  void dependencies() {
    // Use Get.lazyPut for lazy initialization (controller created when first needed)
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<ApiServices>(() => ApiServices());
  }
}
