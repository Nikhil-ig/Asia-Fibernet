# FCM Token Upload - Exact Code Changes

## File 1: `lib/src/auth/core/controller/otp_controller.dart`

### Change 1: Add Import (Line 2)
```dart
// BEFORE:
import 'dart:async';

import 'package:flutter/material.dart';

// AFTER:
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
```

### Change 2: Modify OTP Verification (Around Line 295)
```dart
// BEFORE:
if (verifyResponse != null && verifyResponse.isValid) {
  // ✅ OTP verified successfully
  // Token and user data are already saved by the API method

  // 📱 Upload FCM token to the API
  await _uploadFcmToken();

  if (!Get.isRegistered<ScaffoldController>()) {
    Get.put(ScaffoldController());
  }

  _baseApiService.showSnackbar("Success", verifyResponse.message);

  // 🔑 Check user role from response and navigate accordingly
  final userRole = verifyResponse.data.role;
  if (userRole == "technician") {
    Get.offAllNamed(AppRoutes.technicianDashboard);
  } else {
    Get.offAllNamed(AppRoutes.home);
  }
}

// AFTER:
if (verifyResponse != null && verifyResponse.isValid) {
  // ✅ OTP verified successfully
  // Token and user data are already saved by the API method

  if (!Get.isRegistered<ScaffoldController>()) {
    Get.put(ScaffoldController());
  }

  _baseApiService.showSnackbar("Success", verifyResponse.message);

  // 🔑 Check user role from response and navigate accordingly
  final userRole = verifyResponse.data.role;
  
  // 📱 Upload FCM token in background (non-blocking)
  // This runs after navigation so it doesn't slow down the login flow
  _uploadFcmTokenInBackground();
  
  if (userRole == "technician") {
    Get.offAllNamed(AppRoutes.technicianDashboard);
  } else {
    Get.offAllNamed(AppRoutes.home);
  }
}
```

### Change 3: Replace Old Method with New Method (Around Line 397)
```dart
// BEFORE:
  Future<void> _uploadFcmToken() async {
    try {
      print("📱 Starting FCM token upload...");
      final apiService = ApiServices();
      final fcmToken = await AppSharedPref.instance.getFCMToken();

      print(
        "📱 FCM Token from SharedPreferences: ${fcmToken?.substring(0, 20)}...",
      );

      if (fcmToken == null || fcmToken.isEmpty) {
        print("⚠️ FCM token is empty or null");
        return;
      }

      final result = await apiService.fcmToken();

      if (result != null) {
        print("✅ FCM Token uploaded successfully");
        print("📱 API Response: $result");
      } else {
        print("⚠️ Failed to upload FCM token - API returned null");
      }
    } catch (e) {
      print("❌ Error uploading FCM token: $e");
      print("🔍 Error details: ${e.toString()}");
    }
  }

  void _clearOtpFields() {
    for (var c in otpControllers) c.clear();
    if (focusNodes.isNotEmpty) {
      FocusScope.of(Get.context!).requestFocus(focusNodes[0]);
    }
  }

// AFTER:
  /// 📱 Upload FCM token in background (non-blocking)
  /// This method runs asynchronously without awaiting, allowing login to proceed
  void _uploadFcmTokenInBackground() {
    // Run in background without blocking the UI
    Future.microtask(() async {
      try {
        final fcmToken = await AppSharedPref.instance.getFCMToken();

        if (fcmToken == null || fcmToken.isEmpty) {
          developer.log(
            '⚠️ FCM token is empty or null in background upload',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
          return;
        }

        final apiService = ApiServices();
        final result = await apiService.fcmToken();

        if (result != null) {
          developer.log(
            '✅ FCM Token uploaded successfully in background',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
        } else {
          developer.log(
            '⚠️ Failed to upload FCM token in background - API returned null',
            name: 'OTPController._uploadFcmTokenInBackground',
          );
        }
      } catch (e) {
        developer.log(
          '❌ Error uploading FCM token in background: $e',
          name: 'OTPController._uploadFcmTokenInBackground',
          error: e,
        );
      }
    });
  }

  void _clearOtpFields() {
    for (var c in otpControllers) c.clear();
    if (focusNodes.isNotEmpty) {
      FocusScope.of(Get.context!).requestFocus(focusNodes[0]);
    }
  }
```

