import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:asia_fibernet/src/services/apis/technician_api_service.dart';

/// Background Service for Location Tracking
/// This service handles periodic location tracking in the background
class LocationTrackingBackgroundService {
  static final LocationTrackingBackgroundService _instance =
      LocationTrackingBackgroundService._internal();

  factory LocationTrackingBackgroundService() {
    return _instance;
  }

  LocationTrackingBackgroundService._internal();

  final TechnicianAPI _techAPI = TechnicianAPI();
  Timer? _locationTimer;
  bool _isTracking = false;

  /// Start tracking location periodically
  ///
  /// Parameters:
  /// - [ticketDate]: Date for the ticket (YYYY-MM-DD format)
  /// - [intervalSeconds]: Interval between location updates (default: 60 seconds)
  ///
  /// Example:
  /// ```dart
  /// await _bgService.startTracking(
  ///   ticketDate: '2026-01-05',
  ///   intervalSeconds: 60,
  /// );
  /// ```
  Future<void> startTracking({
    required String ticketDate,
    int intervalSeconds = 60,
  }) async {
    if (_isTracking) {
      print('⚠️ Tracking already in progress');
      return;
    }

    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return;
        }
      }

      _isTracking = true;

      // Start periodic location tracking
      _locationTimer = Timer.periodic(Duration(seconds: intervalSeconds), (
        timer,
      ) async {
        await _trackLocationOnce(ticketDate);
      });

      // Track immediately on start
      await _trackLocationOnce(ticketDate);

      print('🚀 Location tracking started (interval: ${intervalSeconds}s)');
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  /// Track location once
  Future<void> _trackLocationOnce(String ticketDate) async {
    try {
      // Get current location with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () async {
          // Fallback to low accuracy if high accuracy times out
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
        },
      );

      // Get current time
      final now = DateTime.now();
      final timeFormat = DateFormat('HH:mm').format(now);

      // Track location via API
      final success = await _techAPI.trackLocationForTicket(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        date: ticketDate,
        time: timeFormat,
      );

      if (success) {
        print(
          '✅ Location tracked: Lat=${position.latitude.toStringAsFixed(4)}, Lng=${position.longitude.toStringAsFixed(4)} at $timeFormat',
        );
      } else {
        print('⚠️ Failed to sync location to server');
      }
    } catch (e) {
      print('❌ Location tracking error: $e');
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    try {
      _locationTimer?.cancel();
      _locationTimer = null;
      _isTracking = false;
      print('⏹️ Location tracking stopped');
    } catch (e) {
      print('❌ Error stopping tracking: $e');
    }
  }

  /// Check if currently tracking
  bool isTracking() => _isTracking;

  /// Get current tracking status
  Future<Map<String, dynamic>> getTrackingInfo() async {
    return {
      'isTracking': _isTracking,
      'hasPermission': await _checkLocationPermission(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if location permission is granted
  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Clean up resources
  void dispose() {
    stopTracking();
  }
}
