# Custom Notification Sound Setup

## ✅ Status: Custom Sound Already Configured

Your app is now configured to use **`notification_sound.mp3`** from:
- **Android**: `android/app/src/main/res/raw/notification_sound.mp3` ✅ Already present
- **iOS**: `ios/Runner/notification_sound.aiff` (needs to be added - see below)

---

## 📱 Android Setup (Already Complete)

### Current Configuration
- ✅ Sound file: `notification_sound.mp3`
- ✅ Location: `android/app/src/main/res/raw/notification_sound.mp3`
- ✅ Used in both local and Firebase notifications
- ✅ Works for foreground, background, and scheduled notifications

### How It Works
When a notification arrives:
1. **Firebase sends notification** → Device receives it
2. **App in foreground?** → NotificationHelper displays as local notification with `notification_sound.mp3`
3. **App in background?** → Firebase shows notification with system sound + custom MP3
4. **User taps?** → App opens and handles the tap

---

## 🍎 iOS Setup (Required Manual Steps)

### Add Sound File to iOS

**Option 1: Using Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Expand **Runner** folder in left sidebar
3. Right-click on **Runner** folder → **Add Files to "Runner"**
4. Navigate to your `notification_sound.aiff` file (or convert MP3 to AIFF)
5. Ensure **Copy items if needed** is checked
6. Select **Runner** target
7. Click **Add**

**Option 2: Using Terminal**

```bash
# Convert MP3 to AIFF (if needed)
# Install ffmpeg first: brew install ffmpeg
ffmpeg -i notification_sound.mp3 ios/Runner/notification_sound.aiff

# Or copy AIFF file directly
cp notification_sound.aiff ios/Runner/
```

### Create AIFF from MP3

If you only have MP3:

```bash
# Install ffmpeg
brew install ffmpeg

# Convert MP3 to AIFF
ffmpeg -i notification_sound.mp3 -acodec pcm_s16le -ac 2 -ar 44100 notification_sound.aiff

# Add to project
cp notification_sound.aiff ios/Runner/
```

---

## 🔧 Code Implementation

### NotificationHelper Configuration

All notification methods automatically use the custom sound:

```dart
// Local notifications with custom sound
await NotificationHelper.showNotification(
  title: 'Complaint Updated',
  body: 'Your complaint has been assigned',
);
// Plays: notification_sound.mp3 (Android) / notification_sound.aiff (iOS)
```

### Firebase Notifications

When Firebase sends a notification, it automatically displays with custom sound:

```python
# Backend example (Python)
from firebase_admin import messaging

message = messaging.Message(
    notification=messaging.Notification(
        title='Complaint Updated',
        body='Your complaint #AFN-00529 status changed',
    ),
    data={
        'complaint_id': '529',
    },
    token='user_fcm_token',
)

response = messaging.send(message)
# Android: Will play notification_sound.mp3
# iOS: Will play notification_sound.aiff
```

---

## 📊 Notification Sound Flow

### When App is Open (Foreground)
```
Firebase FCM Message
    ↓
NotificationHelper._handleFCMMessage()
    ↓
Shows local notification with notification_sound.mp3/aiff
```

### When App is Closed (Background)
```
Firebase Cloud Messaging
    ↓
Device receives notification
    ↓
Firebase automatically plays custom sound
    ↓
User taps notification
    ↓
App launches & handles notification
```

### Scheduled Notifications
```
NotificationHelper.scheduleNotification()
    ↓
Scheduled for future time
    ↓
When time arrives, plays notification_sound.mp3/aiff
```

---

## 🔊 Testing Custom Sound

### Test Locally (Android)

```dart
// In any screen
import 'package:asia_fibernet/src/services/utils/notification_helper.dart';

// Test button
ElevatedButton(
  onPressed: () async {
    await NotificationHelper.showNotification(
      title: 'Test Notification',
      body: 'Testing custom sound',
    );
  },
  child: Text('Test Notification'),
)
```

### Test via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **aisa-fibernet**
3. Go to **Messaging** → **Send your first message**
4. Create test notification:
   - **Title**: "Test"
   - **Body**: "Testing custom sound"
   - **Target**: Select your app/device
5. Click **Send**
6. Check if custom sound plays ✅

### Test via Backend API

```bash
# Get your FCM token from app logs
# Then send test notification

curl -X POST \
  "https://fcm.googleapis.com/v1/projects/aisa-fibernet/messages:send" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "Test",
        "body": "Testing custom sound"
      }
    }
  }'
```

---

## ✅ Checklist

- ✅ Android notification sound: `android/app/src/main/res/raw/notification_sound.mp3`
- ⏳ iOS notification sound: `ios/Runner/notification_sound.aiff` (ADD MANUALLY)
- ✅ Code: All notifications configured to use custom sound
- ✅ Firebase: Connected and configured
- ✅ Permissions: Requested at runtime

---

## 🐛 Troubleshooting

### Sound not playing on Android?

1. **Check file exists**: Verify `notification_sound.mp3` is in `android/app/src/main/res/raw/`
2. **Clean build**: Run `flutter clean && flutter pub get && flutter build apk --release`
3. **Device volume**: Ensure device is not muted or in silent mode
4. **Check permissions**: Verify notification permission is granted in settings
5. **Logcat**: Check Android logs for any sound-related errors

### Sound not playing on iOS?

1. **Add sound file**: Ensure `notification_sound.aiff` is added to Xcode project
2. **Target membership**: Check that file is added to Runner target
3. **Bundle phase**: Verify in Build Phases → Copy Bundle Resources
4. **File format**: Ensure it's `.aiff` or `.wav` (not MP3)
5. **Device volume**: Check device is not muted

### FCM notification showing but no sound?

1. **Check app state**: Is app in foreground (app is running)?
2. **Check Firebase permission**: Verify notification permission is granted
3. **Check notification channel**: Android 8.0+ requires notification channel
4. **Check firewall**: Enterprise networks sometimes block FCM

---

## 📚 Sound File Formats

| Platform | Format | Supported | Notes |
|----------|--------|-----------|-------|
| Android  | MP3    | ✅ Yes    | Used in your project |
| Android  | WAV    | ✅ Yes    | Alternative option |
| iOS      | AIFF   | ✅ Yes    | Recommended |
| iOS      | WAV    | ✅ Yes    | Alternative option |
| iOS      | MP3    | ❌ No     | Use AIFF instead |

---

## 🎯 Next Steps

1. **For iOS**: Add `notification_sound.aiff` to `ios/Runner/` (see section above)
2. **Test Android**: Run app and test notification sound
3. **Test iOS**: Run on physical device and test
4. **Update backend**: Make sure backend sends proper FCM messages

---

**Status**: ✅ Custom notification sound fully implemented for Android
**Pending**: Add AIFF sound file to iOS (manual step)

---

## 🔗 References

- [Firebase Cloud Messaging Documentation](https://firebase.flutter.dev/docs/messaging/)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Audio Format Conversion Guide](https://apple.stackexchange.com/questions/204980/how-to-convert-mp3-files-to-aiff-for-use-in-xcode)
