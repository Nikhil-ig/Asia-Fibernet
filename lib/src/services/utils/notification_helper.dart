import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as developer;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  /// Initialize both local and Firebase notifications
  static Future<void> initialize() async {
    // ✅ Initialize Local Notifications
    await _initializeLocalNotifications();

    // ✅ Initialize Firebase Messaging
    await _initializeFirebaseMessaging();
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    // ✅ Initialize with @mipmap/ic_launcher which is the Flutter default app icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        developer.log('Local notification clicked: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    // ✅ Create notification channel for Android 8.0+ with custom sound
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'complaint_channel',
            'Complaint Updates',
            description: 'Notifications for complaint status changes',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            // ✅ Use custom notification sound from android/app/src/main/res/raw/notification_sound.mp3
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          ),
        );

    developer.log('Local notifications initialized');
  }

  /// Initialize Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    try {
      // ✅ Set foreground notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // ✅ Request user notification permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('Firebase Messaging: User granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('Firebase Messaging: Provisional permission granted');
      } else {
        developer.log('Firebase Messaging: Permission denied');
      }

      // ✅ Get FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $fcmToken');

      // ✅ Handle foreground notifications (when app is open)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log(
          'FCM Message received in foreground: ${message.notification?.title}',
        );
        _handleFCMMessage(message);
      });

      // ✅ Handle background notifications (when user taps notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('FCM Message opened app: ${message.notification?.title}');
        _handleNotificationTap(message.data.toString());
      });

      // ✅ Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((fcmToken) {
        developer.log('FCM Token refreshed: $fcmToken');
        // TODO: Send new token to your backend
      });

      developer.log('Firebase Messaging initialized');
    } catch (e) {
      developer.log('Error initializing Firebase Messaging: $e');
    }
  }

  /// Handle FCM message when app is in foreground
  static Future<void> _handleFCMMessage(RemoteMessage message) async {
    developer.log('Handling FCM message: ${message.notification?.title}');

    // Show local notification for FCM message with custom sound
    if (message.notification != null) {
      await showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(String? payload) {
    developer.log('Notification tapped with payload: $payload');
    // TODO: Navigate to relevant screen based on notification type
    // Example: if (payload.contains('complaint')) { Get.to(...) }
  }

  /// Show local notification with custom sound
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // ✅ Android notification details with custom sound file (notification_sound.mp3)
      const AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
        'complaint_channel',
        'Complaint Updates',
        channelDescription: 'Notifications for complaint status changes',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        // ✅ Use @mipmap/ic_launcher which is the Flutter default app icon
        icon: '@mipmap/ic_launcher',
        // ✅ Custom notification sound from android/app/src/main/res/raw/notification_sound.mp3
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      // ✅ iOS notification details with custom sound
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // ✅ For iOS, add notification_sound.aiff to ios/Runner folder in Xcode
        sound: 'notification_sound.aiff',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );

      developer.log('Local notification shown: $title');
    } catch (e) {
      developer.log('Error showing notification: $e');
    }
  }

  /// Schedule local notification with custom sound
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required Duration duration,
    String? payload,
  }) async {
    try {
      tz.initializeTimeZones();
      final tz.TZDateTime scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(duration);

      // ✅ Android notification details with custom sound
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'complaint_channel',
            'Complaint Updates',
            channelDescription: 'Notifications for complaint status changes',
            // ✅ Use @mipmap/ic_launcher which is the Flutter default app icon
            icon: '@mipmap/ic_launcher',
            sound: RawResourceAndroidNotificationSound('notification_sound'),
            playSound: true,
            enableVibration: true,
            enableLights: true,
          );

      // ✅ iOS notification details with custom sound
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification_sound.aiff',
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exact,
        payload: payload,
      );

      developer.log('Notification scheduled for: $scheduledTime');
    } catch (e) {
      developer.log('Error scheduling notification: $e');
    }
  }

  /// Get FCM Token
  static Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      developer.log('FCM Token retrieved: $token');
      return token;
    } catch (e) {
      developer.log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic for bulk messaging
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic');
    } catch (e) {
      developer.log('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic');
    } catch (e) {
      developer.log('Error unsubscribing from topic: $e');
    }
  }
}
