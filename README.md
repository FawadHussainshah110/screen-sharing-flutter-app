# Mirror Phone Scan - Wireless Screen Mirroring

Mirror your mobile screen to PC wirelessly using QR code scanning. Built with Flutter and WebRTC for real-time, cable-free screen mirroring.

## 🌟 Features

- ✅ **Wireless Connection** - No cables required, just scan a QR code
- ✅ **Real-time Streaming** - Low latency WebRTC-based screen mirroring
- ✅ **Secure** - Encrypted peer-to-peer connection
- ✅ **Modern UI** - Beautiful glassmorphism design with smooth animations
- ✅ **Easy Setup** - Simple QR code scanning for instant connection
- ✅ **Cross-Platform** - Works on Android (iOS support coming soon)

## 🏗️ Architecture

```
┌──────────────┐                  ┌──────────────┐
│    Mobile    │                  │      PC      │
│   (Flutter)  │                  │  (Web App)   │
└──────┬───────┘                  └──────┬───────┘
       │                                 │
       │   1. Scan QR Code               │
       │◄────────────────────────────────┤
       │                                 │
       │   2. WebSocket Signaling        │
       │◄────────────────────────────────►
       │    (via Node.js Server)         │
       │                                 │
       │   3. WebRTC P2P Stream          │
       │◄────────────────────────────────►
       │                                 │
```

## 📋 Prerequisites

### For Development:
- **Flutter SDK** (≥3.9.2)
- **Node.js** (≥16.0.0)
- **Android device** (Android 5.0+ / API 21+)
- **PC** (Windows/Mac/Linux)

### For Running:
- Both devices must be on the **same WiFi network**
- Camera permission (for QR scanning)
- Screen recording permission (Android)

## 🚀 Setup Instructions

### Step 1: Server Setup

1. **Navigate to server directory:**
   ```bash
   cd server
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the server:**
   ```bash
   npm start
   ```

4. **Open PC application:**
   - The server will display your IP address in the terminal
   - Open your browser and go to: `http://<your-ip>:3000`
   - You'll see a QR code displayed on the screen

### Step 2: Mobile App Setup

1. **Update server URL in constants:**
   ```dart
   // lib/utils/constants.dart
   static const String serverUrl = 'http://YOUR_PC_IP_HERE:3000';
   ```
   
   Replace `YOUR_PC_IP_HERE` with your PC's IP address shown in the server terminal.

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app on your Android device:**
   ```bash
   flutter run
   ```

### Step 3: Connect and Mirror

1. **On PC:** Open the web app - you'll see a QR code
2. **On Mobile:** Launch the app and tap "Start Mirroring"
3. **Scan:** Point your camera at the QR code on PC screen
4. **Grant Permissions:** Allow screen recording permission when prompted
5. **Mirror:** Your screen will appear on the PC instantly!

## 📱 How It Works

1. **QR Code Generation:** PC generates a QR code containing session ID and server URL
2. **Connection:** Mobile scans QR code and connects to the signaling server
3. **WebRTC Handshake:** Devices exchange SDP offers/answers via WebSocket
4. **P2P Streaming:** Direct peer-to-peer video stream starts via WebRTC
5. **Real-time Mirroring:** Your mobile screen appears on PC with minimal latency

## 🛠️ Technologies Used

### Backend
- **Node.js** + **Express** - Web server
- **Socket.IO** - WebSocket communication for signaling
- **QRCode** - QR code generation

### Mobile App
- **Flutter** - Cross-platform mobile framework
- **flutter_webrtc** - WebRTC implementation
- **qr_code_scanner** - QR code scanning
- **socket_io_client** - WebSocket client
- **google_fonts** - Typography

### PC Receiver
- **Vanilla JavaScript** - Client-side logic
- **WebRTC API** - Peer connection and streaming
- **Modern CSS** - Glassmorphism UI design

## 📂 Project Structure

```
mirror_phone_scan/
├── server/                    # Node.js signaling server
│   ├── index.js              # Server entry point
│   ├── package.json          # Node dependencies
│   └── public/               # Web application
│       ├── index.html        # PC receiver UI
│       ├── style.css         # Styling
│       └── app.js            # Client-side logic
│
├── lib/                       # Flutter application
│   ├── main.dart             # App entry point
│   ├── models/               # Data models
│   │   └── connection_state.dart
│   ├── services/             # Business logic
│   │   ├── socket_service.dart
│   │   ├── webrtc_service.dart
│   │   └── permission_service.dart
│   ├── screens/              # UI screens
│   │   ├── home_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   └── streaming_screen.dart
│   ├── widgets/              # Reusable widgets
│   │   └── custom_button.dart
│   └── utils/                # Constants and utilities
│       └── constants.dart
│
└── android/                   # Android configuration
    └── app/
        ├── build.gradle.kts  # Gradle build file
        └── src/main/
            └── AndroidManifest.xml  # Permissions
```

## 🔧 Configuration

### Changing Server Port

Edit `server/index.js`:
```javascript
const PORT = 3000; // Change to your desired port
```

### WebRTC STUN/TURN Servers

Edit `lib/utils/constants.dart`:
```dart
static final Map<String, dynamic> rtcConfiguration = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    // Add your own TURN servers here
  ],
};
```

## 🐛 Troubleshooting

### App won't connect to server
- Ensure both devices are on the same WiFi network
- Check that the server URL in `constants.dart` matches your PC's IP
- Verify firewall isn't blocking port 3000

### Screen recording permission denied
- Grant permission when prompted
- Go to Settings > Apps > Mirror Phone > Permissions

### QR code won't scan
- Ensure camera permission is granted
- Check lighting conditions
- Clean your camera lens

### Low quality or laggy stream
- Check WiFi signal strength
- Close other network-intensive applications
- Reduce number of devices on the network

## 🎯 Next Steps

- [ ] Add iOS support (requires more complex implementation)
- [ ] Implement recording functionality
- [ ] Add support for audio streaming
- [ ] Create desktop app (instead of web-based receiver)
- [ ] Add support for multiple device connections
- [ ] Implement touch input from PC to mobile
- [ ] Add bandwidth optimization

## 📝 License

MIT License - feel free to use this project for learning or commercial purposes.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- WebRTC implementation by [flutter-webrtc](https://github.com/flutter-webrtc/flutter-webrtc)
- QR scanning by [qr_code_scanner](https://pub.dev/packages/qr_code_scanner)

## 📧 Support

If you encounter issues or have questions:
1. Check the troubleshooting section above
2. Review server logs in terminal
3. Check mobile app logs with `flutter logs`

---

**Made with ❤️ using Flutter and WebRTC**
# screen-sharing-flutter-app
