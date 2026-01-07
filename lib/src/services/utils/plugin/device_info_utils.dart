// lib/src/core/utils/device_info_utils.dart

import 'dart:developer' as developer;
import 'dart:io';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:device_info_plus/device_info_plus.dart'; // ✅ Import for device info

/// A utility class to gather device information like IP, location, Wi-Fi details.
class DeviceInfoUtils {
  static final NetworkInfo _networkInfo = NetworkInfo();
  static final DeviceInfoPlugin _deviceInfoPlugin =
      DeviceInfoPlugin(); // ✅ Device Info Plugin Instance

  /// Gets the public IP address, falling back to the local Wi-Fi IP.
  static Future<String> getIpAddress() async {
    try {
      final String? publicIp = await IpAddress().getIpAddress();
      if (publicIp != null && publicIp.isNotEmpty) {
        return publicIp;
      }
      // Fallback to local Wi-Fi IP
      final String? localIp = await _networkInfo.getWifiIP();
      return localIp ?? "0.0.0.0";
    } catch (e) {
      developer.log('Error getting public IP, trying local IP: $e');
      try {
        final String? localIp = await _networkInfo.getWifiIP();
        return localIp ?? "0.0.0.0";
      } catch (e2) {
        developer.log('Error getting local IP: $e2');
        return "0.0.0.0";
      }
    }
  }

  /// Gets the current time zone name (e.g., "Asia/Kolkata").
  static String getTimeZone() {
    try {
      // This call might fail with LateInitializationError if data isn't ready
      return tz.local.name;
    } catch (e) {
      // Handle LateInitializationError specifically or generally
      developer.log(
        'Error getting time zone (might be uninitialized data): $e',
      );
      // Fallback to UTC if there's any issue getting the local timezone
      return "UTC";
    }
  }

