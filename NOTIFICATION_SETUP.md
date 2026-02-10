# Notification Setup Guide

## ✅ Notification Features Implemented

The `NotificationHelper` class now supports both **Local** and **Firebase Cloud Messaging (FCM)** notifications.

---

## 📋 Features

### Local Notifications
- ✅ Show instant notifications
- ✅ Schedule notifications with delay
- ✅ Custom sound with vibration
- ✅ LED lights on Android
- ✅ Notification tapping/click handling
- ✅ Payload support for deep linking

### Firebase Notifications
- ✅ Receive FCM notifications from backend
- ✅ Handle foreground messages
- ✅ Handle background messages
- ✅ Auto-display FCM as local notification
- ✅ FCM token management
- ✅ Topic subscription/unsubscription
- ✅ Token refresh handling

---

## 🚀 Initialization

Add this to your `main.dart` or in your app initialization:

```dart
import 'package:asia_fibernet/src/services/utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize notifications (both local + Firebase)
  await NotificationHelper.initialize();
  
  runApp(const MyApp());
}
```

---

## 💬 Usage Examples

### 1. Show Local Notification

```dart
await NotificationHelper.showNotification(
  title: 'Complaint Submitted',
  body: 'Your complaint has been submitted successfully!',
);
```

### 2. Schedule Notification (Delayed)

```dart
await NotificationHelper.scheduleNotification(
  title: 'Reminder',
  body: 'Please rate your experience',
  duration: Duration(hours: 2),
);
```

### 3. Get FCM Token

```dart
String? fcmToken = await NotificationHelper.getFCMToken();
print('FCM Token: $fcmToken');

// Send this token to your backend to save in database
```

### 4. Subscribe to Topic

```dart
// Subscribe user to 'complaints' topic
await NotificationHelper.subscribeToTopic('complaints');

// Later, unsubscribe
await NotificationHelper.unsubscribeFromTopic('complaints');
```

---

## 📱 Android Setup

Your app is already configured with:
- ✅ Notification channel created
- ✅ Sound: `notification_sound` (place audio file in `android/app/src/main/res/raw/`)
- ✅ Vibration enabled
- ✅ LED lights enabled
- ✅ Google Services configured in `google-services.json`

**Required files:**
- `android/app/src/main/res/raw/notification_sound.wav` or `.mp3`

---

## 🍎 iOS Setup

Your app is already configured with:
- ✅ Sound: `notification_sound.aiff`
- ✅ Alert permission requested
- ✅ Badge permission requested
- ✅ Sound permission requested

**Required files:**
- `ios/Runner/notification_sound.aiff` (add to Xcode)

---

## 🔧 Backend Integration

### Sending Notifications via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aisa-fibernet**
3. Go to **Messaging** → **Send your first message**
4. Create notification:
   - **Title**: "Complaint Updated"
   - **Body**: "Your complaint status has changed"
   - **Target**: Select your app
5. Send!

### Sending via Backend API

Use Firebase Admin SDK to send notifications:

```python
# Example: Python Flask backend
from firebase_admin import messaging

# Send to specific device token
message = messaging.Message(
    notification=messaging.Notification(
        title='Complaint Updated',
        body='Your complaint #AFN-00529 is now assigned',
    ),
    data={
        'complaint_id': '529',
        'status': 'Assigned',
    },
    token='your_fcm_token_here',  # Get from user profile
)

response = messaging.send(message)
print(f'Sent notification: {response}')
```

**Send to Topic:**
```python
# Notify all users subscribed to 'complaints' topic
message = messaging.Message(
    notification=messaging.Notification(
        title='New Complaint Update',
        body='A complaint you follow has been updated',
    ),
    topic='complaints',
)

response = messaging.send(message)
```

---

## 📊 Notification Flow

### Local Notification Flow
```
User Action → NotificationHelper.showNotification() 
          → Local Notification displayed
          → User taps → _handleNotificationTap() → Deep link to relevant screen
```

### Firebase Notification Flow
```
Backend → Firebase Cloud Messaging
      → Device receives FCM message
      → If app in foreground → _handleFCMMessage()
         → Shows as local notification
      → If app in background → Handled by FCM
      → User taps → Opens app & handles deep link
```

---

## 🎯 Deep Linking Setup (Optional)

To handle notification taps and navigate to relevant screens:

```dart
// In _handleNotificationTap method, add routing logic:
static void _handleNotificationTap(String? payload) {
  if (payload == null) return;
  
  if (payload.contains('complaint_id')) {
    // Extract complaint ID and navigate
    Get.to(() => ComplaintDetailScreen(complaintId: '529'));
  } else if (payload.contains('profile')) {
    Get.to(() => ProfileScreen());
  }
}
```

---

## 🔔 Notification Permissions

### Android (Automatic)
- Requested at runtime via notification channel
- Users see permission prompt when notification is sent

### iOS (Automatic)
- Requested via `requestPermission()` in Firebase initialization
- Users see system permission dialog

---

## 📝 Important Notes

1. **FCM Token Management**:
   - Token is retrieved automatically during initialization
   - Send this token to your backend to store in user's profile
   - Handle token refresh (automatically listening in the code)

2. **Sound Files**:
   - Android: Place `.wav` or `.mp3` in `android/app/src/main/res/raw/notification_sound.*`
   - iOS: Place `.aiff` or `.wav` in `ios/Runner/notification_sound.aiff`

3. **Topic Subscriptions**:
   - Users can subscribe to topics like 'complaints', 'promotions', etc.
   - Useful for sending bulk notifications

4. **Testing**:
   - Send test notification from Firebase Console
   - Check device logs for notification events
   - Ensure device is connected and logged in

---

## 🐛 Troubleshooting

### Notification not showing?
1. Check if permissions are granted
2. Verify sound file exists
3. Check logcat/device logs for errors
4. Ensure `NotificationHelper.initialize()` is called before showing

### FCM token not received?
1. Ensure Firebase project is connected
2. Check internet connection
3. Verify `google-services.json` is correct
4. App needs to be signed for production

### Sound not playing?
1. Check if sound file exists in correct location
2. Device volume is not muted
3. Device notification settings allow sound

---

## 📚 References

- [Firebase Messaging Documentation](https://firebase.flutter.dev/docs/messaging/overview/)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Console](https://console.firebase.google.com/)

---

**Status**: ✅ Full implementation complete with local + Firebase support
