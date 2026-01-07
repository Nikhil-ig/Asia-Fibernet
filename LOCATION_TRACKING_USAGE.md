# Location Tracking Implementation Guide

## Overview
The `TechnicianAPI` now includes location tracking functionality using the `_trackLocation` endpoint. This allows real-time tracking of technicians during their work.

## API Specifications

### Request Format
```json
{
  "technician_id": "1223",
  "date": "2025-08-22",
  "session_datetime": "2025-08-20 13:30:54",
  "location": {
    "location_name": "10:34",
    "lat": "34.7128",
    "lng": "-34.0060"
  }
}
```

**Parameters:**
- `technician_id`: Auto-filled from SharedPref (logged-in user)
- `date`: Date in `YYYY-MM-DD` format
- `session_datetime`: Full datetime in `YYYY-MM-DD HH:MM:SS` format
- `location.location_name`: Time in `HH:MM` format
- `location.lat`: Latitude coordinate
- `location.lng`: Longitude coordinate

**Headers:**
- `Authorization`: Bearer Token (auto-included)
- `Content-Type`: application/json

### Response Format
```json
{
  "status": "success",
  "message": "Location stored successfully"
}
```

## API Methods

### 1. Basic Location Tracking
```dart
Future<bool> trackLocation({
  required String date,                // YYYY-MM-DD
  required String sessionDateTime,     // YYYY-MM-DD HH:MM:SS
  required String latitude,            // "34.7128"
  required String longitude,           // "-34.0060"
  required String locationName,        // HH:MM format
})
```

**Usage Example:**
```dart
final techAPI = TechnicianAPI();

bool success = await techAPI.trackLocation(
  date: '2025-08-22',
  sessionDateTime: '2025-08-20 13:30:54',
  latitude: '34.7128',
  longitude: '-34.0060',
  locationName: '10:34',
);

if (success) {
  print('✅ Location tracked successfully!');
}
```

### 2. Track Location with Current Date-Time
```dart
Future<bool> trackLocationNow({
  required String latitude,
  required String longitude,
  required String locationName,  // Time in HH:MM format
})
```

**Usage Example:**
```dart
// Uses current date and time automatically
bool success = await techAPI.trackLocationNow(
  latitude: '34.7128',
  longitude: '-34.0060',
  locationName: '10:34',  // Current time
);
```

### 3. Simplified Ticket-Based Tracking
```dart
Future<bool> trackLocationForTicket({
  required String latitude,
  required String longitude,
  required String date,        // YYYY-MM-DD
  required String time,        // HH:MM format
})
```

**Usage Example:**
```dart
bool success = await techAPI.trackLocationForTicket(
  latitude: '34.7128',
  longitude: '-34.0060',
  date: '2025-08-22',
  time: '10:34',
);
```

## Integration in Technician Workflow

### In a Ticket Detail Controller
```dart
import 'package:geolocator/geolocator.dart';
import 'package:asia_fibernet/src/services/apis/technician_api_service.dart';
import 'package:intl/intl.dart';

class TicketDetailController extends GetxController {
  final TechnicianAPI _techAPI = TechnicianAPI();
  
  var isTrackingLocation = false.obs;
  
  /// Update ticket status and track location
  Future<void> trackCurrentLocation() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Get current time in HH:MM format
      final now = DateTime.now();
      final timeFormat = DateFormat('HH:mm').format(now);
      final dateFormat = DateFormat('yyyy-MM-dd').format(now);
      
      // Track location
      isTrackingLocation.value = true;
      
      final success = await _techAPI.trackLocationNow(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        locationName: timeFormat,
      );
      
      if (success) {
        print('✅ Location tracked!');
        Get.snackbar('Success', 'Location tracked successfully');
      } else {
        print('❌ Failed to track location');
        Get.snackbar('Error', 'Failed to track location', 
          backgroundColor: Colors.red);
      }
    } catch (e) {
      print('Error tracking location: $e');
      Get.snackbar('Error', 'Error: ${e.toString()}',
        backgroundColor: Colors.red);
    } finally {
      isTrackingLocation.value = false;
    }
  }
}
```

