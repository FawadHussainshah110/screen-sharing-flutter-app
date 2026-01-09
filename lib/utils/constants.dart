// Import for Color class
import 'package:flutter/material.dart';

class AppConstants {
  // Server Configuration
  // ============================================
  // OPTION 1: Local Network (Same WiFi)
  // static const String serverUrl = 'http://192.168.100.72:3000';

  // OPTION 2: ngrok (For Testing Across Networks)
  // Get your ngrok URL from: https://ngrok.com
  // Run: ngrok http 3000
  // Then paste the https URL here:
  // static const String serverUrl = 'https://YOUR-NGROK-URL.ngrok.io';

  // OPTION 3: Cloud Deployed (Production)
  // static const String serverUrl = 'https://your-app.railway.app';
  // or: 'https://your-app.onrender.com';

  // Currently using:
  static const String serverUrl = 'http://192.168.100.72:3000'; // Change this!

  // WebRTC Configuration
  // ============================================
  static final Map<String, dynamic> rtcConfiguration = {
    'iceServers': [
      // STUN Servers (for discovering public IP addresses)
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},

      // TURN Servers (for NAT traversal - OPTIONAL but recommended)
      // Uncomment and add your credentials from https://www.metered.ca/
      // Free tier: 50GB/month
      // {
      //   'urls': 'turn:a.relay.metered.ca:80',
      //   'username': 'YOUR_METERED_USERNAME',
      //   'credential': 'YOUR_METERED_CREDENTIAL',
      // },
      // {
      //   'urls': 'turn:a.relay.metered.ca:443',
      //   'username': 'YOUR_METERED_USERNAME',
      //   'credential': 'YOUR_METERED_CREDENTIAL',
      // },
      // {
      //   'urls': 'turn:a.relay.metered.ca:443?transport=tcp',
      //   'username': 'YOUR_METERED_USERNAME',
      //   'credential': 'YOUR_METERED_CREDENTIAL',
      // },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
  };

  // Media Constraints
  static final Map<String, dynamic> mediaConstraints = {
    'audio': false,
    'video': {
      'mandatory': {
        'minWidth': '640',
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    },
  };

  // Screen Capture Constraints (Android)
  static final Map<String, dynamic> screenConstraints = {
    'audio': false,
    'video': true,
  };

  // App Theme Colors
  static const primaryColor = Color(0xFF667EEA);
  static const secondaryColor = Color(0xFF764BA2);
  static const backgroundColor = Color(0xFF0F0F23);
  static const cardColor = Color(0xFF1A1A2E);
  static const successColor = Color(0xFF10B981);
  static const errorColor = Color(0xFFEF4444);
  static const warningColor = Color(0xFFF59E0B);

  // Error Messages
  static const String errorCameraPermission =
      'Camera permission is required to scan QR codes';
  static const String errorScreenPermission =
      'Screen recording permission is required for mirroring';
  static const String errorInvalidQR =
      'Invalid QR code. Please scan the QR code from the PC screen';
  static const String errorConnection =
      'Failed to connect to server. Please check your network';
  static const String errorStreaming = 'Failed to start screen mirroring';
}
