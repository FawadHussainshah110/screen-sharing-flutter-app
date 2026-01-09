# Connection Troubleshooting Guide

## Issue: "Connection error: timeout"

### Current Status
- ✅ **Mobile App:** Running successfully
- ✅ **Camera:** Working perfectly  
- ✅ **QR Scanner:** Initializing correctly
- ❌ **Server Connection:** Timing out

### Logs Analysis

From your mobile app logs:
```
I/flutter (23622): ❌ Connection error: timeout
```

This means the app tried to connect to the server but couldn't reach it.

---

## Common Causes & Solutions

### 1. **Different WiFi Networks** (Most Common)

**Problem:** Phone and PC must be on the SAME WiFi network

**Check:**
- PC WiFi network name
- Phone WiFi network name  
- They must match exactly

**Solution:**
```
1. On your phone: Settings → WiFi
2. Check network name
3. On your PC: Check WiFi settings
4. Make sure both show the same network
```

---

### 2. **Incorrect Server IP**

**Current server URL in app:**
```dart
http://192.168.100.72:3000
```

**Verify PC's actual IP:**
```bash
# On Mac:
ifconfig | grep "inet " | grep -v 127.0.0.1

# You should see something like:
inet 192.168.100.72 netmask ...
```

**If IP is different:**
1. Update `lib/utils/constants.dart` line 15
2. Replace with correct IP
3. Run: `flutter run`

---

### 3. **Firewall Blocking Connection**

**Mac Firewall might be blocking port 3000**

**Solution:**
```
1. System Settings → Network → Firewall
2. If enabled, click "Firewall Options"
3. Add "node" to allowed apps
   OR
4. Temporarily disable firewall to test
```

---

### 4. **Server Not Running**

**Check if server is actually running:**
```bash
lsof -i :3000
```

**Should show:**
```
COMMAND   PID    USER
node    16416  projectteam
```

**If nothing shows:**
```bash
cd server
npm start
```

---

### 5. **Phone Using Cellular Data**

**Problem:** Phone switched to mobile data instead of WiFi

**Solution:**
```
1. Phone Settings → WiFi
2. Make sure WiFi is ON and connected
3. Turn off mobile data temporarily
4. Retry connection
```

---

## Quick Diagnostic Steps

### Step 1: Verify Server is Running
```bash
# Check if port 3000 is open
lsof -i :3000

# Expected: Shows node process
```

### Step 2: Check PC's IP Address
```bash
# Get your IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Compare with server URL in constants.dart
```

### Step 3: Test from Phone's Browser

**Before using the app, test connectivity:**

1. On your Samsung phone, open Chrome
2. Go to: `http://192.168.100.72:3000`
3. You should see the QR code page

**If browser works:**
- ✅ Network is fine
- ❌ Issue is in app configuration

**If browser doesn't work:**
- ❌ Network/connectivity issue
- Check WiFi, firewall, IP address

---

## Alternative: Use ngrok (Works on Any Network)

If same-network connection fails, use ngrok:

```bash
# Terminal 1: Keep server running
# Terminal 2: Start ngrok
./setup-ngrok.sh
```

This will:
- Create public URL (works from anywhere)
- Auto-update your app
- Bypass network issues

---

## Expected vs Actual

### What SHOULD Happen:
```
1. App opens → ✅
2. Camera opens → ✅  
3. QR scans → ✅
4. Connects to server → ❌ FAILING HERE
5. WebSocket connects
6. Screen streams
```

### Current Progress:
- Steps 1-3: ✅ **Working**
- Step 4: ❌ **Timeout**

---

## Next Actions

### Option A: Fix Network (Recommended first)
1. Verify both devices on same WiFi
2. Check PC IP matches constants.dart
3. Test in phone's browser first
4. Retry app

### Option B: Use ngrok (Quick alternative)
```bash
./setup-ngrok.sh
flutter run
```

### Option C: Debug Logs
```bash
# Watch server logs while testing
# Look for incoming connections

# On phone, after scanning QR:
flutter logs
```

---

## Server Configuration Check

Your server is configured to run on:
```javascript
const PORT = process.env.PORT || 3000;
```

Make sure it started on port 3000:
```
🚀 Mirror Phone Server Started!
═══════════════════════════════════════════
📡 Server running on: http://192.168.100.72:3000
```

---

## Testing Checklist

Before attempting connection:

- [ ] Server showing "running on..." message
- [ ] PC and phone on same WiFi
- [ ] IP in constants.dart matches PC's IP  
- [ ] Firewall allows node/port 3000
- [ ] Phone browser can access server URL
- [ ] App rebuilt after changing constants.dart

---

## If Still Not Working

Try this systematic approach:

### 1. Simplest Test First
```bash
# On PC terminal:
curl http://localhost:3000/generate-qr

# Should return JSON with sessionId
```

### 2. Local Network Test
```bash
# On phone browser:
http://YOUR_PC_IP:3000

# Should show QR code page
```

### 3. App Connection Test
```bash
# Watch both:
# - Server logs (Terminal 1)
# - App logs (flutter logs)

# While scanning QR code
```

### 4. Use ngrok to Bypass Network
```bash
./setup-ngrok.sh
# Then rebuild app
```

---

## Success Indicators

When working correctly, you'll see:

**Server logs:**
```
✅ New session created: [uuid]
🔌 Client connected: [socket-id]
📱 Mobile joined session: [uuid]
```

**App logs:**
```
I/flutter: Socket Connected
I/flutter: ✅ WebRTC connection established
```

Currently you only see:
```
I/flutter: ❌ Connection error: timeout
```

This means the app can't reach the server at all.

---

## Most Likely Issue

Based on the timeout error, **95% chance it's one of these:**

1. **Different WiFi networks** (50%)
2. **Wrong IP address in constants.dart** (30%)
3. **Firewall blocking** (15%)
4. **Phone using cellular data** (5%)

**Quick fix:**
1. Verify same WiFi
2. Verify correct IP
3. Test in phone browser first
