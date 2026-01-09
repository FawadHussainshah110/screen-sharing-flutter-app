import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  IO.Socket? _socket;
  final String serverUrl;

  // Event controllers
  final _connectedController = StreamController<bool>.broadcast();
  final _offerController = StreamController<Map<String, dynamic>>.broadcast();
  final _answerController = StreamController<Map<String, dynamic>>.broadcast();
  final _iceCandidateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _peerDisconnectedController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Stream getters
  Stream<bool> get onConnected => _connectedController.stream;
  Stream<Map<String, dynamic>> get onOffer => _offerController.stream;
  Stream<Map<String, dynamic>> get onAnswer => _answerController.stream;
  Stream<Map<String, dynamic>> get onIceCandidate =>
      _iceCandidateController.stream;
  Stream<void> get onPeerDisconnected => _peerDisconnectedController.stream;
  Stream<String> get onError => _errorController.stream;

  SocketService({required this.serverUrl});

  // Connect to server
  void connect() {
    try {
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      // Connection events
      _socket!.onConnect((_) {
        print('✅ Connected to server');
        _connectedController.add(true);
      });

      _socket!.onDisconnect((_) {
        print('❌ Disconnected from server');
        _connectedController.add(false);
      });

      _socket!.onConnectError((error) {
        print('❌ Connection error: $error');
        _errorController.add('Connection error: $error');
      });

      // Session events
      _socket!.on('joined-session', (data) {
        print('✅ Joined session: $data');
      });

      // WebRTC signaling events
      _socket!.on('offer', (data) {
        print('📡 Received offer');
        _offerController.add(data as Map<String, dynamic>);
      });

      _socket!.on('answer', (data) {
        print('📡 Received answer');
        _answerController.add(data as Map<String, dynamic>);
      });

      _socket!.on('ice-candidate', (data) {
        print('🧊 Received ICE candidate');
        _iceCandidateController.add(data as Map<String, dynamic>);
      });

      _socket!.on('peer-disconnected', (_) {
        print('👋 Peer disconnected');
        _peerDisconnectedController.add(null);
      });

      _socket!.on('error', (data) {
        print('❌ Socket error: $data');
        _errorController.add(data['message'] ?? 'Unknown error');
      });
    } catch (e) {
      print('❌ Socket connection error: $e');
      _errorController.add('Failed to connect: $e');
    }
  }

  // Join session
  void joinSession(String sessionId, String deviceType) {
    _socket?.emit('join-session', {
      'sessionId': sessionId,
      'deviceType': deviceType,
    });
  }

  // Send WebRTC offer
  void sendOffer(String sessionId, Map<String, dynamic> offer) {
    _socket?.emit('offer', {'sessionId': sessionId, 'offer': offer});
  }

  // Send WebRTC answer
  void sendAnswer(String sessionId, Map<String, dynamic> answer) {
    _socket?.emit('answer', {'sessionId': sessionId, 'answer': answer});
  }

  // Send ICE candidate
  void sendIceCandidate(
    String sessionId,
    Map<String, dynamic> candidate,
    String target,
  ) {
    _socket?.emit('ice-candidate', {
      'sessionId': sessionId,
      'candidate': candidate,
      'target': target,
    });
  }

  // Leave session
  void leaveSession(String sessionId) {
    _socket?.emit('leave-session', {'sessionId': sessionId});
  }

  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Cleanup
  void dispose() {
    disconnect();
    _connectedController.close();
    _offerController.close();
    _answerController.close();
    _iceCandidateController.close();
    _peerDisconnectedController.close();
    _errorController.close();
  }
}
