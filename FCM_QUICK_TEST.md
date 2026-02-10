# FCM Token Upload - Quick Test Guide

## What Happens After Login

### Timeline:
```
1. User enters mobile number
2. User verifies OTP ✅
3. Dashboard loads IMMEDIATELY (non-blocking)
4. In BACKGROUND:
   - Fresh FCM token fetched from Firebase
   - Token saved to SharedPreferences
   - Token uploaded to API
```

## Console Logs to Watch For

### ✅ Success Logs (in order):
```
I/flutter: 🔄 Refreshing FCM token from Firebase after login...
I/flutter: ✅ Fresh FCM token saved from Firebase: [TOKEN_VALUE]
I/flutter: 📤 Uploading FCM token to API: [TOKEN_VALUE]
I/flutter: ✅ FCM Token uploaded successfully in background
I/flutter: Response: {success: true, message: "Token updated", ...}
```

### ⚠️ Error Logs (if something fails):
```
I/flutter: ⚠️ FCM token is empty or null in background upload
# or
I/flutter: ❌ Error uploading FCM token in background: [ERROR_MESSAGE]
```

## How to Verify It's Working

### Method 1: Check Console Logs
1. Open terminal and run: `flutter logs`
2. Login with valid credentials
3. Look for the success logs above
4. Verify all 4 logs appear in order

### Method 2: Network Monitoring (Best)
1. Install Charles Proxy or Fiddler
2. Configure Flutter to use proxy
3. Login
4. Look for POST request to: `/af/api/update_fcm_token.php`
5. Verify request body has `fcm_token` field
6. Verify response shows `{"success": true}`

### Method 3: Server Logs
1. Check your API server logs
2. Look for POST requests to `/af/api/update_fcm_token.php`
3. Verify the FCM token was received and stored
4. Check database for updated fcm_token field

## Expected API Request

**Method:** POST
**URL:** `https://asiafibernet.in/af/api/update_fcm_token.php`
**Headers:** 
```
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer [USER_TOKEN]
```
**Body:**
```
fcm_token=[FCM_TOKEN_VALUE]
```

**Response (Success):**
```json
{
  "success": true,
  "message": "FCM token updated successfully",
  "status": "success"
}
```

## What Changed

### Before:
- FCM token was uploaded during login (blocking)
- Could delay login if API was slow
- Only token from app startup was used

### Now:
- ✅ Fresh FCM token fetched from Firebase after login
- ✅ Upload happens in background (non-blocking)
- ✅ User reaches dashboard immediately
- ✅ Token is current and valid
- ✅ Retry logic handles failures

## Quick Verification Checklist

Run through these steps:

- [ ] App starts and shows FCM token in console
- [ ] Enter valid mobile number
- [ ] Verify OTP successfully
- [ ] Dashboard loads immediately (no delay)
- [ ] Console shows "🔄 Refreshing FCM token..." log
- [ ] Console shows "✅ Fresh FCM token saved..." log
- [ ] Console shows "📤 Uploading FCM token..." log
- [ ] Console shows "✅ FCM Token uploaded successfully..." log
- [ ] (Optional) Network monitor shows POST to update_fcm_token.php
- [ ] (Optional) Server received the token successfully

## Files Modified

Only 1 file was modified:
- `lib/src/auth/core/controller/otp_controller.dart`
  - Added import for `firebase_messaging`
  - Enhanced `_uploadFcmTokenInBackground()` method
  - Added Firebase token refresh step

## Testing in Different Builds

### Debug Build:
```bash
flutter run
```
- All logs visible in console
- Can test immediately after app starts

### Release Build:
```bash
flutter build apk --release
flutter install
```
- Background upload works without blocking login
- May not see all logs (adjust logging if needed)
- Same API call happens in background

## Troubleshooting Quick Fixes

| Problem | Fix |
|---------|-----|
| "FCM token is empty" | Restart app, ensure internet connection |
| API upload fails | Check API server is running, check logs |
| No logs appearing | Run `flutter logs` before login |
| Slow login | This shouldn't happen (upload is async) |
| Token not updating on server | Check API response, verify database |

## Key Points to Remember

✅ **Non-Blocking:** Login completes immediately, upload happens in background
✅ **Fresh Token:** Gets new token from Firebase after login (not startup token)
✅ **Automatic Retry:** Retries up to 2 times if API fails
✅ **Error Safe:** Won't block login if upload fails
✅ **Logged:** Detailed logs for debugging
✅ **Production Ready:** Works in both debug and release builds

---

**Need more info?** See `FCM_LOGIN_VERIFICATION.md` for detailed documentation.
