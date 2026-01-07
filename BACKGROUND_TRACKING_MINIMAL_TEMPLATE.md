# Minimal Integration Template

Copy and paste this into any controller to add background tracking:

## Option 1: Simple Template (Copy-Paste Ready)

```dart
import 'package:asia_fibernet/src/services/background_services/location_tracking_background_service.dart';
import 'package:intl/intl.dart';

class YourController extends GetxController {
  // 1️⃣ Add this line
  final _bgService = LocationTrackingBackgroundService();
  
  // Your other code...
  
  // 2️⃣ Add this method
  Future<void> startLocationTracking() async {
    try {
      await _bgService.startTracking(
        ticketDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        intervalSeconds: 60,
      );
      print('✅ Tracking started');
    } catch (e) {
      print('❌ Tracking error: $e');
    }
  }
  
  // 3️⃣ Add this method
  Future<void> stopLocationTracking() async {
    try {
      await _bgService.stopTracking();
      print('✅ Tracking stopped');
    } catch (e) {
      print('❌ Stop error: $e');
    }
  }
  
  // 4️⃣ Call in your workflow
  Future<void> acceptTicketAndStartTracking(String ticketNo) async {
    final success = await api.acceptTicket(ticketNo);
    if (success) {
      await startLocationTracking(); // ← Add this
    }
  }
  
  // 5️⃣ Call when done
  Future<void> completeTicketAndStopTracking(String ticketNo) async {
    final success = await api.completeTicket(ticketNo);
    if (success) {
      await stopLocationTracking(); // ← Add this
    }
  }
}
```

## Option 2: In-Line Usage (Fastest)

```dart
// Just add this where needed:

// START
await LocationTrackingBackgroundService().startTracking(
  ticketDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  intervalSeconds: 60,
);

// STOP
await LocationTrackingBackgroundService().stopTracking();
```

## Option 3: Global Access (Anywhere)

```dart
// Since it's a singleton, use it like this anywhere:

class RandomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Access from anywhere!
        await LocationTrackingBackgroundService().startTracking(
          ticketDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          intervalSeconds: 60,
        );
      },
      child: Text('Start Tracking'),
    );
  }
}
```

## Key Methods

```dart
// Start tracking
await bgService.startTracking(
  ticketDate: 'YYYY-MM-DD',      // Required
  intervalSeconds: 60,             // Required (30-300 recommended)
);

// Stop tracking
await bgService.stopTracking();

// Check if tracking
bool isActive = bgService.isTracking();

// Get info
Map<String, dynamic> info = await bgService.getTrackingInfo();

// Cleanup (on app exit)
bgService.dispose();
```

## One-Liner Integration

Add this to your existing button's onPressed:

```dart
ElevatedButton(
  onPressed: () async {
    // Your existing code...
    
    // Add tracking!
    await LocationTrackingBackgroundService().startTracking(
      ticketDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      intervalSeconds: 60,
    );
  },
  child: Text('Accept Ticket'),
),
```

---

That's it! Works everywhere, even when app is closed. 🚀
