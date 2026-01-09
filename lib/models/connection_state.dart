enum ConnectionStatus { disconnected, connecting, connected, streaming, error }

class ConnectionState {
  final ConnectionStatus status;
  final String? sessionId;
  final String? serverUrl;
  final String? errorMessage;

  ConnectionState({
    required this.status,
    this.sessionId,
    this.serverUrl,
    this.errorMessage,
  });

  factory ConnectionState.initial() {
    return ConnectionState(status: ConnectionStatus.disconnected);
  }

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? sessionId,
    String? serverUrl,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      serverUrl: serverUrl ?? this.serverUrl,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get statusText {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.streaming:
        return 'Streaming';
      case ConnectionStatus.error:
        return 'Error';
    }
  }
}
