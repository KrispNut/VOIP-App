# VOIP App

A Flutter softphone application with SIP/WebRTC P2P calling, dead app wake-up via FCM/APNS push notifications, and native CallKit integration for iOS.

## Features

- **SIP Registration** - Register with a SIP server using extension credentials
- **Login System** - Secure authentication with credential persistence
- **P2P Calling** - Direct audio calls via WebRTC
- **Inbound Calling** - Receive incoming calls with CallKit (iOS) integration
- **Push Notifications** - FCM/APNs wake-up for dead/killed apps
- **Background Recovery** - Handle calls when app is backgrounded
- **Call Controls** - Mute, speaker, hold, and end call
- **Auto-Answer** - Automatic call pickup after CallKit accept

## Tech Stack

| Package | Purpose |
|---------|---------|
| `sip_ua` | SIP User Agent |
| `flutter_webrtc` | WebRTC media streaming |
| `flutter_callkit_incoming` | iOS CallKit integration |
| `firebase_core` | Firebase initialization |
| `firebase_messaging` | FCM/APNs push notifications |
| `provider` | State management |
| `dio` | HTTP client |

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1
- Xcode (for iOS)
- Android Studio (for Android)
- Firebase project with FCM enabled
- SIP server

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd VOIP-App

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

1. **Firebase Setup**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Enable Cloud Messaging in Firebase Console

2. **SIP Server**
   - Configure your SIP server URL in the app
   - Ensure WebSocket support (WSS recommended)

## Screenshots

<!-- Will add screenshots once the app is polished -->

## Roadmap

- [ ] **Asterisk Server** - Full Asterisk integration
- [ ] Video calling support
- [ ] Group/conference calls
- [ ] Call history
- [ ] Contact management
