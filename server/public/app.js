// DOM Elements
const qrSection = document.getElementById('qrSection');
const videoSection = document.getElementById('videoSection');
const qrPlaceholder = document.getElementById('qrPlaceholder');
const qrCodeImg = document.getElementById('qrCode');
const serverUrlEl = document.getElementById('serverUrl');
const sessionIdEl = document.getElementById('sessionId');
const statusEl = document.getElementById('status');
const statusText = statusEl.querySelector('.status-text');
const remoteVideo = document.getElementById('remoteVideo');
const disconnectBtn = document.getElementById('disconnectBtn');
const fullscreenBtn = document.getElementById('fullscreenBtn');
const videoContainer = document.querySelector('.video-container');
const toast = document.getElementById('toast');

// State
let socket = null;
let peerConnection = null;
let currentSessionId = null;

// WebRTC Configuration - Using Google's public STUN servers + optional TURN
const rtcConfiguration = {
    iceServers: [
        // STUN servers (for discovering public IP)
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' },

        // TURN servers (for NAT traversal - OPTIONAL but recommended)
        // Uncomment and add credentials from https://www.metered.ca/ (50GB free/month)
        // {
        //     urls: 'turn:a.relay.metered.ca:80',
        //     username: 'YOUR_METERED_USERNAME',
        //     credential: 'YOUR_METERED_CREDENTIAL',
        // },
        // {
        //     urls: 'turn:a.relay.metered.ca:443',
        //     username: 'YOUR_METERED_USERNAME',
        //     credential: 'YOUR_METERED_CREDENTIAL',
        // },
        // {
        //     urls: 'turn:a.relay.metered.ca:443?transport=tcp',
        //     username: 'YOUR_METERED_USERNAME',
        //     credential: 'YOUR_METERED_CREDENTIAL',
        // },
    ],
    iceCandidatePoolSize: 10,
};

// Initialize
async function init() {
    try {
        await generateQRCode();
        setupSocketConnection();
    } catch (error) {
        console.error('Initialization error:', error);
        showToast('Failed to initialize. Please refresh the page.', 'error');
    }
}

// Generate QR Code
async function generateQRCode() {
    try {
        const response = await fetch('/generate-qr');
        const data = await response.json();

        if (data.success) {
            currentSessionId = data.sessionId;

            // Display QR code
            qrCodeImg.src = data.qrCode;
            qrCodeImg.style.display = 'block';
            qrPlaceholder.style.display = 'none';

            // Display connection info
            serverUrlEl.textContent = data.serverUrl;
            sessionIdEl.textContent = data.sessionId;

            console.log('QR Code generated successfully');
        } else {
            throw new Error(data.error || 'Failed to generate QR code');
        }
    } catch (error) {
        console.error('QR generation error:', error);
        qrPlaceholder.innerHTML = `
            <p style="color: var(--error);">❌ Failed to generate QR code</p>
            <button onclick="location.reload()" style="padding: 0.5rem 1rem; margin-top: 1rem; cursor: pointer;">
                Retry
            </button>
        `;
    }
}

// Setup Socket.IO Connection
function setupSocketConnection() {
    socket = io();

    socket.on('connect', () => {
        console.log('Connected to server');

        // Join session as PC
        socket.emit('join-session', {
            sessionId: currentSessionId,
            deviceType: 'pc'
        });
    });

    socket.on('joined-session', (data) => {
        console.log('Joined session:', data);
        updateStatus('Waiting for mobile device...', 'waiting');
    });

    socket.on('mobile-connected', () => {
        console.log('Mobile device connected');
        updateStatus('Mobile connected, setting up stream...', 'connecting');
        showToast('Mobile device connected!', 'success');
    });

    socket.on('offer', async ({ offer }) => {
        console.log('Received offer from mobile');
        await handleOffer(offer);
    });

    socket.on('ice-candidate', async ({ candidate }) => {
        console.log('Received ICE candidate');
        if (peerConnection && candidate) {
            try {
                await peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
            } catch (error) {
                console.error('Error adding ICE candidate:', error);
            }
        }
    });

    socket.on('peer-disconnected', () => {
        console.log('Mobile device disconnected');
        updateStatus('Mobile disconnected', 'error');
        showToast('Mobile device disconnected', 'error');
        resetConnection();
    });

    socket.on('error', (data) => {
        console.error('Socket error:', data);
        showToast(data.message || 'Connection error', 'error');
        updateStatus('Connection error', 'error');
    });

    socket.on('disconnect', () => {
        console.log('Disconnected from server');
        updateStatus('Disconnected from server', 'error');
    });
}

