# Background Location Tracking Setup Guide

## Step 1: Add Dependencies to pubspec.yaml

```yaml
dependencies:
  # Existing dependencies...
  
  # Background Service
  flutter_background_service: ^5.0.0
  flutter_background_service_android: ^5.0.0
  flutter_background_service_ios: ^5.0.0
  
  # Location
  geolocator: ^9.0.0
  
  # Other
  intl: ^0.18.0
  get: ^4.6.0
```

## Step 2: Android Configuration

### Update `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Increase to 21 for background services
        targetSdkVersion 34
    }
}
```

### Update `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.your_app">

    <!-- Location Permissions -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Background Service Permissions -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application>
        <!-- ... existing application tags ... -->
        
        <!-- Foreground Service for Location -->
        <service
            android:name="com.flutter.flutter_background_service_android.BackgroundService"
            android:enabled="true"
            android:exported="true"
            android:foregroundServiceType="location" />
            
    </application>
</manifest>
```

## Step 3: iOS Configuration

### Update `ios/Runner/Info.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... existing keys ... -->
    
    <!-- Location Permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs access to your location to track work location</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs access to your location to track work location in background</string>
    
    <!-- Background Modes -->
    <key>UIBackgroundModes</key>
    <array>
        <string>location</string>
    </array>
</dict>
</plist>
```

## Step 4: Initialize in main.dart

```dart
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service FIRST
  await LocationTrackingBackgroundService().initializeBackgroundService();
  
  // ... rest of initialization ...
  
  runApp(const MyApp());
}
```

## Step 5: Start/Stop Tracking in Your Code

### Start Tracking

```dart
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

class TicketDetailsController extends GetxController {
  final _bgService = LocationTrackingBackgroundService();
  
  /// Start background tracking when accepting a ticket
  Future<void> acceptTicketAndStartTracking(String ticketDate) async {
    try {
      // Accept ticket...
      
      // Start background location tracking
      await _bgService.startBackgroundTracking(
        ticketDate: ticketDate,
        intervalSeconds: 60, // Track every 60 seconds
      );
      
      Get.snackbar(
        '✅ Success',
        'Location tracking started in background',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to start tracking: $e');
    }
  }
}
```

### Stop Tracking

```dart
/// Stop background tracking when completing ticket
Future<void> completeTicketAndStopTracking() async {
  try {
    // Mark ticket as complete...
    
    // Stop background tracking
    await _bgService.stopBackgroundTracking();
    
    Get.snackbar(
      '✅ Success',
      'Location tracking stopped',
    );
  } catch (e) {
    Get.snackbar('Error', 'Failed to stop tracking: $e');
  }
}
```

## Step 6: Check Tracking Status

```dart
/// Check if background tracking is active
Future<void> checkTrackingStatus() async {
  final isTracking = await _bgService.getTrackingStatus();
  
  if (isTracking) {
    print('📍 Background tracking is ACTIVE');
  } else {
    print('⏸️ Background tracking is INACTIVE');
  }
}
```

## Complete Usage Example

```dart
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

class TicketWorkController extends GetxController {
  final _bgService = LocationTrackingBackgroundService();
  
  var isTracking = false.obs;
  var currentTicketDate = ''.obs;
  
  /// Accept ticket and start background tracking
  Future<void> acceptTicket(String ticketNo, String ticketDate) async {
    try {
      // Call backend to accept ticket
      // await acceptTicketApi(ticketNo);
      
      currentTicketDate.value = ticketDate;
      
      // Start background location tracking
      // Track every 60 seconds
      await _bgService.startBackgroundTracking(
        ticketDate: ticketDate,
        intervalSeconds: 60,
      );
      
      isTracking.value = true;
      
      Get.snackbar(
        '✅ Tracking Started',
        'Your location will be tracked every minute',
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to start tracking: $e',
        backgroundColor: Colors.red,
      );
    }
  }
  
