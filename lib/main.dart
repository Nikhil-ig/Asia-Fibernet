// main.dart
import 'package:asia_fibernet/src/services/apis/base_api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ Fixed import paths (no spaces)
import 'src/auth/core/controller/binding/login_binding.dart';
import 'src/services/apis/api_services.dart';
import 'src/services/routes.dart';
import 'src/services/sharedpref.dart';
import 'src/services/background_services/app_lifecycle_manager.dart';
import 'src/theme/colors.dart';

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

void main() async {
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
  });

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions at runtime
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  // --- START: MORE ROBUST TOKEN RETRIEVAL ---
  if (kDebugMode) {
    try {
      // For iOS, explicitly get the APNS token first.
      // This will return null on simulators, which is expected.
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null && defaultTargetPlatform == TargetPlatform.iOS) {
        print('=======================================');
        print('!!! WARNING: Running on iOS Simulator !!!');
        print(
          'Push notifications will not work. Please use a physical device.',
        );
        print('=======================================');
      } else {
        // Now get the FCM token.
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print('=======================================');
        print('!!! COPY THIS FCM TOKEN FOR TESTING !!!');
        print('FCM Token: $fcmToken');
        AppSharedPref.instance.setfcmToken(fcmToken!);
        print('=======================================');
      }
    } catch (e) {
      print('=======================================');
      print('!!! FAILED TO GET FCM TOKEN !!!');
      print('Error: $e');
      print(
        'Ensure you are on a physical iOS device and have completed the native setup.',
      );
      print('=======================================');
    }
  }
  // --- END: MORE ROBUST TOKEN RETRIEVAL ---

  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Set presentation options for iOS
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Create the Android Notification Channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Listen for foreground messages and display them using local notifications (for Android)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  tz.initializeTimeZones();
  await ScreenUtil.ensureScreenSize();
  await AppSharedPref.init();
  Get.put(BaseApiService());
  Get.put(ApiServices());

  // ✅ Initialize App Lifecycle Manager for background location tracking
  AppLifecycleManager().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppSharedPref.instance.clearAllUserData();
    Get.put(ApiServices());
    return ScreenUtilInit(
      designSize: MediaQuery.sizeOf(
        context,
      ), //const Size(375, 812), // iPhone 13 mini as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return SafeArea(
          top: false,
          child: GetMaterialApp(
            title: 'Asia Fibernet',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primary,
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.light().textTheme,
              ),
              scaffoldBackgroundColor: AppColors.backgroundLight,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.cardBackground,
                elevation: 0,
                iconTheme: IconThemeData(color: AppColors.primary),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            initialBinding:
                LoginBinding(), // Will be used when navigating to login
            initialRoute: '/splash',
            getPages: AppRoutes.getPages, // Use the new routes file
            // Middleware is applied to individual GetPage routes, not globally
          ),
        );
      },
    );
  }
}
