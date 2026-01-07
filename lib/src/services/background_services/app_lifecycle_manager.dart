import 'package:flutter/material.dart';
import 'location_tracking_background_service.dart';

/// Global App Lifecycle Manager
/// Manages background location tracking across entire app lifecycle
/// Ensures tracking persists even when app is minimized or closed
class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  
  final _bgService = LocationTrackingBackgroundService();
  bool _isInitialized = false;

  AppLifecycleManager._internal();

  factory AppLifecycleManager() {
    return _instance;
  }

  /// Initialize the lifecycle manager
  /// Call this from main.dart
  void initialize() {
    if (_isInitialized) return;
    
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    print('✅ AppLifecycleManager initialized');
  }

  /// Called when app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        print('⏸️ App paused - Background tracking continues...');
        // App is in background - tracking should continue automatically
        // Nothing to do here, timer continues running
        break;
        
      case AppLifecycleState.resumed:
        print('▶️ App resumed - Location tracking active');
        // App is back in foreground
        // Verify tracking is still running
        _verifyTracking();
        break;
        
      case AppLifecycleState.inactive:
        print('⏳ App inactive');
        // App is transitioning between states
        break;
        
      case AppLifecycleState.detached:
        print('🛑 App detached - Cleaning up...');
        // App is being closed
        // Don't stop tracking here - let it continue in background
        break;
        
      case AppLifecycleState.hidden:
        print('👤 App hidden');
        // App is hidden (mostly iOS)
        break;
    }
  }

  /// Verify tracking is still active
  Future<void> _verifyTracking() async {
    try {
      final isTracking = _bgService.isTracking();
      if (isTracking) {
        print('✅ Tracking verified - still active');
      } else {
        print('⚠️ Tracking was stopped');
      }
    } catch (e) {
      print('❌ Error verifying tracking: $e');
    }
  }

  /// Cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgService.dispose();
  }
}
