import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../utils/constants.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  late final SocketService _socketService;
  final WebRTCService _webrtcService = WebRTCService();

  String? sessionId;
  String? serverUrl;
  String statusText = 'Generating QR Code...';
  bool isConnected = false;
  bool isStreaming = false;
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeReceiver();
  }

  Future<void> _initializeReceiver() async {
    try {
      // Initialize remote video renderer
      await _remoteRenderer.initialize();

      // Get server URL (use same server as sender)
      serverUrl = 'http://192.168.1.193:3000'; // TODO: Make this dynamic
      _socketService = SocketService(serverUrl: serverUrl!);

      // Generate session ID
      await _generateSession();

      // Setup socket connection
      _setupSocketConnection();
    } catch (e) {
      print('❌ Initialization error: $e');
      setState(() {
        statusText = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _generateSession() async {
    try {
      // Generate a unique session ID
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      setState(() {
        statusText = 'Waiting for sender to scan...';
      });

      print('✅ Session created: $sessionId');
    } catch (e) {
      print('❌ Error generating session: $e');
      setState(() {
        statusText = 'Failed to generate QR code';
      });
    }
  }

  void _setupSocketConnection() {
    _socketService.connect();

    // Connection status
    _socketService.onConnected.listen((connected) {
      if (connected) {
        print('✅ Connected to server');
        // Join session as PC (receiver)
        _socketService.joinSession(sessionId!, 'pc');
      }
    });

    // Mobile connected
    _socketService.onOffer.listen((data) async {
      print('📡 Received offer from sender');
      setState(() {
        statusText = 'Sender connected, setting up stream...';
        isConnected = true;
      });

      await _handleOffer(data['offer']);
    });

    // ICE candidates
    _socketService.onIceCandidate.listen((data) async {
      if (_webrtcService.peerConnection != null && data['candidate'] != null) {
        try {
          await _webrtcService.addIceCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        } catch (e) {
          print('❌ Error adding ICE candidate: $e');
        }
      }
    });

    // Peer disconnected
    _socketService.onPeerDisconnected.listen((_) {
      setState(() {
        statusText = 'Sender disconnected';
        isConnected = false;
        isStreaming = false;
      });
      _resetConnection();
    });

    // Errors
    _socketService.onError.listen((error) {
      setState(() {
        statusText = 'Error: $error';
      });
    });
  }

  Future<void> _handleOffer(Map<String, dynamic> offer) async {
    try {
      // Initialize peer connection
      await _webrtcService.initializePeerConnection();

      // Set up callbacks
      _webrtcService.onIceCandidate = (RTCIceCandidate candidate) {
        _socketService.sendIceCandidate(
          sessionId!,
          candidate.toMap(),
          'mobile',
        );
      };

      _webrtcService.onAddStream = (MediaStream stream) {
        print('📺 Received remote stream');
        setState(() {
          _remoteRenderer.srcObject = stream;
          isStreaming = true;
          statusText = 'Streaming';
        });
      };

      _webrtcService.onConnectionStateChange = () {
        final state = _webrtcService.getConnectionState();
        print('🔗 Connection state: $state');

        if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _resetConnection();
        }
      };

      // Set remote description
      await _webrtcService.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create answer
      final answer = await _webrtcService.createAnswer();
      if (answer != null) {
        _socketService.sendAnswer(sessionId!, answer.toMap());
        print('📡 Sent answer to sender');
      }
    } catch (e) {
      print('❌ Error handling offer: $e');
      setState(() {
        statusText = 'Failed to establish connection';
      });
    }
  }

  void _resetConnection() {
    _webrtcService.close();
    setState(() {
      _remoteRenderer.srcObject = null;
      isStreaming = false;
      isConnected = false;
      statusText = 'Waiting for sender to scan...';
    });
  }

  void _disconnect() {
    _socketService.leaveSession(sessionId!);
    _resetConnection();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _webrtcService.dispose();
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(child: isStreaming ? _buildVideoView() : _buildQRView()),
    );
  }

  Widget _buildQRView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const Spacer(),

            // Title
            Text(
              'Receive Mirror',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Status
            Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // QR Code
            if (sessionId != null && serverUrl != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: jsonEncode({
                    'sessionId': sessionId,
                    'serverUrl': serverUrl,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  }),
                  version: QrVersions.auto,
                  size: 250,
                ),
              )
            else
              const CircularProgressIndicator(color: AppConstants.primaryColor),

            const SizedBox(height: 40),

            // Session Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Session ID',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sessionId?.substring(0, 8) ?? '-',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ask the sender to scan this QR code to start mirroring',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    return Stack(
      children: [
        // Video
        Center(
          child: RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
        ),

        // Overlay controls
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STREAMING',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Disconnect button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _disconnect,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
