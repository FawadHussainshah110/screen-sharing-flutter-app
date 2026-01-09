import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../utils/constants.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class StreamingScreen extends StatefulWidget {
  final String sessionId;
  final String serverUrl;

  const StreamingScreen({
    super.key,
    required this.sessionId,
    required this.serverUrl,
  });

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen>
    with WidgetsBindingObserver {
  late final SocketService _socketService;
  final WebRTCService _webrtcService = WebRTCService();

  String statusText = 'Initializing...';
  bool isConnected = false;
  bool isStreaming = false;
  bool _isCleaningUp = false;

  // Platform channel for foreground service
  static const platform = MethodChannel(
    'com.example.mirror_phone_scan/screen_capture',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _socketService = SocketService(serverUrl: widget.serverUrl);
    _setupCleanupListener();
    _initializeConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('📱 App lifecycle state changed: $state');

    // Note: We don't stop mirroring when app is backgrounded
    // The foreground service keeps it running
    if (state == AppLifecycleState.detached) {
      print('⚠️ App is being detached - cleanup will be handled by service');
    }
  }

  /// Setup listener for cleanup broadcasts from native side
  void _setupCleanupListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onCleanup') {
        print('🧹 Received cleanup signal from native side');
        await _performCleanup();
      }
    });
  }

  Future<void> _initializeConnection() async {
    try {
      setState(() {
        statusText = 'Connecting to server...';
      });

      // Initialize socket connection first
      _socketService.connect();

      // Set up listeners
      _setupSocketListeners();
      _setupWebRTCCallbacks();

      // Join session
      await Future.delayed(const Duration(seconds: 1));
      _socketService.joinSession(widget.sessionId, 'mobile');
    } catch (e) {
      print('❌ Initialization error: $e');
      _handleError('Failed to initialize: $e');
    }
  }

  Future<void> _startForegroundService() async {
    try {
      await platform.invokeMethod('startForegroundService');
      print('✅ Foreground service started');
    } catch (e) {
      print('❌ Failed to start foreground service: $e');
    }
  }

  Future<void> _stopForegroundService() async {
    try {
      await platform.invokeMethod('stopForegroundService');
      print('✅ Foreground service stopped');
    } catch (e) {
      print('❌ Failed to stop foreground service: $e');
    }
  }

  void _setupSocketListeners() {
    // Connection status
    _socketService.onConnected.listen((connected) {
      if (connected) {
        setState(() {
          isConnected = true;
          statusText = 'Connected! Starting screen capture...';
        });
        _startScreenCapture();
      }
    });

    // Answer from PC
    _socketService.onAnswer.listen((data) async {
      try {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _webrtcService.setRemoteDescription(answer);
        setState(() {
          statusText = 'WebRTC connection established';
          isStreaming = true;
        });
      } catch (e) {
        print('❌ Error handling answer: $e');
        _handleError('Failed to establish WebRTC: $e');
      }
    });

    // ICE candidates from PC
    _socketService.onIceCandidate.listen((data) async {
      try {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _webrtcService.addIceCandidate(candidate);
      } catch (e) {
        print('❌ Error adding ICE candidate: $e');
      }
    });

    // Peer disconnected
    _socketService.onPeerDisconnected.listen((_) {
      _handleDisconnection();
    });

    // Errors
    _socketService.onError.listen((error) {
      _handleError(error);
    });
  }

  void _setupWebRTCCallbacks() {
    _webrtcService.onIceCandidate = (RTCIceCandidate candidate) {
      _socketService.sendIceCandidate(
        widget.sessionId,
        candidate.toMap(),
        'pc',
      );
    };

    _webrtcService.onConnectionStateChange = () {
      final state = _webrtcService.getConnectionState();
      print('🔗 Connection state: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _handleDisconnection();
      }
    };
  }

  Future<void> _startScreenCapture() async {
    try {
      setState(() {
        statusText = 'Starting screen capture...';
      });

      // Create peer connection
      await _webrtcService.initializePeerConnection();

      // Start foreground service IMMEDIATELY before requesting MediaProjection
      // This is required for Android 14+ - the service must be running
      // when MediaProjection is requested
      await _startForegroundService();

      // Additional delay for safety - native side already waits 1 second
      await Future.delayed(const Duration(seconds: 1));

      // Capture screen - this requests MediaProjection permission
      final stream = await _webrtcService.captureScreen();

      if (stream == null) {
        throw Exception('Failed to capture screen');
      }

      setState(() {
        statusText = 'Creating connection...';
      });

      // Create and send offer
      final offer = await _webrtcService.createOffer();
      if (offer == null) {
        throw Exception('Failed to create offer');
      }

      _socketService.sendOffer(widget.sessionId, offer.toMap());

      setState(() {
        statusText = 'Waiting for PC to respond...';
      });
    } catch (e) {
      print('❌ Screen capture error: $e');
      _handleError('Screen capture failed: $e');
    }
  }

  void _handleError(String error) {
    setState(() {
      statusText = 'Error: $error';
      isStreaming = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleDisconnection() {
    setState(() {
      statusText = 'Disconnected';
      isConnected = false;
      isStreaming = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection lost'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Perform comprehensive cleanup of all resources
  Future<void> _performCleanup() async {
    if (_isCleaningUp) {
      print('⚠️ Cleanup already in progress, skipping...');
      return;
    }

    _isCleaningUp = true;
    print('🧹 Starting comprehensive cleanup...');

    try {
      // 1. Leave session on server
      _socketService.leaveSession(widget.sessionId);

      // 2. Close WebRTC connection with timeout
      await _webrtcService.close().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⚠️ WebRTC close timed out');
        },
      );

      // 3. Disconnect socket
      _socketService.disconnect();

      // 4. Stop foreground service
      await _stopForegroundService();

      print('✅ Cleanup completed successfully');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    } finally {
      _isCleaningUp = false;
    }
  }

  Future<void> _stopMirroring() async {
    await _performCleanup();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Perform cleanup synchronously if not already done
    if (!_isCleaningUp) {
      _webrtcService.dispose();
      _socketService.dispose();
      _stopForegroundService();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isStreaming
                          ? [
                              AppConstants.primaryColor,
                              AppConstants.secondaryColor,
                            ]
                          : [Colors.grey.shade600, Colors.grey.shade800],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isStreaming ? Icons.cast_connected : Icons.cast,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Status Text
                Text(
                  statusText,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Session ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
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
                        widget.sessionId.substring(0, 8),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Loading indicator
                if (!isStreaming)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                  ),

                // Streaming indicator
                if (isStreaming)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
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
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'STREAMING',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Stop Button
                ElevatedButton(
                  onPressed: _stopMirroring,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.errorColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stop, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Stop Mirroring',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
