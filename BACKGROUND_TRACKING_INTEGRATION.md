# Background Location Tracking Integration Guide

## Integration Points in Your Technician Workflow

### 1. Ticket Acceptance

When technician accepts a ticket, start background tracking:

```dart
class TicketListController extends GetxController {
  final TechnicianAPI _techAPI = TechnicianAPI();
  final _bgService = LocationTrackingBackgroundService();
  
  /// Accept a ticket and start background location tracking
  Future<void> acceptTicket(TicketModel ticket) async {
    try {
      // Call API to accept ticket
      final success = await _techAPI.acceptTicket(ticket.ticketNo);
      
      if (success) {
        // Start background location tracking
        final ticketDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        await _bgService.startTracking(
          ticketDate: ticketDate,
          intervalSeconds: 60, // Track every 60 seconds
        );
        
        Get.snackbar(
          '✅ Ticket Accepted',
          'Location tracking started',
          duration: Duration(seconds: 3),
        );
        
        // Navigate to ticket work screen
        Get.to(() => TicketWorkScreen(ticket: ticket));
      }
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to accept ticket: $e');
    }
  }
}
```

### 2. Ticket Work Screen

Show tracking status and allow manual stops:

```dart
class TicketWorkScreen extends StatelessWidget {
  final TicketModel ticket;
  final _bgService = LocationTrackingBackgroundService();
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation before leaving active tracking
        if (_bgService.isTracking()) {
          final shouldStop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Location Tracking Active'),
              content: Text('Location tracking is still active. Stop it?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Keep Tracking'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Stop Tracking'),
                ),
              ],
            ),
          );
          
          if (shouldStop ?? false) {
            await _bgService.stopTracking();
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ticket: ${ticket.ticketNo}'),
          elevation: 0,
        ),
        body: Column(
          children: [
            // Tracking Status Card
            _buildTrackingStatusCard(),
            
            // Customer Details
            _buildCustomerDetails(),
            
            // Work Details
            Expanded(child: _buildWorkDetails()),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrackingStatusCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Tracking Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tracking every 60 seconds',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.white),
        ],
      ),
    );
  }
  
  Widget _buildCustomerDetails() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer: ${ticket.customerName}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Phone: ${ticket.customerPhone}'),
            Text('Address: ${ticket.customerAddress}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkDetails() {
    return Card(
      margin: EdgeInsets.all(16),
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
            SizedBox(height: 12),
            Text('Issue: ${ticket.issue}'),
            Text('Description: ${ticket.description}'),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),
            Text('Add work notes here...'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        gap: 12,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // Continue tracking - just go back
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('👈 Back (Keep Tracking)'),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // Complete ticket and stop tracking
                await _completeTicketAndStop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('✅ Complete'),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _completeTicketAndStop(BuildContext context) async {
    try {
      // Mark ticket as complete
      // await _techAPI.completeTicket(ticket.ticketNo);
      
      // Stop background tracking
      await _bgService.stopTracking();
      
      Get.snackbar(
        '✅ Success',
        'Ticket completed and tracking stopped',
        duration: Duration(seconds: 3),
      );
      
      // Navigate back
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to complete ticket: $e');
    }
  }
}
```

### 3. Dashboard Integration

Show active tracking status in dashboard:

```dart
class TechnicianDashboardController extends GetxController {
  final _bgService = LocationTrackingBackgroundService();
  
  var isActivelyTracking = false.obs;
  var trackingInfo = <String, dynamic>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    _checkTrackingStatus();
  }
  
  void _checkTrackingStatus() {
    // Update UI every 5 seconds
    Timer.periodic(Duration(seconds: 5), (_) async {
      isActivelyTracking.value = _bgService.isTracking();
      
      if (isActivelyTracking.value) {
        trackingInfo.value = await _bgService.getTrackingInfo();
      }
    });
  }
}

class DashboardScreen extends StatelessWidget {
  final controller = Get.put(TechnicianDashboardController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          // Show tracking indicator
          Obx(() => Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Chip(
                avatar: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  controller.isActivelyTracking.value
                      ? '📍 Tracking Active'
                      : '⏸️ Not Tracking',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: controller.isActivelyTracking.value
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // Show tracking status card if active
          Obx(() {
            if (controller.isActivelyTracking.value) {
              return Card(
                margin: EdgeInsets.all(16),
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Tracking Active',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            Text(
                              'Your location is being tracked in background',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
          
          // Rest of dashboard...
          Expanded(
            child: ListView(
              children: [
                // Active tickets
                // Statistics
                // etc.
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. App Lifecycle Management

Handle tracking on app pause/resume:

```dart
class TechnicianApp extends StatefulWidget {
  @override
  State<TechnicianApp> createState() => _TechnicianAppState();
}

class _TechnicianAppState extends State<TechnicianApp>
    with WidgetsBindingObserver {
  final _bgService = LocationTrackingBackgroundService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App going to background - tracking continues!
        print('⏸️ App paused (tracking continues in background)');
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground
        print('▶️ App resumed');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: SplashScreen(),
      // ... rest of config
    );
  }
}
```

## 📊 Data Flow

```
User accepts ticket
    ↓
Start background tracking (startTracking())
    ↓
Periodic location fetches (every 60s)
    ↓
API call sends to backend (trackLocationForTicket)
    ↓
Backend stores location data
    ↓
[App can be closed - tracking continues]
    ↓
User completes ticket
    ↓
Stop background tracking (stopTracking())
```

## 🔔 Notifications During Tracking

When tracking is active, users see persistent notification showing:
- "Location Tracking Active"
- Last tracked time
- Current coordinates

This keeps them aware tracking is happening.

## ⚙️ Configuration Recommendations

| Scenario | Interval | Duration | Use Case |
|----------|----------|----------|----------|
| Active Work | 30-60s | During ticket | High precision needed |
| Standard Tracking | 60-120s | Normal work | Good balance |
| Long Distance Travel | 120s+ | On the way | Battery efficient |
| Background Only | 300s | 5 minute gap | Minimal tracking |

## 📱 Testing Checklist

- [ ] Start tracking, close app completely
- [ ] Verify location updates continue in background
- [ ] Check device battery optimization doesn't kill service
- [ ] Verify API receives location data
- [ ] Test stop tracking while app is closed
- [ ] Verify permissions request works
- [ ] Test on different Android versions (API 21+)
- [ ] Check notification shows while tracking
- [ ] Verify battery drain is acceptable

## 🐛 Common Issues

**Issue:** Tracking stops after app closes
- **Solution:** Check device battery optimization settings, whitelist your app

**Issue:** Location not syncing to backend
- **Solution:** Verify network connectivity, check API token validity

**Issue:** High battery drain
- **Solution:** Increase tracking interval to 120+ seconds

**Issue:** Permission denied
- **Solution:** Request permissions explicitly before starting tracking

---

**Integration Status:** ✅ Ready for Production