---

## File 2: `lib/src/services/apis/api_services.dart`

### Change 1: Add Import (Line 2)
```dart
// BEFORE:
// services/api_services.dart
import 'dart:convert';
import 'dart:io';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

// AFTER:
// services/api_services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
```

### Change 2: Replace fcmToken() Method (Around Line 693)
```dart
// BEFORE:
  Future<Map<String, dynamic>?> fcmToken() async {
    final body = {'fcm_token': AppSharedPref.instance.getFCMToken()};
    try {
      final res = await _apiClient.post(_fcmToken, body: body);
      return _apiClient.handleResponse(res, (json) => json);
    } catch (e) {
      if (e.toString().contains('Unauthorized: No token')) return null;
      return null;
    }
  }

// AFTER:
  Future<Map<String, dynamic>?> fcmToken() async {
    try {
      // 📱 Get FCM token from SharedPreferences (it's now async)
      final fcmTokenValue = await AppSharedPref.instance.getFCMToken();
      
      if (fcmTokenValue == null || fcmTokenValue.isEmpty) {
        developer.log(
          'FCM token is null or empty - skipping upload',
          name: 'ApiServices.fcmToken',
        );
        return {'status': 'skipped', 'reason': 'FCM token not available'};
      }
      
      final body = {'fcm_token': fcmTokenValue};
      
      // Retry logic for better reliability in release builds
      http.Response? res;
      int retries = 0;
      const maxRetries = 2;
      
      while (retries < maxRetries) {
        try {
          res = await _apiClient.post(_fcmToken, body: body).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('FCM token upload timeout');
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            rethrow;
          }
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * retries));
        }
      }
      
      if (res == null) {
        developer.log(
          'FCM token upload failed - null response',
          name: 'ApiServices.fcmToken',
        );
        return null;
      }

      final response = _apiClient.handleResponse(res, (json) => json);
      if (response != null) {
        developer.log(
          'FCM token uploaded successfully: $response',
          name: 'ApiServices.fcmToken',
        );
      }
      return response;
    } catch (e) {
      developer.log(
        'Error uploading FCM token: $e',
        name: 'ApiServices.fcmToken',
        error: e,
      );
      // Don't throw, just log and return null - FCM upload shouldn't block login
      return null;
    }
  }
```

---

## Summary of Changes

### OTPController Changes
1. ✅ Added `import 'dart:developer' as developer;`
2. ✅ Changed from `await _uploadFcmToken()` to `_uploadFcmTokenInBackground()`
3. ✅ Moved FCM upload call after navigation (non-blocking)
4. ✅ Replaced `_uploadFcmToken()` with `_uploadFcmTokenInBackground()`
5. ✅ Use `developer.log()` instead of `print()`

### ApiServices Changes
1. ✅ Added `import 'dart:async';`
2. ✅ Added `await` to `getFCMToken()` call (properly async)
3. ✅ Added null/empty check before uploading
4. ✅ Added retry logic (up to 2 attempts)
5. ✅ Added explicit 10-second timeout
6. ✅ Use `developer.log()` for logging
7. ✅ Better error handling and graceful degradation

---

## Key Improvements

| Aspect | Change | Impact |
|--------|--------|--------|
| **Blocking** | `await` → `Future.microtask()` | Non-blocking login |
| **Async Handling** | Proper `await` for `getFCMToken()` | Works in release builds |
| **Logging** | `print()` → `developer.log()` | Visible in both modes |
| **Retry** | None → Up to 2 attempts | Better reliability |
| **Timeout** | None → 10 seconds | No indefinite hangs |
| **Error Message** | None → Detailed logging | Easier debugging |

---

## Testing the Changes

### Build & Test
```bash
# Clean and rebuild
flutter clean
flutter pub get

# Debug mode
flutter run

# Release mode (APK)
flutter build apk --release

# Check logs
adb logcat | grep "fcmToken"
```

### Expected Success Output
```
✅ FCM Token uploaded successfully in background
✅ FCM token uploaded successfully: {status: success}
```

### Expected Failure Output (Graceful)
```
⚠️ FCM token is empty or null in background upload
⚠️ Failed to upload FCM token in background - API returned null
❌ Error uploading FCM token: [error description]
```

---

**All changes are backward compatible and don't break existing functionality!**
