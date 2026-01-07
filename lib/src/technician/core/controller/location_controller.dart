import 'dart:async';

import 'package:get/get.dart';
import '../../../services/apis/base_api_service.dart';
import '../../../services/sharedpref.dart';

class LocationController extends GetxController {
  var isTracking = false.obs;
  var trackingTime = "00:00:00".obs;
  var lastLocationTime = "N/A".obs;
  var statusMessage = "Location tracking is inactive".obs;

  Timer? _trackingTimer;
  DateTime? _trackingStartTime;

  @override
  void onInit() {
    super.onInit();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    isTracking(await AppSharedPref.instance.getTrackingStatus());
    if (isTracking.value) {
      _trackingStartTime = DateTime.now();
      _startTrackingTimer();
      statusMessage.value = "Location tracking is active";
    }
  }

  // Start location tracking
  Future<void> startTracking() async {
    try {
      statusMessage.value = "Starting location tracking...";

      // Initialize and start background service
      // await BackgroundLocationService.initialize();
      // await BackgroundLocationService.startTracking();

      // Update UI state
      isTracking(true);
      _trackingStartTime = DateTime.now();
      statusMessage.value = "Location tracking is active";

      // Start tracking timer
      _startTrackingTimer();
    } catch (e) {
      isTracking(false);
      statusMessage.value = "Error starting tracking: $e";
      BaseApiService().showSnackbar(
        "Tracking Error",
        "Failed to start location tracking",
      );
    }
  }

  void _startTrackingTimer() {
    _trackingTimer?.cancel();

    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isTracking.value) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      final diff = now.difference(_trackingStartTime!);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      trackingTime.value =
          '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    });
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    // Stop background service
    // await BackgroundLocationService.stopTracking();

    // Reset UI state
    isTracking(false);
    _trackingTimer?.cancel();
    trackingTime.value = "00:00:00";
    lastLocationTime.value = "N/A";
    statusMessage.value = "Location tracking is inactive";
    _trackingStartTime = null;

    // Clear tracking status
    await AppSharedPref.instance.setTrackingStatus(false);
  }

  @override
  void onClose() {
    _trackingTimer?.cancel();
    if (isTracking.value) {
      stopTracking();
    }
    super.onClose();
  }
}
