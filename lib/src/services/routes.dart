import 'package:get/get.dart';

// Auth screens
import '../auth/core/controller/signup_controller.dart';
import '../auth/ui/greeting_screen.dart';
import '../auth/ui/splash_screen.dart';
import '../auth/ui/login_screen.dart';
import '../auth/ui/otp_screen.dart';
import '../auth/ui/signup_screen.dart';
import '../auth/ui/scaffold_screen.dart';
import '../auth/core/controller/binding/login_binding.dart';
import '../auth/core/controller/binding/scaffold_screen_binding.dart';

// Customer screens
import '../customer/unregistered_user/unregistered_user_screen.dart';
import '../customer/ui/screen/pages/home_page.dart';
import '../customer/ui/screen/pages/complaints_page.dart';
import '../customer/ui/screen/pages/referral_screen.dart';
import '../customer/ui/screen/profile_screen.dart';
import '../customer/unregistered_user/kyc_under_review_screen.dart';
import '../customer/ui/screen/bsnl_screen.dart';

// Technician screens
import '../customer/unregistered_user/unregistered_kyc_status_screen.dart';
import '../technician/ui/screens/tech_dashboard_screen.dart';
import '../technician/ui/screens/technician_profile_screen.dart';
import '../technician/ui/screens/all_tickets_screen.dart';
import '../technician/ui/screens/expense_screen.dart';
import '../technician/ui/screens/notifications_screen.dart';
import '../technician/ui/screens/tech_all_customers_screen.dart';
import '../technician/ui/screens/customer_detail_screen.dart';
import '../technician/attendance/attendance_screen.dart';
import '../technician/ui/screens/wire_installation/modem_installation_screen.dart';
import '../technician/ui/screens/wire_installation/wire_installation_customers_screen.dart';
import '../technician/ui/screens/wire_installation_screen.dart';
import '../notification_settings/notification_settings_view.dart';
import '../notification_settings/controller/binding/notification_settings_binding.dart';

class AppRoutes {
  // Define route names as constants
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String greeting = '/greeting';

  // Customer routes
  static const String unregisteredUser = '/unregistered-user';
  static const String customerHome = '/customer-home';
  static const String complaints = '/complaints';
  static const String referral = '/referral';
  static const String profile = '/profile';
  static const String kycReview = '/kyc-review';
  static const String finalKYCReview = '/final-kyc-review';
  static const String bsnlPlans = '/bsnl-plans';

  // Technician routes
  static const String technicianDashboard = '/technician-dashboard';
  static const String technicianProfile = '/technician-profile';
  static const String allTickets = '/all-tickets';
  static const String expenses = '/expenses';
  static const String notifications = '/notifications';
  static const String allCustomers = '/all-customers';
  static const String customerDetails = '/customer-details';
  static const String attendance = '/attendance';
  static const String wireInstallation = '/wireInstallation';
  static const String modemInstallation = '/modemInstallation';
  static const String notificationSettings = '/notification-settings';

  // Define routes map for GetX navigation
  static List<GetPage> getPages = [
    // Auth routes
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: login, page: () => LoginScreen(), binding: LoginBinding()),
    GetPage(name: otp, page: () => OTPScreen()),
    GetPage(
      name: signup,
      page: () => SignUpScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SignUpController>(() => SignUpController());
      }),
    ),
    GetPage(
      name: home,
      page: () => ScaffoldScreen(),
      binding: ScaffoldScreenBinding(),
    ),
    GetPage(name: greeting, page: () => GreetingScreen()),

    // Customer routes
    GetPage(
      name: unregisteredUser,
      page: () => UnregisteredUserScreen(),
      binding: ScaffoldScreenBinding(),
    ),
    GetPage(name: customerHome, page: () => HomeScreenContent()),
    GetPage(name: complaints, page: () => ComplaintsScreen()),
    GetPage(
      name: referral,
      page: () => ReferralScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReferralController());
      }),
    ),
    GetPage(name: profile, page: () => ProfileScreen()),
    GetPage(name: kycReview, page: () => KycUnderReviewScreen()),
    GetPage(name: finalKYCReview, page: () => FinalKycStatusScreen()),
    GetPage(name: bsnlPlans, page: () => PremiumBsnlPlansScreen()),

    // Technician routes
    GetPage(name: technicianDashboard, page: () => TechnicianDashboardScreen()),
    GetPage(name: technicianProfile, page: () => TechnicianProfileScreen()),
    GetPage(name: allTickets, page: () => AllTicketsScreen()),
    GetPage(name: expenses, page: () => ExpenseScreen()),
    GetPage(name: notifications, page: () => NotificationScreen()),
    GetPage(name: allCustomers, page: () => AllCustomersScreen()),
    GetPage(name: customerDetails, page: () => CustomerDetailsScreen()),
    GetPage(name: attendance, page: () => AttendanceScreen()),
    GetPage(
      name: wireInstallation,
      // page: () => WireInstallationSubmissionScreen(),
      page: () => WireInstallationCustomersScreen(),
    ),
    GetPage(
      name: modemInstallation,
      // page: () => WireInstallationSubmissionScreen(),
      page: () => ModemInstallationScreen(),
    ),
    GetPage(
      name: notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: NotificationSettingsBinding(),
    ),
  ];

  // Helper method for navigation
  static void navigateTo(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
    bool preventDuplicates = true,
  }) {
    Get.toNamed(
      routeName,
      arguments: arguments,
      parameters: parameters,
      preventDuplicates: preventDuplicates,
    );
  }

  // Helper method for replacing current route
  static void replaceWith(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    Get.offNamed(routeName, arguments: arguments, parameters: parameters);
  }

  // Helper method for replacing all routes
  static void replaceAllWith(
    String routeName, {
    dynamic arguments,
    Map<String, String>? parameters,
  }) {
    Get.offAllNamed(routeName, arguments: arguments, parameters: parameters);
  }
}
