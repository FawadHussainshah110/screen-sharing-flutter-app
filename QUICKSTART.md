# Quick Start Guide

## ⚡ 3-Step Setup

### 1️⃣ Start Server (PC)
```bash
cd server
npm install
npm start
```
📝 **Note the IP address** shown in terminal (e.g., `192.168.1.100`)

### 2️⃣ Configure Mobile App
1. Open `lib/utils/constants.dart`
2. Update line 8:
   ```dart
   static const String serverUrl = 'http://192.168.1.100:3000'; // Your IP here
   ```

### 3️⃣ Run Mobile App
```bash
flutter pub get
flutter run
```

## 🎯 UsageSteps

1. **PC:** Open browser → `http://localhost:3000` → See QR code
2. **Mobile:** Open app → Tap "Start Mirroring" → Scan QR
3. **Done!** Screen appears on PC ✨

## ⚠️ Important

- ✅ Both devices on **same WiFi**
- ✅ Update server IP in `constants.dart`
- ✅ Grant camera + screen recording permissions

## 🆘 Quick Fixes

| Problem | Solution |
|---------|----------|
| Can't connect | Check WiFi, verify IP in constants.dart |
| QR won't scan | Grant camera permission, check lighting |
| Permission denied | Go to Settings > Apps > Permissions |

---

### Find Your IP Address

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter

**Mac/Linux:**
```bash
ifconfig
```
Look for "inet" under en0 or wlan0

---

📖 **Full documentation:** See [README.md](README.md)
