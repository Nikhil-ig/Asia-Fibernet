# FCM Token Upload Implementation

## Overview
This implementation automatically uploads the FCM (Firebase Cloud Messaging) token to your API endpoint after successful login/OTP verification.

## Implementation Details

### Changes Made

#### 1. Modified: `lib/src/auth/core/controller/otp_controller.dart`

**Added Method:**
```dart
/// 📱 Upload FCM token to the API after successful login
Future<void> _uploadFcmToken() async {
  try {
    final apiService = ApiServices();
    final result = await apiService.fcmToken();
    
    if (result != null) {
      print("✅ FCM Token uploaded successfully");
    } else {
      print("⚠️ Failed to upload FCM token");
    }
  } catch (e) {
    print("❌ Error uploading FCM token: $e");
  }
}
```

**Modified Verification Logic:**
After successful OTP verification (line ~300), added:
```dart
// 📱 Upload FCM token to the API
await _uploadFcmToken();
```

### How It Works

1. **User logs in** with mobile number
2. **OTP is verified** via `verifyOTP()` method in `ApiServices`
3. **Upon successful verification**, the `_uploadFcmToken()` method is called
4. **FCM token** is retrieved from SharedPreferences (saved during app startup in `main.dart`)
5. **Token is sent** to the API endpoint: `/af/api/update_fcm_token.php`
6. **API receives** Bearer token in Authorization header (already handled by `BaseApiService`)

### API Endpoint Details

**Endpoint:** `/af/api/update_fcm_token.php`
**Method:** POST
**Authentication:** Bearer Token (JWT)

**Request Body:**
```json
{
  "fcm_token": "ePLbn898SHOmfIV9oX4H48:APA91bHGRdpVWmi2tsyMATTu5JAV3BiHWCxB2FIWVXifpp9T7h1iDk6brRMAjsiP-Vy2in3BeHKFL8KQnO-8W1C9WohxDITtrDrdtoG8FtLpyy4weHvjCVk"
}
```

**Response Expected:**
```json
{
  "status": "success",
  "message": "FCM token updated successfully"
}
```

### Flow Diagram

```
Login Screen
    ↓
Enter Mobile Number
    ↓
Generate OTP
    ↓
Enter OTP
    ↓
Verify OTP (API Call)
    ↓
✅ If OTP Valid
    ↓
Upload FCM Token (NEW) ← Added Implementation
    ↓
Save Token & User Data to SharedPreferences
    ↓
Register ScaffoldController
    ↓
Check User Role
    ↓
Navigate to Dashboard (Customer/Technician)
```

## Already Implemented Components

### 1. FCM Token Storage in SharedPreferences
**File:** `lib/src/services/sharedpref.dart`
```dart
Future<bool> setfcmToken(String token) {
  _validatePrefs();
  return _prefs!.setString(_fcmToken, token);
}

String? getFCMToken() {
  _validatePrefs();
  return _prefs!.getString(_fcmToken);
}
```

### 2. API Service Method
**File:** `lib/src/services/apis/api_services.dart`
```dart
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
```

### 3. FCM Token Initialization in main.dart
**File:** `lib/main.dart` (Lines 60-90)
- FCM token is retrieved when app starts
- Token is saved to SharedPreferences for later use

## Testing the Implementation

### Manual Testing Steps:

1. **Build and run the app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Copy FCM Token from logs**
   Look for the console output:
   ```
   =======================================
   !!! COPY THIS FCM TOKEN FOR TESTING !!!
   FCM Token: ePLbn898SHOmfIV9oX4H48:APA91b...
   =======================================
   ```

3. **Test Login Flow**
   - Enter a valid mobile number on the login screen
   - Verify OTP when prompted
   - Check console logs for:
     - ✅ "Verification successful"
     - ✅ "User Role: UserRole.xxx"
     - ✅ "FCM Token uploaded successfully"

4. **Verify with Network Debugger**
   - Use Charles Proxy or Fiddler
   - Look for POST request to `/af/api/update_fcm_token.php`
   - Verify request body contains the FCM token
   - Verify Authorization header has Bearer token

### Expected Console Output:

```
I/flutter ( 1234): ✅ Verification successful
I/flutter ( 1234): User Role: UserRole.customer
I/flutter ( 1234): Token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...'
I/flutter ( 1234): ✅ FCM Token uploaded successfully
```

## Error Handling

The implementation includes error handling:
- If FCM token upload fails, it won't block the user from accessing the dashboard
- Errors are logged to console for debugging
- User will still be logged in and can access their account
- FCM token can be retried on next login or when explicitly triggered

## Future Enhancements

1. **Retry Logic:** Implement automatic retry on FCM token upload failure
2. **Silent Failure Handling:** Send FCM token in background without blocking UI
3. **Token Refresh:** Upload new FCM token when it refreshes (Firebase token refresh)
4. **Analytics:** Track FCM token upload success/failure rates

## Files Modified

- ✅ `/Users/apple/Documents/Office/company/HTCL/asia_fibernet/lib/src/auth/core/controller/otp_controller.dart`
  - Added `_uploadFcmToken()` method
  - Called `_uploadFcmToken()` after OTP verification

## Verification Checklist

- [x] FCM token is being captured on app startup
- [x] Token is stored in SharedPreferences
- [x] API endpoint is defined in ApiServices
- [x] Bearer token authentication is configured
- [x] FCM token upload is called after successful login
- [x] Error handling is in place
- [x] Console logging is available for debugging
- [x] No errors in Dart analysis

---

**Status:** ✅ Implementation Complete
**Date:** 20 January 2026