  /// Attempts to get the current geographical position.
  static Future<Position?> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log('Location services are disabled.');
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        developer.log('Location permissions are denied.');
        // Don't show snackbar here, let the calling code decide
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      developer.log('Location permissions are permanently denied.');
      // Don't show snackbar here, let the calling code decide
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy
                .medium, // Consider if high accuracy is always needed
      );
    } catch (e) {
      developer.log('Error getting location: $e');
      return null;
    }
  }

  /// Gets the city name based on the current location.
  static Future<String> getCityName() async {
    final position = await getLocation();
    if (position == null) return "Unknown";
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Prioritize locality, fallback to subAdministrativeArea
        return place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea!
                : "Unknown");
      }
    } catch (e) {
      developer.log('Error getting city name: $e');
    }
    return "Unknown";
  }

  /// Gets the postal code based on the current location.
  static Future<String> getPostalCode() async {
    final position = await getLocation();
    if (position == null) return "Unknown";
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        return place.postalCode ?? "Unknown";
      }
    } catch (e) {
      developer.log('Error getting postal code: $e');
    }
    return "Unknown";
  }

  /// Gets various Wi-Fi related information.
  static Future<Map<String, String>> getWifiInfo() async {
    try {
      // Attempt to get Wi-Fi details. These might be null if not connected to Wi-Fi.
      final ssid = await _networkInfo.getWifiName();
      final bssid = await _networkInfo.getWifiBSSID();
      final ip = await _networkInfo.getWifiIP();
      final ipv6 =
          await _networkInfo
              .getWifiIPv6(); // Might often be null or unsupported

      final subnet = "255.255.255.0"; // Common default, might not be accurate
      final broadcast =
          ip != null ? _calculateBroadcast(ip, subnet) : "Unknown";
      // Common default gateway assumption (first host of subnet)
      final gateway =
          ip != null ? "${ip.split('.').take(3).join('.')}.1" : "Unknown";

      return {
        'ssid': ssid ?? "Unknown",
        'bssid': bssid ?? "Unknown",
        'ip': ip ?? "Unknown",
        'ipv6': ipv6 ?? "Unknown",
        'subnet': subnet,
        'broadcast': broadcast,
        'gateway': gateway,
      };
    } catch (e) {
      developer.log('Error getting Wi-Fi info: $e');
      // Return 'Unknown' for all fields on error
      return {
        'ssid': 'Unknown',
        'bssid': 'Unknown',
        'ip': 'Unknown',
        'ipv6': 'Unknown',
        'subnet': 'Unknown',
        'broadcast': 'Unknown',
        'gateway': 'Unknown',
      };
    }
  }

  /// Helper method to calculate the broadcast IP from IP and subnet mask.
  static String _calculateBroadcast(String ip, String subnet) {
    try {
      final ipParts = ip.split('.').map(int.parse).toList();
      final subnetParts = subnet.split('.').map(int.parse).toList();
      final broadcastParts = <int>[];
      for (int i = 0; i < 4; i++) {
        // Bitwise OR: Network part (AND) + Host part (NOT subnet)
        broadcastParts.add(
          (ipParts[i] & subnetParts[i]) | (~subnetParts[i] & 255),
        );
      }
      return broadcastParts.join('.');
    } catch (e) {
      developer.log('Error calculating broadcast address: $e');
      return "Unknown";
    }
  }

  /// Gets dynamic device information (model, brand, OS version, etc.).
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return {
          'device': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'version_release': androidInfo.version.release,
          'version_sdk': androidInfo.version.sdkInt.toString(),
          'id': androidInfo.id, // Build ID
          'hardware': androidInfo.hardware,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'device': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name, // e.g., "My iPhone"
          'system_name': iosInfo.systemName, // e.g., "iOS"
          'system_version': iosInfo.systemVersion,
          'localized_model': iosInfo.localizedModel,
          'identifier_for_vendor': iosInfo.identifierForVendor ?? "Unknown",
        };
      } else {
        // Fallback for other platforms (Web, Desktop - limited info)
        return {'device': 'Other', 'model': 'Unknown', 'brand': 'Unknown'};
      }
    } catch (e) {
      developer.log('Error getting device info: $e');
      // Provide minimal fallback info on error
      return {'device': 'Unknown', 'model': 'Unknown', 'brand': 'Unknown'};
    }
  }

  /// Gathers all available device information into a single map.
  /// This mimics the structure often used in API request bodies.
  /// Includes dynamic device details.
  static Future<Map<String, dynamic>> getAllDeviceInfo() async {
    // Run independent futures concurrently for better performance
    final ipAddressFuture = getIpAddress();
    final timeZoneFuture = Future.value(
      getTimeZone(),
    ); // Already sync, wrap for consistency
    final locationFuture = getLocation();
    final wifiInfoFuture = getWifiInfo();
    final deviceInfoFuture = getDeviceInfo(); // ✅ Get device info

    // Wait for all futures to complete
    final results = await Future.wait([
      ipAddressFuture,
      timeZoneFuture,
      locationFuture,
      wifiInfoFuture,
      deviceInfoFuture,
      getCityName(), // Depends on location
      getPostalCode(), // Depends on location
    ], eagerError: false); // Don't stop on first error

    final String ipAddress = results[0] as String;
    final String timeZone = results[1] as String;
    final Position? location = results[2] as Position?;
    final Map<String, String> wifiInfo = results[3] as Map<String, String>;
    final Map<String, String> deviceInfo =
        results[4] as Map<String, String>; // ✅ Get result
    final String cityName = results[5] as String;
    final String postalCode = results[6] as String;

    final double latitude = location?.latitude ?? 0.0;
    final double longitude = location?.longitude ?? 0.0;

    // Merge all maps into the final request data map
    return {
      'ip_address': ipAddress,
      'time_zone': timeZone,
      'latitude': latitude,
      'longitude': longitude,
      'city_name': cityName,
      'postal_code': postalCode,
      ...wifiInfo, // Spread Wi-Fi info
      ...deviceInfo, // ✅ Spread dynamic device info
    };
  }
}
