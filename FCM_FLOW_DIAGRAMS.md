# FCM Token Flow Diagram & Visual Guide

## Complete Login Flow with FCM Upload

```
┌─────────────────────────────────────────────────────────────────┐
│                      APP STARTUP (main.dart)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ Initialize Firebase                                         │
│  ✅ Request FCM token from Firebase                             │
│  ✅ Save to SharedPreferences                                   │
│                                                                  │
│  Console Output:                                                │
│  =====================================                          │
│  !!! COPY THIS FCM TOKEN FOR TESTING !!!                       │
│  FCM Token: ePLbn898SHOmfIV9oX4H48:APA91b...                   │
│  =====================================                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    USER LOGS IN (otp_screen.dart)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1️⃣ User enters mobile number                                  │
│  2️⃣ User taps "Send OTP"                                       │
│  3️⃣ User receives OTP                                          │
│  4️⃣ User enters OTP in 6 text fields                           │
│  5️⃣ User taps "Verify" button                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│            OTP VERIFICATION (otp_controller.dart)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ Call: ApiServices().verifyOTP()                            │
│  ✅ Response: {success: true, token: "...", role: "..."}      │
│  ✅ Save token & user data to SharedPreferences               │
│                                                                  │
│  🔄 Call: _uploadFcmTokenInBackground() [NON-BLOCKING]        │
│     (starts background process without awaiting)               │
│                                                                  │
│  ✅ Navigate to Dashboard IMMEDIATELY                          │
│     (user sees dashboard right away)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                ↙                              ↘
    (UI Thread)                         (Background Task)
         ↓                                       ↓
┌──────────────────────┐  ┌───────────────────────────────────────┐
│   USER DASHBOARD     │  │  FCM TOKEN UPLOAD (in background)     │
├──────────────────────┤  ├───────────────────────────────────────┤
│                      │  │                                       │
│ ✅ Fully loaded      │  │  STEP 1: Refresh from Firebase       │
│ ✅ Interactive       │  │  ──────────────────────────────────  │
│ ✅ Ready to use      │  │                                       │
│                      │  │  🔄 FirebaseMessaging.instance.      │
│ 💬 Get notifications │  │     getToken()                        │
│    sent later        │  │                                       │
│                      │  │  📱 Save fresh token to              │
│                      │  │     SharedPreferences                │
│                      │  │                                       │
│                      │  │  Console Log:                        │
│                      │  │  "✅ Fresh FCM token saved            │
│                      │  │   from Firebase: eK5lbn..."          │
│                      │  │                                       │
│                      │  │  ↓                                    │
│                      │  │                                       │
│                      │  │  STEP 2: Validate Token              │
│                      │  │  ───────────────────────────────────  │
│                      │  │                                       │
│                      │  │  ✅ Retrieve from SharedPreferences  │
│                      │  │  ✅ Check if null/empty              │
│                      │  │                                       │
│                      │  │  Console Log:                        │
│                      │  │  "📤 Uploading FCM token to          │
│                      │  │   API: eK5lbn..."                   │
│                      │  │                                       │
│                      │  │  ↓                                    │
│                      │  │                                       │
│                      │  │  STEP 3: Upload to API               │
│                      │  │  ────────────────────────────────────  │
│                      │  │                                       │
│                      │  │  📡 POST Request:                    │
│                      │  │     /af/api/update_fcm_token.php     │
│                      │  │                                       │
│                      │  │  Headers:                            │
│                      │  │  Authorization: Bearer [USER_TOKEN]  │
│                      │  │  Content-Type: application/x-www-   │
│                      │  │                form-urlencoded       │
│                      │  │                                       │
│                      │  │  Body:                               │
│                      │  │  fcm_token=eK5lbn898...             │
│                      │  │                                       │
│                      │  │  Retry Logic (if fails):            │
│                      │  │  ✅ Retry 1 after 500ms             │
│                      │  │  ✅ Retry 2 after 1000ms            │
│                      │  │  ❌ Give up after 2 retries         │
│                      │  │  (won't block login anyway)          │
│                      │  │                                       │
│                      │  │  ↓                                    │
│                      │  │                                       │
│                      │  │  ✅ Success Response:                │
│                      │  │  {                                   │
│                      │  │    "success": true,                  │
│                      │  │    "message": "Token updated"        │
│                      │  │  }                                   │
│                      │  │                                       │
│                      │  │  Console Log:                        │
│                      │  │  "✅ FCM Token uploaded               │
│                      │  │   successfully in background"        │
│                      │  │                                       │
│                      │  └───────────────────────────────────────┘
│                      │
│ Ready to receive     │ (Token now stored on server)
│ push notifications   │ (User can receive messages)
│ from server! 🎉      │
└──────────────────────┘
```

## Timing Diagram

```
Time →  [Login Start] ... [OTP Sent] ... [OTP Entered] [Verified]
                                                        ↓
                                              IMMEDIATE USER SEES:
                                              ✅ Dashboard loads (0ms)
                                              
                                              BACKGROUND CONTINUES:
                                              🔄 Firebase refresh (50ms)
                                              📤 API upload (200ms)
                                              ✅ Success log (250ms)
                                              
Total Time to Dashboard: ~0ms (non-blocking)
Total FCM Upload Time: ~250ms (in background)
```

## State Flow Diagram