// Handle WebRTC Offer
async function handleOffer(offer) {
    try {
        console.log('📡 Handling offer from mobile...');

        // Create peer connection
        peerConnection = new RTCPeerConnection(rtcConfiguration);
        console.log('✅ Peer connection created');

        // Track received tracks to build stream manually if needed
        const receivedTracks = [];

        // Handle incoming tracks - IMPROVED VERSION
        peerConnection.ontrack = (event) => {
            console.log('🎥 Received track:', event.track.kind);
            console.log('   Track ID:', event.track.id);
            console.log('   Track state:', event.track.readyState);
            console.log('   Streams:', event.streams.length);

            receivedTracks.push(event.track);

            // Method 1: Use the stream from the event if available
            if (event.streams && event.streams[0]) {
                console.log('✅ Using stream from event');
                remoteVideo.srcObject = event.streams[0];
                showVideoSection();
                updateStatus('Connected - Streaming', 'connected');
                showToast('Screen mirroring started!', 'success');
            }
            // Method 2: Create a new MediaStream from received tracks
            else {
                console.log('⚠️ No stream in event, creating MediaStream manually');
                const stream = new MediaStream(receivedTracks);
                remoteVideo.srcObject = stream;
                showVideoSection();
                updateStatus('Connected - Streaming', 'connected');
                showToast('Screen mirroring started!', 'success');
            }

            // Add track event listeners for debugging
            event.track.onended = () => {
                console.log('❌ Track ended:', event.track.kind);
            };

            event.track.onmute = () => {
                console.log('🔇 Track muted:', event.track.kind);
            };

            event.track.onunmute = () => {
                console.log('🔊 Track unmuted:', event.track.kind);
            };
        };

        // Handle ICE candidates
        peerConnection.onicecandidate = (event) => {
            if (event.candidate) {
                console.log('🧊 Sending ICE candidate to mobile');
                socket.emit('ice-candidate', {
                    sessionId: currentSessionId,
                    candidate: event.candidate,
                    target: 'mobile'
                });
            } else {
                console.log('✅ ICE gathering complete');
            }
        };

        // Handle ICE gathering state
        peerConnection.onicegatheringstatechange = () => {
            console.log('🧊 ICE gathering state:', peerConnection.iceGatheringState);
        };

        // Handle ICE connection state
        peerConnection.oniceconnectionstatechange = () => {
            console.log('🔗 ICE connection state:', peerConnection.iceConnectionState);

            if (peerConnection.iceConnectionState === 'failed') {
                console.error('❌ ICE connection failed');
                showToast('Connection failed. Please try again.', 'error');
                updateStatus('Connection failed', 'error');
            }
        };

        // Handle connection state
        peerConnection.onconnectionstatechange = () => {
            console.log('🔗 Connection state:', peerConnection.connectionState);

            switch (peerConnection.connectionState) {
                case 'connecting':
                    updateStatus('Connecting...', 'connecting');
                    break;
                case 'connected':
                    console.log('✅ WebRTC connection established');
                    updateStatus('Connected - Streaming', 'connected');
                    break;
                case 'disconnected':
                    console.warn('⚠️ Connection disconnected');
                    updateStatus('Connection lost', 'error');
                    showToast('Connection lost. Attempting to reconnect...', 'error');
                    break;
                case 'failed':
                    console.error('❌ Connection failed');
                    updateStatus('Connection failed', 'error');
                    showToast('Connection failed. Please try again.', 'error');
                    // Auto-reset after failure
                    setTimeout(() => resetConnection(), 3000);
                    break;
                case 'closed':
                    console.log('🔒 Connection closed');
                    resetConnection();
                    break;
            }
        };

        // Set remote description
        console.log('📝 Setting remote description...');
        await peerConnection.setRemoteDescription(new RTCSessionDescription(offer));
        console.log('✅ Remote description set');

        // Create and send answer
        console.log('📝 Creating answer...');
        const answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);
        console.log('✅ Answer created and set as local description');

        socket.emit('answer', {
            sessionId: currentSessionId,
            answer: answer
        });

        console.log('📡 Sent answer to mobile');

    } catch (error) {
        console.error('❌ Error handling offer:', error);
        console.error('Error stack:', error.stack);
        showToast('Failed to establish connection: ' + error.message, 'error');
        updateStatus('Connection failed', 'error');
    }
}