  /// Complete ticket and stop background tracking
  Future<void> completeTicket(String ticketNo) async {
    try {
      // Call backend to complete ticket
      // await completeTicketApi(ticketNo);
      
      // Stop background tracking
      await _bgService.stopBackgroundTracking();
      
      isTracking.value = false;
      currentTicketDate.value = '';
      
      Get.snackbar(
        '✅ Ticket Completed',
        'Location tracking stopped',
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        '❌ Error',
        'Failed to complete ticket: $e',
        backgroundColor: Colors.red,
      );
    }
  }
  
  /// Monitor tracking status
  Future<void> monitorTrackingStatus() async {
    while (true) {
      final isActive = await _bgService.getTrackingStatus();
      if (!isActive && isTracking.value) {
        // Tracking was stopped externally, update UI
        isTracking.value = false;
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }
  
  @override
  void onInit() {
    super.onInit();
    // Optional: Monitor tracking status
    // monitorTrackingStatus();
  }
  
  @override
  void onClose() {
    // Stop tracking when closing controller
    _bgService.stopBackgroundTracking();
    super.onClose();
  }
}
```

## UI Screen Example

```dart
class TicketWorkScreen extends StatelessWidget {
  final String ticketNo;
  final String ticketDate;
  final controller = Get.put(TicketWorkController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Working on Ticket: $ticketNo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Tracking Status
            Obx(() => Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.isTracking.value ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    controller.isTracking.value
                        ? 'Location Tracking Active'
                        : 'Tracking Inactive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            // Start/Stop Button
            Padding(
              padding: EdgeInsets.all(16),
              child: Obx(() => ElevatedButton(
                onPressed: controller.isTracking.value
                    ? () => controller.completeTicket(ticketNo)
                    : () => controller.acceptTicket(ticketNo, ticketDate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isTracking.value
                      ? Colors.red
                      : Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  controller.isTracking.value
                      ? '⏹️ Stop Tracking & Complete'
                      : '▶️ Start Tracking',
                  style: TextStyle(fontSize: 16),
                ),
              )),
            ),
            
            // Work details...
          ],
        ),
      ),
    );
  }
}
```

## Tracking Intervals

| Interval | Use Case | Battery Impact |
|----------|----------|----------------|
| 30 seconds | Active work, high priority | High |
| 60 seconds | Normal work tracking | Medium |
| 120 seconds | Low priority tracking | Low |
| 300 seconds (5 min) | Background monitoring only | Very Low |

**Recommendation:** Use 60-120 seconds for regular ticket work

## Troubleshooting

### Background Service Not Starting
- ✅ Ensure `initializeBackgroundService()` called in `main()`
- ✅ Check Android minSdkVersion is 21 or higher
- ✅ Verify all permissions are declared in AndroidManifest.xml
- ✅ Check for errors in device logs: `flutter logs`

### Location Not Being Tracked
- ✅ Verify location permissions are granted
- ✅ Check GPS is enabled on device
- ✅ Ensure network connectivity (API call requires internet)
- ✅ Check API token is valid

### Battery Drain
- ✅ Increase tracking interval to 120+ seconds
- ✅ Use `LocationAccuracy.low` for battery savings
- ✅ Only track during active work hours
- ✅ Stop tracking when app is backgrounded

### Service Keeps Stopping
- ✅ Ensure device battery optimization is not killing service
- ✅ Check `Settings > Battery > Battery Optimization > Exclude Your App`
- ✅ Verify foreground service is properly configured

## Testing Checklist

- [ ] Android: Verify background tracking works after force-closing app
- [ ] iOS: Test with app in background (Home button)
- [ ] Test location permission prompts
- [ ] Verify API calls are made while app is closed
- [ ] Check notification updates in real-time
- [ ] Test stop tracking functionality
- [ ] Verify battery usage is acceptable
- [ ] Test on different Android/iOS versions

## Important Notes

1. **Location accuracy:** Background tracking uses `LocationAccuracy.high` with fallback to `low`
2. **API calls:** Ensure your backend API works properly with Bearer token authentication
3. **Notification:** Foreground service will show notification while tracking
4. **Permissions:** Always request permissions before starting background service
5. **Stop service:** Always stop tracking when ticket is completed

---

**Last Updated:** January 5, 2026
**Status:** Production Ready ✅