```
┌─────────────────────┐
│   LOGGED OUT        │
│                     │
│ - No token          │
│ - No dashboard      │
└──────────┬──────────┘
           │
           │ User enters mobile & OTP
           ↓
┌─────────────────────┐
│  VERIFYING OTP      │
│                     │
│ - Waiting for API   │
│ - UI blocked        │
└──────────┬──────────┘
           │
           │ OTP verified successfully
           ↓
┌─────────────────────┐
│  LOADING DASHBOARD  │
│                     │
│ - Token saved ✅    │
│ - User data saved ✅│
│ - FCM refresh       │
│   starts in BG      │
└──────────┬──────────┘
           │
           │ Navigation complete
           ↓
┌─────────────────────┐
│  DASHBOARD READY    │  ← USER SEES THIS (0ms)
│                     │
│ - Dashboard open ✅ │
│ - Fully interactive │
│ - FCM upload in BG  │
└──────────┬──────────┘
           │
           │ Background work continues (in parallel)
           │ 🔄 Firebase refresh
           │ 📤 API upload
           │ ✅ Token stored
           ↓
┌─────────────────────┐
│  FULLY CONNECTED    │  ← BACKGROUND (250ms)
│                     │
│ - Dashboard open ✅ │
│ - FCM uploaded ✅   │
│ - Ready for push    │
│   notifications ✅  │
└─────────────────────┘
```

## Decision Tree - What Happens Next

```
                    User Taps "Verify"
                           │
                           ↓
                   Call verifyOTP()
                           │
                    ┌──────┴──────┐
                    ↓             ↓
            OTP Valid?       OTP Invalid?
                    │             │
                   YES           NO
                    │             │
                    ↓             ↓
            Start FCM Upload  Show Error
            in background     & Clear OTP
                    │
                    ↓
            Navigate to Dashboard
            (Without waiting for FCM)
                    │
                    ↓
            ┌───────┴────────────────┐
            ↓                        ↓
        In Background:          User is navigating:
        ┌─────────────────┐   ┌──────────────────┐
        │ Try to refresh  │   │ Dashboard loads  │
        │ FCM from        │   │ User can already │
        │ Firebase        │   │ use the app      │
        │                 │   │                  │
        │ ┌──────┬──────┐ │   │ (No waiting!)    │
        │ ↓      ↓      ↓ │   └──────────────────┘
        │Token? → Upload
        │      │ OK? ✅
        │      │
        │      ↓ Try Again
        │    (Retry Logic)
        │      │
        │      ↓ Success ✅
        │    Log & Done
        │
        └─────────────────┘
```

## Network Request Diagram

```
┌──────────────┐                              ┌──────────────┐
│    App       │                              │ API Server   │
│   (Client)   │                              │              │
└──────┬───────┘                              └──────┬───────┘
       │                                             │
       │ 1. Send OTP                                │
       ├────────────────────────────────────────────>│
       │                                             │
       │                2. OTP Sent                  │
       │<────────────────────────────────────────────┤
       │                                             │
       │ 3. Verify OTP                              │
       ├────────────────────────────────────────────>│
       │                                             │
       │ (User sees dashboard loading here)         │
       │                                             │
       │    4. Token & User Data                    │
       │<────────────────────────────────────────────┤
       │                                             │
       │ ✅ Dashboard Ready to Display              │
       │                                             │
       │ (In Background Now):                       │
       │ 5. Upload FCM Token                        │
       ├────────────────────────────────────────────>│
       │                                             │
       │    6. Success Response                     │
       │<────────────────────────────────────────────┤
       │                                             │
       │ ✅ Token Stored                            │
       │                                             │
```

## Component Interaction Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    OTP Controller                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  verifyOTP()                                                │
│  ├─ Calls: ApiServices.verifyOTP()                         │
│  │   └─ Verifies OTP & returns token                       │
│  │                                                          │
│  ├─ Calls: _uploadFcmTokenInBackground()  [NEW]            │
│  │   ├─ Calls: FirebaseMessaging.instance.getToken()      │
│  │   │   └─ Gets fresh token from Firebase                │
│  │   │                                                      │
│  │   ├─ Calls: AppSharedPref.instance.setfcmToken()       │
│  │   │   └─ Saves fresh token                             │
│  │   │                                                      │
│  │   ├─ Calls: AppSharedPref.instance.getFCMToken()       │
│  │   │   └─ Retrieves for upload                          │
│  │   │                                                      │
│  │   └─ Calls: ApiServices.fcmToken()                     │
│  │       └─ Uploads to API with retry                     │
│  │                                                          │
│  └─ Navigates to Dashboard                                │
│     (Without waiting for FCM upload)                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
         ↓              ↓              ↓              ↓
    ┌────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────┐
    │Firebase│ │  App Shared  │ │   API        │ │ Router │
    │    &   │ │    Pref      │ │ Services     │ │        │
    │Firebase│ │              │ │              │ │        │
    │Messaging│ │SaveToken()  │ │fcmToken()   │ │Navigate│
    └────────┘ │GetToken()    │ └──────────────┘ └────────┘
```

## Log Output Timeline

```
Timeline    Component              Log Message
────────    ──────────            ────────────────
0ms        OTP Controller         ✅ Verification successful
1ms        OTP Controller         User Role: UserRole.technician
2ms        OTP Controller         Token: 'eyJ0eXAiOiJKV1QiLC...'
3ms        OTP Controller         🔄 Refreshing FCM token from Firebase after login...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5ms        Router                 Navigating to Dashboard
10ms       Dashboard              Dashboard rendered and visible to user
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
50ms       FCM Service (BG)       ✅ Fresh FCM token saved from Firebase: eK5lbn...
75ms       Shared Pref (BG)       FCM Token retrieved from cache
100ms      API Service (BG)       📤 Uploading FCM token to API: eK5lbn...
150ms      HTTP Client (BG)       Sending POST request to /af/api/update_fcm_token.php
200ms      Network (BG)           Received response from server
250ms      API Service (BG)       ✅ FCM Token uploaded successfully in background
251ms      OTP Controller (BG)    Response: {success: true, message: "Token updated"}
```

---

**Visual Guide Created:** January 21, 2026
**Status:** ✅ Complete
