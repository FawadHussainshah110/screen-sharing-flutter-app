const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const QRCode = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const os = require('os');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

const PORT = process.env.PORT || 3000;

// Store active sessions
const sessions = new Map();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Get local IP address
function getLocalIPAddress() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Skip internal and non-IPv4 addresses
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return 'localhost';
}

// Generate QR code with session info
app.get('/generate-qr', async (req, res) => {
  try {
    const sessionId = uuidv4();
    const ipAddress = getLocalIPAddress();

    // Store session
    sessions.set(sessionId, {
      id: sessionId,
      createdAt: Date.now(),
      pcSocketId: null,
      mobileSocketId: null,
      connected: false
    });

    // Create connection info object
    const connectionInfo = {
      sessionId,
      serverUrl: `http://${ipAddress}:${PORT}`,
      timestamp: Date.now()
    };

    // Generate QR code
    const qrCodeDataUrl = await QRCode.toDataURL(JSON.stringify(connectionInfo), {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    res.json({
      success: true,
      qrCode: qrCodeDataUrl,
      sessionId,
      serverUrl: connectionInfo.serverUrl
    });

    console.log(`✅ New session created: ${sessionId}`);
    console.log(`📱 Server URL: ${connectionInfo.serverUrl}`);

  } catch (error) {
    console.error('❌ Error generating QR code:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log(`🔌 Client connected: ${socket.id}`);

  // Join session room
  socket.on('join-session', (data) => {
    const { sessionId, deviceType } = data;

    if (!sessions.has(sessionId)) {
      socket.emit('error', { message: 'Invalid session ID' });
      return;
    }

    const session = sessions.get(sessionId);
    socket.join(sessionId);

    if (deviceType === 'pc') {
      session.pcSocketId = socket.id;
      console.log(`💻 PC joined session: ${sessionId}`);
    } else if (deviceType === 'mobile') {
      session.mobileSocketId = socket.id;
      console.log(`📱 Mobile joined session: ${sessionId}`);

      // Notify PC that mobile has connected
      if (session.pcSocketId) {
        io.to(session.pcSocketId).emit('mobile-connected');
      }
    }

    sessions.set(sessionId, session);
    socket.emit('joined-session', { sessionId, deviceType });
  });

  // WebRTC signaling - Forward offer
  socket.on('offer', (data) => {
    const { sessionId, offer } = data;
    const session = sessions.get(sessionId);

    if (session && session.pcSocketId) {
      console.log(`📡 Forwarding offer to PC for session: ${sessionId}`);
      io.to(session.pcSocketId).emit('offer', { offer });
    }
  });

  // WebRTC signaling - Forward answer
  socket.on('answer', (data) => {
    const { sessionId, answer } = data;
    const session = sessions.get(sessionId);

    if (session && session.mobileSocketId) {
      console.log(`📡 Forwarding answer to mobile for session: ${sessionId}`);
      io.to(session.mobileSocketId).emit('answer', { answer });
    }
  });

  // WebRTC signaling - Forward ICE candidate
  socket.on('ice-candidate', (data) => {
    const { sessionId, candidate, target } = data;
    const session = sessions.get(sessionId);

    if (!session) return;

    const targetSocketId = target === 'pc' ? session.pcSocketId : session.mobileSocketId;

    if (targetSocketId) {
      console.log(`🧊 Forwarding ICE candidate to ${target} for session: ${sessionId}`);
      io.to(targetSocketId).emit('ice-candidate', { candidate });
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log(`🔌 Client disconnected: ${socket.id}`);

    // Find and clean up session
    for (const [sessionId, session] of sessions.entries()) {
      if (session.pcSocketId === socket.id) {
        console.log(`💻 PC disconnected from session: ${sessionId}`);
        if (session.mobileSocketId) {
          io.to(session.mobileSocketId).emit('peer-disconnected');
        }
        sessions.delete(sessionId);
      } else if (session.mobileSocketId === socket.id) {
        console.log(`📱 Mobile disconnected from session: ${sessionId}`);
        if (session.pcSocketId) {
          io.to(session.pcSocketId).emit('peer-disconnected');
        }
        session.mobileSocketId = null;
        sessions.set(sessionId, session);
      }
    }
  });

  // Manual disconnect
  socket.on('leave-session', (data) => {
    const { sessionId } = data;
    const session = sessions.get(sessionId);

    if (session) {
      socket.leave(sessionId);

      // Notify the other peer
      if (session.pcSocketId === socket.id && session.mobileSocketId) {
        io.to(session.mobileSocketId).emit('peer-disconnected');
      } else if (session.mobileSocketId === socket.id && session.pcSocketId) {
        io.to(session.pcSocketId).emit('peer-disconnected');
      }
    }
  });
});

// Clean up old sessions (older than 1 hour)
setInterval(() => {
  const now = Date.now();
  const oneHour = 60 * 60 * 1000;

  for (const [sessionId, session] of sessions.entries()) {
    if (now - session.createdAt > oneHour) {
      console.log(`🧹 Cleaning up old session: ${sessionId}`);
      sessions.delete(sessionId);
    }
  }
}, 5 * 60 * 1000); // Run every 5 minutes

// Start server
server.listen(PORT, () => {
  const ipAddress = getLocalIPAddress();
  console.log('\n🚀 Mirror Phone Server Started!');
  console.log('═══════════════════════════════════════════');
  console.log(`📡 Server running on: http://${ipAddress}:${PORT}`);
  console.log(`💻 Open this URL in your PC browser`);
  console.log('═══════════════════════════════════════════\n');
});
