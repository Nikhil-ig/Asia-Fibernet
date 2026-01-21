# FCM Token Upload - Implementation Checklist & Verification

## Pre-Implementation Checklist ✅
- [x] Firebase Cloud Messaging dependency installed
- [x] FCM token retrieval working in `main.dart`
- [x] FCM token storage in SharedPreferences
- [x] API endpoint defined (`update_fcm_token.php`)
- [x] Bearer token authentication configured

## Implementation Checklist ✅

### Code Changes
- [x] Added `import 'dart:developer' as developer;` to OTPController
- [x] Added `import 'dart:async';` to ApiServices
- [x] Changed FCM upload from blocking to non-blocking
- [x] Implemented `_uploadFcmTokenInBackground()` method
- [x] Enhanced `fcmToken()` with proper async/await
- [x] Added retry logic (up to 2 attempts)
- [x] Added explicit timeout (10 seconds)
- [x] Replaced `print()` with `developer.log()`
- [x] Proper error handling and logging

### Testing
- [x] Code compiles without errors
- [x] No import errors
- [x] No syntax errors
- [x] No compilation warnings
- [x] All async/await properly handled

## Verification Checklist

### Debug Mode Testing
- [ ] Build with `flutter run`
- [ ] Navigate to login screen
- [ ] Enter valid mobile number
- [ ] Verify OTP
- [ ] Check console logs for: "FCM Token uploaded successfully"
- [ ] User navigates to dashboard immediately
- [ ] No loading delays

### Release Mode Testing (APK)
- [ ] Clean build: `flutter clean`
- [ ] Build APK: `flutter build apk --release`
- [ ] Install on Android device: `adb install -r app-release.apk`
- [ ] Login with valid credentials
- [ ] User navigates to dashboard immediately (< 1 second)
- [ ] Check logs: `adb logcat | grep "fcmToken"`
- [ ] Verify success output appears

### Release Mode Testing (iOS)
- [ ] Build: `flutter build ios --release`
- [ ] Run on physical device (not simulator)
- [ ] Login with valid credentials
- [ ] User navigates immediately
- [ ] Check Dart DevTools logging

### Network Testing

#### Good Network (< 1s latency)
- [ ] Login with good WiFi
- [ ] Dashboard loads in < 1 second
- [ ] "FCM Token uploaded successfully" in logs
- [ ] No retry messages in logs

#### Poor Network (5-10s latency)
- [ ] Login on slow mobile network
- [ ] Dashboard loads in < 1 second (still)
- [ ] Retry messages appear in logs
- [ ] Second attempt succeeds or fails gracefully
- [ ] Login doesn't fail

