import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/constants.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Expose peer connection for receiver mode
  RTCPeerConnection? get peerConnection => _peerConnection;

  // Callbacks
  Function(RTCIceCandidate)? onIceCandidate;
  Function(MediaStream)? onAddStream;
  Function()? onConnectionStateChange;

  // Initialize peer connection
  Future<void> initializePeerConnection() async {
    try {
      _peerConnection = await createPeerConnection(
        AppConstants.rtcConfiguration,
      );

      // Set up event handlers
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        print('🧊 New ICE candidate: ${candidate.candidate}');
        onIceCandidate?.call(candidate);
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        print('📺 Remote stream added');
        onAddStream?.call(stream);
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        print('🔗 Connection state: $state');
        onConnectionStateChange?.call();
      };

      print('✅ Peer connection created');
    } catch (e) {
      print('❌ Error creating peer connection: $e');
      rethrow;
    }
  }

  // Capture screen (for Android)
  Future<MediaStream?> captureScreen() async {
    try {
      // Use lower quality to prevent encoder overload and dropped frames
      // This fixes the "encoder queue full" issue
      final stream = await navigator.mediaDevices.getDisplayMedia({
        'audio': false,
        'video': {
          'width': {'ideal': 720}, // Reduced from 1080
          'height': {'ideal': 1280}, // Proportional to 720p
          'frameRate': {'ideal': 30, 'max': 30}, // Reduced from 60fps
        },
      });

      _localStream = stream;

      // Add stream to peer connection
      stream.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, stream);
      });

      print('✅ Screen capture started at reduced quality (720p@30fps)');
      return stream;
    } catch (e) {
      print('❌ Error capturing screen: $e');
      return null;
    }
  }

  // Create offer
  Future<RTCSessionDescription?> createOffer() async {
    try {
      RTCSessionDescription description = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(description);
      print('✅ Offer created');
      return description;
    } catch (e) {
      print('❌ Error creating offer: $e');
      return null;
    }
  }

  // Create answer
  Future<RTCSessionDescription?> createAnswer() async {
    try {
      RTCSessionDescription description = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(description);
      print('✅ Answer created');
      return description;
    } catch (e) {
      print('❌ Error creating answer: $e');
      return null;
    }
  }

  // Set remote description
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await _peerConnection!.setRemoteDescription(description);
      print('✅ Remote description set');
    } catch (e) {
      print('❌ Error setting remote description: $e');
      rethrow;
    }
  }

  // Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection!.addCandidate(candidate);
      print('✅ ICE candidate added');
    } catch (e) {
      print('❌ Error adding ICE candidate: $e');
    }
  }

  // Get connection state
  RTCPeerConnectionState? getConnectionState() {
    return _peerConnection?.connectionState;
  }

  // Close connection
  Future<void> close() async {
    try {
      // Stop all tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;
      _localStream = null;

      print('✅ WebRTC connection closed');
    } catch (e) {
      print('❌ Error closing connection: $e');
    }
  }

  // Dispose
  void dispose() {
    close();
  }
}
