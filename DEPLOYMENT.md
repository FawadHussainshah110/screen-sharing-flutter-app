# Mirror Phone Scan - Deployment Guide

## 🚀 Quick Start: Test Across Different Networks

### Option 1: Using ngrok (Fastest - 5 minutes)

Perfect for immediate testing without deploying to cloud!

#### Step 1: Install ngrok

**Mac:**
```bash
brew install ngrok
```

**Windows/Linux:**
Download from https://ngrok.com/download

#### Step 2: Start your server
```bash
# Terminal 1: Start the Node.js server
cd server
npm start
```

#### Step 3: Create public tunnel
```bash
# Terminal 2: Expose server to internet
ngrok http 3000
```

You'll see output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:3000
```

#### Step 4: Update mobile app

Open `lib/utils/constants.dart` and change line 21:
```dart
static const String serverUrl = 'https://abc123.ngrok.io'; // Your ngrok URL
```

#### Step 5: Rebuild and test!
```bash
flutter run
```

Now you can:
- ✅ Mirror from your phone on cellular data
- ✅ View on PC at home
- ✅ Test across different WiFi networks
- ✅ Share with friends anywhere in the world!

> **Note:** Free ngrok URLs change each time you restart. Get a permanent URL with ngrok Pro ($8/month).

---

## ☁️ Option 2: Deploy to Cloud (Production)

### A. Deploy to Railway.app (Recommended)

**Cost:** Free for first $5/month usage

#### Step 1: Push to GitHub
```bash
cd /Users/projectteam/Desktop/my\ projects/mirror_phone_scan
git init
git add .
git commit -m "Initial commit"
git remote add origin YOUR_GITHUB_REPO
git push -u origin main
```

#### Step 2: Deploy to Railway
1. Go to https://railway.app
2. Click "Start a New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository
5. Railway will auto-detect Node.js and deploy!

#### Step 3: Get your URL
- Railway will give you a URL like: `https://mirror-phone-production.up.railway.app`
- Add a custom domain if you want!

#### Step 4: Update mobile app
```dart
// lib/utils/constants.dart
static const String serverUrl = 'https://your-app.railway.app';
```

### B. Deploy to Render.com (Free Tier)

**Cost:** Completely free!

#### Step 1: Push to GitHub (same as above)

#### Step 2: Deploy to Render
1. Go to https://render.com
2. Click "New" → "Web Service"
3. Connect your GitHub repository
4. Settings:
   - **Name:** mirror-phone-server
   - **Root Directory:** `server`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`

#### Step 3: Get your URL
- Render gives you: `https://mirror-phone-server.onrender.com`

#### Step 4: Update mobile app
```dart
static const String serverUrl = 'https://mirror-phone-server.onrender.com';
```

> **Note:** Free Render apps sleep after 15min of inactivity. First connection might be slow.

---

## 🔄 Option 3: Add TURN Servers (Reliability)

TURN servers help WebRTC work through firewalls and NAT. Essential for production!

### Step 1: Sign up for Metered.ca

1. Go to https://www.metered.ca/stun-turn
2. Click "Get Free Account"
3. Create new app
4. Copy your credentials

You'll get:
- Username: e.g., `abc123`
- Credential: e.g., `xyz789secret`

### Step 2: Update Flutter app

`lib/utils/constants.dart` - Uncomment TURN servers (lines 31-45):
```dart
{
  'urls': 'turn:a.relay.metered.ca:80',
  'username': 'abc123',  // Your username
  'credential': 'xyz789secret',  // Your credential
},
{
  'urls': 'turn:a.relay.metered.ca:443',
  'username': 'abc123',
  'credential': 'xyz789secret',
},
{
  'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
  'username': 'abc123',
  'credential': 'xyz789secret',
},
```

### Step 3: Update PC receiver

`server/public/app.js` - Uncomment TURN servers (lines 20-34):
```javascript
{
    urls: 'turn:a.relay.metered.ca:80',
    username: 'abc123',
    credential: 'xyz789secret',
},
{
    urls: 'turn:a.relay.metered.ca:443',
    username: 'abc123',
    credential: 'xyz789secret',
},
{
    urls: 'turn:a.relay.metered.ca:443?transport=tcp',
    username: 'abc123',
    credential: 'xyz789secret',
},
```

### Step 4: Rebuild
```bash
flutter run
```

Now WebRTC will work even through:
- ✅ Strict firewalls
- ✅ Corporate networks
- ✅ Symmetric NAT
- ✅ Any network configuration

**Free Tier:** 50GB/month bandwidth

---

## 📊 Complete Setup (All Options)

For maximum reliability:

1. **Deploy server to Railway/Render** (permanent URL)
2. **Add TURN servers** (Metered.ca for reliability)
3. **Update mobile app** with production URL
4. **Keep ngrok** for quick testing

This gives you:
- ✅ Works from anywhere on internet
- ✅ Reliable through any network
- ✅ Quick testing with ngrok
- ✅ Production-ready deployment

---

## 🔒 Security Recommendations

When making your server public:

### Add to `server/index.js`:

```javascript
// Add rate limiting
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests
});

app.use('/generate-qr', limiter);

// Add authentication (optional)
const sessionPassword = process.env.SESSION_PASSWORD;

app.get('/generate-qr', async (req, res) => {
  // Check password if set
  if (sessionPassword && req.query.password !== sessionPassword) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  // ... rest of code
});
```

Install rate limiting:
```bash
cd server
npm install express-rate-limit
```

---

## 🆘 Troubleshooting

### ngrok URL not working
- Check if ngrok is still running
- Verify URL is exactly copied (including https://)
- Free URLs change on restart

### Cloud deployment failing
- Check build logs in Railway/Render dashboard
- Ensure `package.json` has correct start script
- Verify Node.js version compatibility

### TURN servers not connecting
- Double-check credentials (no extra spaces)
- Test with https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/
- Free tier has bandwidth limits

### Connection timeout
- Check firewall settings
- Verify both devices have internet
- Try adding more STUN servers

---

## 💰 Cost Summary

| Service | Free Tier | Paid Option |
|---------|-----------|-------------|
| ngrok | ✅ Yes (random URL) | $8/mo (static URL) |
| Railway | ✅ $5/mo credit | Pay-as-you-go |
| Render | ✅ Unlimited | $7/mo (no sleep) |
| Metered.ca | ✅ 50GB/month | $1.99/10GB |

**Recommended Free Stack:**
- Railway/Render for server (Free)
- Metered.ca for TURN (Free 50GB)
- **Total: $0/month** for moderate usage!

---

## ✅ Current Status

Your app is now configured with:
- [x] Environment-based PORT (cloud-ready)
- [x] TURN server placeholders (easy to enable)
- [x] Deployment files (Procfile, engines)
- [x] Multiple server URL options
- [x] Comments guiding each option

**Next:** Choose your deployment method and update `serverUrl`!
