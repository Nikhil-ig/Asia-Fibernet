# Background Location Tracking - Quick Start

## 📦 Step 1: Install Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^9.0.0
  intl: ^0.18.0
```

Run: `flutter pub get`

## 🔧 Step 2: Android Setup (REQUIRED)

### Update `android/app/build.gradle`
```gradle
android {
    minSdkVersion 21  // IMPORTANT: Increase from default
    targetSdkVersion 34
}
```

### Update `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 📱 Step 3: iOS Setup (OPTIONAL but RECOMMENDED)

### Update `ios/Runner/Info.plist`
Add inside `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to track work location</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location for background tracking</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## 🚀 Step 4: Use in Your Code

### Basic Usage

```dart
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

class TicketScreen extends StatelessWidget {
  final _bgService = LocationTrackingBackgroundService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ticket Work')),
      body: Column(
        children: [
          // Start tracking when accepting ticket
          ElevatedButton(
            onPressed: () async {
              await _bgService.startTracking(
                ticketDate: '2026-01-05',
                intervalSeconds: 60, // Track every 60 seconds
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Tracking started')),
              );
            },
            child: Text('▶️ Start Tracking'),
          ),
          
          // Stop tracking when completing ticket
          ElevatedButton(
            onPressed: () async {
              await _bgService.stopTracking();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('⏹️ Tracking stopped')),
              );
            },
            child: Text('⏹️ Stop Tracking'),
          ),
        ],
      ),
    );
  }
}
```

### In a GetX Controller

```dart
import 'package:get/get.dart';
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

class TicketController extends GetxController {
  final _bgService = LocationTrackingBackgroundService();
  
  var isTracking = false.obs;
  
  /// Accept ticket and start background tracking
  Future<void> acceptTicket(String ticketNo, String ticketDate) async {
    try {
      // Accept ticket on backend
      // await acceptTicketApi(ticketNo);
      
      // Start background location tracking
      await _bgService.startTracking(
        ticketDate: ticketDate,
        intervalSeconds: 60,
      );
      
      isTracking.value = true;
      Get.snackbar('✅ Success', 'Location tracking started');
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to start tracking: $e');
    }
  }
  
  /// Complete ticket and stop tracking
  Future<void> completeTicket(String ticketNo) async {
    try {
      // Mark ticket as complete
      // await completeTicketApi(ticketNo);
      
      // Stop tracking
      await _bgService.stopTracking();
      
      isTracking.value = false;
      Get.snackbar('✅ Success', 'Ticket completed');
    } catch (e) {
      Get.snackbar('❌ Error', e.toString());
    }
  }
  
  @override
  void onClose() {
    // Always stop tracking when closing
    _bgService.dispose();
    super.onClose();
  }
}
```

## 📊 Tracking Intervals

```dart
// Track every 30 seconds (high accuracy)
await _bgService.startTracking(
  ticketDate: ticketDate,
  intervalSeconds: 30,
);

// Track every 60 seconds (recommended)
await _bgService.startTracking(
  ticketDate: ticketDate,
  intervalSeconds: 60,
);

// Track every 2 minutes (battery efficient)
await _bgService.startTracking(
  ticketDate: ticketDate,
  intervalSeconds: 120,
);

// Track every 5 minutes (low power mode)
await _bgService.startTracking(
  ticketDate: ticketDate,
  intervalSeconds: 300,
);
```

## ✅ Check Tracking Status

```dart
// Check if currently tracking
if (_bgService.isTracking()) {
  print('📍 Tracking is ACTIVE');
}

// Get detailed tracking info
final info = await _bgService.getTrackingInfo();
print('Is Tracking: ${info['isTracking']}');
print('Has Permission: ${info['hasPermission']}');
print('Timestamp: ${info['timestamp']}');
```

## 🎯 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';

class CompleteTicketWorkScreen extends StatefulWidget {
  final String ticketNo;
  final String ticketDate;
  
  const CompleteTicketWorkScreen({
    required this.ticketNo,
    required this.ticketDate,
  });

  @override
  State<CompleteTicketWorkScreen> createState() =>
      _CompleteTicketWorkScreenState();
}

class _CompleteTicketWorkScreenState extends State<CompleteTicketWorkScreen> {
  final _bgService = LocationTrackingBackgroundService();
  
  late bool _isTracking;
  late int _trackingInterval;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _isTracking = false;
    _trackingInterval = 60;
    _startTime = DateTime.now();
  }

  Future<void> _startTracking() async {
    try {
      await _bgService.startTracking(
        ticketDate: widget.ticketDate,
        intervalSeconds: _trackingInterval,
      );
      
      setState(() => _isTracking = true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Location tracking started every $_trackingInterval seconds'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTracking() async {
    try {
      await _bgService.stopTracking();
      
      setState(() => _isTracking = false);
      
      final duration = DateTime.now().difference(_startTime);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏹️ Tracking stopped (duration: ${duration.inMinutes}m)'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bgService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket: ${widget.ticketNo}'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.ticketDate))),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tracking Status
            Card(
              color: _isTracking ? Colors.green : Colors.grey,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isTracking ? 'Tracking Active' : 'Tracking Inactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isTracking)
                      Text(
                        'Every ${_trackingInterval}s',
                        style: TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Interval Slider
            if (!_isTracking)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tracking Interval: ${_trackingInterval}s',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _trackingInterval.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 9,
                    label: '${_trackingInterval}s',
                    onChanged: (value) {
                      setState(() => _trackingInterval = value.toInt());
                    },
                  ),
                ],
              ),
            SizedBox(height: 20),

            // Control Buttons
            ElevatedButton.icon(
              onPressed: _isTracking ? null : _startTracking,
              icon: Icon(Icons.play_arrow),
              label: Text('▶️ Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : null,
              icon: Icon(Icons.stop),
              label: Text('⏹️ Stop Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            // Work details go here...
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('✅ Started: ${DateFormat('HH:mm').format(_startTime)}'),
                        Text('⏱️ Duration: ${DateTime.now().difference(_startTime).inMinutes}m'),
                        Text('📍 Tracking: ${_isTracking ? "Active" : "Inactive"}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## ⚡ Key Points

✅ **Works in background** - Even when app is closed  
✅ **No external dependencies** - Uses only geolocator  
✅ **Simple API** - Just `startTracking()` and `stopTracking()`  
✅ **Battery efficient** - Configurable intervals  
✅ **API integration** - Automatically sends data to backend  
✅ **Error handling** - Graceful fallbacks for location accuracy  

## 🐛 Troubleshooting

### "Can't get location" error
→ Check permissions are granted in device settings

### Background tracking stops
→ Ensure your device is not killing background processes (Settings > Battery)

### API not syncing
→ Check internet connection and API token validity

### High battery drain
→ Increase tracking interval from 30s to 120s+

---

**Ready to use!** Just copy-paste the code and customize for your needs. 🎉