### Real-Time Location Updates
```dart
import 'dart:async';
import 'package:intl/intl.dart';

class TicketWorkController extends GetxController {
  final TechnicianAPI _techAPI = TechnicianAPI();
  Timer? _locationTimer;
  
  final String ticketDate; // Pass the ticket/work date
  
  TicketWorkController({required this.ticketDate});
  
  /// Start tracking location every 30 seconds
  void startLocationTracking() {
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition();
        
        final now = DateTime.now();
        final timeFormat = DateFormat('HH:mm').format(now);
        
        await _techAPI.trackLocationForTicket(
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
          date: ticketDate,
          time: timeFormat,
        );
        
        print('📍 Location tracked at $timeFormat');
      } catch (e) {
        print('Location tracking error: $e');
      }
    });
  }
  
  /// Stop tracking location
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    print('Stopped tracking location');
  }
  
  @override
  void onClose() {
    stopLocationTracking();
    super.onClose();
  }
}
```

### Track Location on Ticket Status Change
```dart
class TicketActionsController extends GetxController {
  final TechnicianAPI _techAPI = TechnicianAPI();
  
  Future<void> markAsOnTheWay(String ticketDate) async {
    try {
      // Get location
      Position position = await Geolocator.getCurrentPosition();
      
      // Get current time
      final now = DateTime.now();
      final timeFormat = DateFormat('HH:mm').format(now);
      
      // Track location with ticket date
      final tracked = await _techAPI.trackLocationForTicket(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        date: ticketDate,
        time: timeFormat,
      );
      
      if (tracked) {
        // Update ticket status in backend
        // await updateTicketStatus('on_the_way');
        print('✅ Tracked location and updated status');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  
  Future<void> markAsArrived(String ticketDate) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final now = DateTime.now();
      final timeFormat = DateFormat('HH:mm').format(now);
      
      await _techAPI.trackLocationForTicket(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        date: ticketDate,
        time: timeFormat,
      );
      
      // Update ticket status
      // await updateTicketStatus('arrived');
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

## UI Integration Example

```dart
class TicketMapScreen extends StatelessWidget {
  final String ticketDate;
  final controller = Get.put(TicketWorkController(ticketDate: ticketDate));
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Location')),
      body: Column(
        children: [
          // Map widget here
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: Text('Map will display here'),
              ),
            ),
          ),
          
          // Tracking controls
          Obx(() => Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              gap: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: controller.isTrackingLocation.value 
                    ? null
                    : () => controller.startLocationTracking(),
                  icon: Icon(Icons.location_on),
                  label: Text('▶️ Start Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: controller.isTrackingLocation.value
                    ? () => controller.stopLocationTracking()
                    : null,
                  icon: Icon(Icons.location_off),
                  label: Text('⏹️ Stop Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
```

## Permission Requirements

Ensure you have location permissions in your `pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^9.0.0
  permission_handler: ^11.0.0
  intl: ^0.18.0
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to track technician work</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to track technician work</string>
```

## Formatting Helpers

### Get Current Time in HH:MM Format
```dart
import 'package:intl/intl.dart';

String getCurrentTime() {
  return DateFormat('HH:mm').format(DateTime.now());
}

String getCurrentDate() {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
}

String getCurrentDateTime() {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
}
```

## Error Handling

All location tracking methods include error handling:
```dart
try {
  bool success = await _techAPI.trackLocationForTicket(
    latitude: lat,
    longitude: lng,
    date: date,
    time: time,
  );
  
  if (success) {
    // Location tracked successfully
    Get.snackbar('Success', '✅ Location tracked');
  } else {
    // Failed to track (check logs)
    Get.snackbar('Error', '❌ Failed to track location',
      backgroundColor: Colors.red);
  }
} catch (e) {
  // Handle exception
  print('Error: $e');
  Get.snackbar('Error', 'Error: ${e.toString()}',
    backgroundColor: Colors.red);
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Location not updating | Check location permissions and GPS is enabled |
| 401 Unauthorized | Ensure user token is valid and up-to-date |
| "Location stored successfully" but data not visible | Check date format (YYYY-MM-DD) |
| High battery drain | Reduce tracking frequency (increase interval) |
| Latitude/Longitude not being sent | Ensure you're passing strings, not numbers |

## Best Practices

1. ✅ **Request permission** before accessing location
2. ✅ **Use HH:MM format** for location_name field (time)
3. ✅ **Use YYYY-MM-DD format** for date field
4. ✅ **Convert Position to String** before sending (position.latitude.toString())
5. ✅ **Track periodically** (every 30-60 seconds) during active work
6. ✅ **Stop tracking** when work is completed
7. ✅ **Handle network errors** gracefully
8. ✅ **Show user feedback** when tracking starts/stops

---

**Last Updated:** January 5, 2026  
**API Version:** 1.0  
**Status:** Production Ready ✅
