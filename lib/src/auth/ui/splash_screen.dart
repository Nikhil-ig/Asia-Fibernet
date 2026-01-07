// asia_fibernet_fixes/splash_screen.dart
import 'package:asia_fibernet/src/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/sharedpref.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _checkLoginState();
  }

  void _checkLoginState() async {
    await Future.delayed(Duration(seconds: 2));

    final token = await AppSharedPref.instance.getToken();
    final isLoggedIn = token != null && token.isNotEmpty;
    final phoneNo = AppSharedPref.instance.getMobileNumber();
    final role = AppSharedPref.instance.getRole();
    final isVerified = AppSharedPref.instance.getVerificationStatus();

    print("token: $token, role: $role, phone: $phoneNo");

    if (isLoggedIn) {
      switch (role) {
        case "customer":
          if (isVerified) {
            Get.offAllNamed(AppRoutes.home);
          } else {
            Get.offAllNamed(AppRoutes.unregisteredUser);
          }
          break;
        case "technician":
          Get.offAllNamed(AppRoutes.technicianDashboard);
          break;
        case "admin":
          Get.offAllNamed('/admin'); // TODO: Implement admin screen
          break;
        default:
          Get.offAllNamed(AppRoutes.login);
      }
    } else {
      // Not logged in
      if (role == "Guest" && phoneNo != null && phoneNo.isNotEmpty) {
        Get.offAllNamed(AppRoutes.unregisteredUser);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1976D2),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi, size: 100, color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Asia Fibernet",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "High-Speed Internet",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
