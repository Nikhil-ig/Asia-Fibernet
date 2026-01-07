import 'package:get/get.dart';

import '../../../../customer/ui/screen/pages/home_page.dart';
import '../../../../customer/ui/screen/pages/referral_screen.dart';
import '../../../../customer/customer_complaint_controller.dart';
import '../../../ui/scaffold_screen.dart';

/// Binding class to manage dependencies for the LoginScreen.
class ScaffoldScreenBinding implements Bindings {
  @override
  void dependencies() {
    // Use Get.lazyPut for lazy initialization (controller created when first needed)
    Get.lazyPut<ScaffoldController>(() => ScaffoldController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ComplaintController>(() => ComplaintController());
    Get.lazyPut<ReferralController>(() => ReferralController());
    // Get.lazyPut<ApiServices>(() => ApiServices());
  }
}