#### No Network (Offline)
- [ ] Login while offline (won't work, expected)
- [ ] OR login online, then go offline
- [ ] Dashboard accessible offline
- [ ] No crash or error

### API Testing

#### Using Network Debugger (Charles Proxy/Fiddler)
- [ ] Intercept request to `/af/api/update_fcm_token.php`
- [ ] Verify method is POST
- [ ] Verify request body: `{"fcm_token": "..."}`
- [ ] Verify Authorization header: `Bearer <jwt_token>`
- [ ] Verify response status: 200
- [ ] Verify response contains: `{"status": "success"}`

#### Using adb logcat
```bash
# In one terminal
adb logcat | grep "fcmToken"

# Then login on device
# Should see:
# OTPController._uploadFcmTokenInBackground
# ApiServices.fcmToken
# Success or error messages
```

#### Using Dart DevTools
- [ ] Open Dart DevTools
- [ ] Select "Logging" tab
- [ ] Filter by "fcmToken"
- [ ] Login
- [ ] Verify logs appear for both success and failure

### Edge Cases

#### Token Not Available
- [ ] Simulate missing FCM token
- [ ] Should log: "FCM token is empty or null"
- [ ] Should not crash
- [ ] Login should still work
- [ ] No retry attempts

#### API Timeout
- [ ] Simulate 15+ second API delay
- [ ] Should timeout after 10 seconds
- [ ] Should log: "FCM token upload timeout"
- [ ] Should retry once
- [ ] Login should not be affected

#### Network Failure
- [ ] Disconnect internet during FCM upload
- [ ] Should fail and retry
- [ ] Should log error details
- [ ] User can still use app
- [ ] No blocking or hanging

#### Server Error (500)
- [ ] Simulate server returning 500 error
- [ ] Should log error
- [ ] Should retry
- [ ] Should eventually give up gracefully
- [ ] No blocking login

### Security Checks
- [ ] Bearer token properly sent in Authorization header
- [ ] FCM token never logged in plain text (substring only)
- [ ] No sensitive data exposed in error messages
- [ ] Token retrieval uses async SharedPreferences
- [ ] No hardcoded tokens or credentials

### Performance Checks
- [ ] Login time < 1 second (without FCM)
- [ ] FCM upload doesn't delay dashboard
- [ ] Retry logic doesn't cause excessive delays
- [ ] Memory usage normal (no leaks)
- [ ] CPU usage minimal while uploading
- [ ] No battery drain from continuous retries

### Code Quality Checks
- [x] No compilation errors
- [x] No lint warnings (related to FCM)
- [x] Proper error handling
- [x] Proper async/await usage
- [x] Logging in both modes
- [x] No hardcoded values (except timeout/retries)
- [x] Comments and documentation
- [x] Backward compatible

## Deployment Checklist

### Before Release
- [ ] All tests pass
- [ ] Code reviewed
- [ ] APK built and tested
- [ ] Logging verified in release mode
- [ ] Network scenarios tested
- [ ] Edge cases handled
- [ ] Version bumped in pubspec.yaml
- [ ] Changelog updated

### Release Process
- [ ] Build production APK
- [ ] Test on multiple devices
- [ ] Test on different networks
- [ ] Verify in Google Play Console
- [ ] Update app version
- [ ] Deploy to production

### Post-Release
- [ ] Monitor crash reports
- [ ] Monitor error logs
- [ ] Monitor FCM upload success rate
- [ ] Gather user feedback
- [ ] Monitor performance metrics

## Troubleshooting Guide

### Issue: FCM Token Still Not Uploading

**Step 1: Check FCM Token Availability**
```bash
adb logcat | grep "COPY THIS FCM TOKEN"
```
- If no output, Firebase not initialized properly

**Step 2: Check SharedPreferences**
```bash
adb shell
sqlite3 /data/data/com.example.asia_fibernet/databases/flutter_pref.db
SELECT * FROM preferences WHERE key LIKE '%fcm%';
```
- Should see FCM token saved

**Step 3: Check Network**
- Verify internet connectivity
- Ping the API server
- Check firewall/proxy settings

**Step 4: Check Logs**
```bash
adb logcat | grep -E "(fcmToken|OTPController)"
```
- Look for specific error messages

**Step 5: Check API**
- Verify endpoint is correct
- Verify API server is responding
- Check server logs for errors

### Issue: Login Delayed After Fix

**Cause:** FCM upload might still be blocking
**Solution:**
```dart
// Ensure this is NOT awaited
_uploadFcmTokenInBackground();  // ✅ Correct
// NOT this:
await _uploadFcmTokenInBackground();  // ❌ Wrong
```

### Issue: Logs Not Showing in Release

**Cause:** Using `print()` instead of `developer.log()`
**Solution:**
- Ensure `developer.log()` used throughout
- Check Dart DevTools for logs

## Documentation

Created documentation files:
- [x] `FCM_TOKEN_IMPLEMENTATION.md` - Initial implementation
- [x] `FCM_TOKEN_RELEASE_BUILD_FIX.md` - Bug fix details
- [x] `FCM_TOKEN_FIX_SUMMARY.md` - Quick reference
- [x] `FCM_COMPLETE_SOLUTION.md` - Complete guide
- [x] `FCM_VISUAL_COMPARISON.md` - Before/After
- [x] `FCM_EXACT_CODE_CHANGES.md` - Exact changes
- [x] `FCM_IMPLEMENTATION_CHECKLIST.md` - This file

## Sign-Off

- [ ] Developer: Code complete and tested
- [ ] QA: All tests passed
- [ ] Product: Feature verified working
- [ ] Release: Ready for production

---

## Next Steps

1. **Complete all verification checks above**
2. **Run final tests on multiple devices**
3. **Build production APK**
4. **Deploy to staging environment**
5. **Get final approval**
6. **Deploy to production**
7. **Monitor logs and crash reports**
8. **Gather feedback from users**

## Support Contact

For issues or questions about FCM token upload:
1. Check the documentation files (above)
2. Review the troubleshooting guide
3. Check logs via `adb logcat | grep fcmToken`
4. Review error messages in Dart DevTools

---

**Status:** ✅ Ready for Testing & Deployment
**Date:** 21 January 2026
**Version:** 1.0

---

Good luck with deployment! 🚀