// Show video section
function showVideoSection() {
    qrSection.style.display = 'none';
    videoSection.style.display = 'block';
}

// Reset connection
function resetConnection() {
    if (peerConnection) {
        peerConnection.close();
        peerConnection = null;
    }

    if (remoteVideo.srcObject) {
        remoteVideo.srcObject.getTracks().forEach(track => track.stop());
        remoteVideo.srcObject = null;
    }

    videoSection.style.display = 'none';
    qrSection.style.display = 'block';

    // Generate new QR code
    generateQRCode();

    updateStatus('Waiting for connection...', 'waiting');
}

// Update status
function updateStatus(text, type) {
    statusText.textContent = text;
    statusEl.className = `status ${type}`;
}

// Show toast notification
function showToast(message, type = 'info') {
    toast.textContent = message;
    toast.className = `toast ${type} show`;

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Event Listeners
disconnectBtn.addEventListener('click', () => {
    if (socket) {
        socket.emit('leave-session', { sessionId: currentSessionId });
    }
    resetConnection();
    showToast('Disconnected', 'info');
});

fullscreenBtn.addEventListener('click', () => {
    if (!document.fullscreenElement) {
        videoContainer.requestFullscreen().catch(err => {
            console.error('Error attempting to enable fullscreen:', err);
        });
        videoContainer.classList.add('fullscreen');
    } else {
        document.exitFullscreen();
        videoContainer.classList.remove('fullscreen');
    }
});

// Handle fullscreen change
document.addEventListener('fullscreenchange', () => {
    if (!document.fullscreenElement) {
        videoContainer.classList.remove('fullscreen');
    }
});

// Initialize on page load
window.addEventListener('load', init);

// Add video element event listeners for debugging
remoteVideo.addEventListener('loadedmetadata', () => {
    console.log('📹 Video metadata loaded');
    console.log('   Video dimensions:', remoteVideo.videoWidth, 'x', remoteVideo.videoHeight);
    console.log('   Video duration:', remoteVideo.duration);
});

remoteVideo.addEventListener('loadeddata', () => {
    console.log('📹 Video data loaded');
});

remoteVideo.addEventListener('canplay', () => {
    console.log('✅ Video can play');
});

remoteVideo.addEventListener('playing', () => {
    console.log('▶️ Video is playing');
});

remoteVideo.addEventListener('waiting', () => {
    console.log('⏸️ Video is waiting for data');
});

remoteVideo.addEventListener('stalled', () => {
    console.warn('⚠️ Video playback stalled');
});

remoteVideo.addEventListener('error', (e) => {
    console.error('❌ Video error:', e);
    console.error('   Error code:', remoteVideo.error?.code);
    console.error('   Error message:', remoteVideo.error?.message);
    showToast('Video playback error. Please try again.', 'error');
});

remoteVideo.addEventListener('emptied', () => {
    console.log('📭 Video emptied');
});

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    if (socket) {
        socket.disconnect();
    }
    if (peerConnection) {
        peerConnection.close();
    }
});
