// import 'dart:isolate';
// import 'dart:ui';
// import 'dart:developer' as developer;
// import 'package:background_locator_2/background_locator.dart';
// import 'package:background_locator_2/location_dto.dart';
// import 'package:background_locator_2/settings/android_settings.dart';
// import 'package:background_locator_2/settings/ios_settings.dart';
// import 'package:background_locator_2/settings/locator_settings.dart';
// import 'package:geolocator/geolocator.dart' show AndroidResource;
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:intl/intl.dart';

// import 'apis/api_services.dart';
// import '/src/core/services/sharedpref.dart';

// class BackgroundLocationService {
//   static bool _isRunning = false;
//   static const String _isolateName = "LocatorIsolate";

//   static Future<void> initialize() async {
//     await BackgroundLocator.initialize();
//   }

//   static Future<void> startTracking() async {
//     await _requestPermissions();

//     if (_isRunning) return;

//     try {
//       ReceivePort port = ReceivePort();
//       IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);

//       port.listen((dynamic data) {
//         if (data is LocationDto) {
//           _handleLocationUpdate(data);
//         }
//       });

//       await BackgroundLocator.registerLocationUpdate(
//         locationCallback,
//         // initCallback: initCallback,
//         disposeCallback: disposeCallback,
//         iosSettings: IOSSettings(
//           accuracy: LocationAccuracy.NAVIGATION,
//           distanceFilter: 0,
//         ),
//         autoStop: false,
//         androidSettings: AndroidSettings(
//           accuracy: LocationAccuracy.HIGH,
//           interval: 15000,
//           distanceFilter: 10,
//           androidNotificationSettings: AndroidNotificationSettings(
//             notificationChannelName: 'Employee Tracker',
//             notificationTitle: 'Tracking active',
//             notificationMsg: 'Location service is running',
//             // notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
//             notificationTapCallback: notificationCallback,
//           ),
//         ),
//       );

//       _isRunning = true;
//       await AppSharedPref.setTrackingStatus(true);

//       developer.log('BackgroundLocationService: Tracking started');
//     } catch (e) {
//       developer.log('BackgroundLocationService: Error starting: $e');
//     }
//   }

//   static Future<void> stopTracking() async {
//     await BackgroundLocator.unRegisterLocationUpdate();
//     IsolateNameServer.removePortNameMapping(_isolateName);

//     _isRunning = false;
//     await AppSharedPref.setTrackingStatus(false);

//     developer.log('BackgroundLocationService: Tracking stopped');
//   }

//   static Future<void> _requestPermissions() async {
//     var status = await Permission.locationAlways.status;
//     if (status.isDenied) {
//       await Permission.locationAlways.request();
//     }
//   }

//   static Future<void> _handleLocationUpdate(LocationDto location) async {
//     try {
//       final employeeId = await AppSharedPref.getToken();
//       if (employeeId == null || employeeId.isEmpty) return;

//       final now = DateTime.now();
//       final currentDate = DateFormat('yyyy-MM-dd').format(now);
//       final currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
//       final currentTime = DateFormat('HH:mm').format(now);

//       final apiServices = Get.find<TechnicianAPI>();

//       final success = await apiServices.trackLocation(
//         technicianId: employeeId,
//         date: currentDate,
//         sessionDatetime: currentDateTime,
//         locationName: currentTime,
//         lat: location.latitude.toString(),
//         lng: location.longitude.toString(),
//       );

//       developer.log(
//         success
//             ? 'BackgroundLocationService: Location sent'
//             : 'BackgroundLocationService: Failed to send',
//       );
//     } catch (e) {
//       developer.log('BackgroundLocationService: Error sending location: $e');
//     }
//   }
// }

// /// REQUIRED CALLBACKS (must be top-level)

// @pragma('vm:entry-point')
// void locationCallback(LocationDto locationDto) {
//   final SendPort? send = IsolateNameServer.lookupPortByName(
//     BackgroundLocationService._isolateName,
//   );
//   send?.send(locationDto);
// }

// @pragma('vm:entry-point')
// void initCallback() {
//   developer.log('BackgroundLocationService: Init');
// }

// @pragma('vm:entry-point')
// void disposeCallback() {
//   developer.log('BackgroundLocationService: Dispose');
// }

// @pragma('vm:entry-point')
// void notificationCallback() {
//   developer.log('BackgroundLocationService: Notification clicked');
// }
