// lib/services/ws_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../models/telemetry.dart';

enum WsState { disconnected, connecting, connected }

class WsException implements Exception {
  WsException(this.message);
  final String message;
  @override String toString() => 'WsException: $message';
}

class WsService {
  WsService(this._baseUrl, {required this.token});

  String _baseUrl;
  String token; // Bearer token sent as Authorization header on the WS upgrade.

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  // Cancellable reconnect handle. A prior implementation used Future.delayed,
  // which cannot be cancelled — so when the Retry button (or updateUrl, or a
  // state transition) kicked off a fresh _tryConnect, the stale timer would
  // still fire and overwrite _ch/_sub, leaking the Retry-created socket.
  Timer? _reconnectTimer;
  final _ctrl      = StreamController<TelemetryFrame>.broadcast();
  final _stateCtrl = StreamController<WsState>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();

  Stream<TelemetryFrame> get stream => _ctrl.stream;
  Stream<WsState>        get state  => _stateCtrl.stream;
  Stream<String>         get errors => _errorCtrl.stream;

  WsState _state = WsState.disconnected;
  WsState get currentState => _state;
  String? _lastError;
  String? get lastError => _lastError;

  bool _disposed = false;
  int  _retryS   = 2;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 5;

  void updateUrl(String url) {
    _baseUrl = url;
    // disconnect() already cancels any pending _reconnectTimer, so scheduling
    // a new one here uses the same cancellable field. Without this, repeated
    // updateUrl calls (e.g. connection_provider's per-frame state fixups on a
    // flaky link) would stack non-cancellable Future.delayeds, each firing
    // connect() → disconnect() → _tryConnect() and briefly dropping the live
    // connection every ~300 ms.
    disconnect();
    if (_disposed) return;
    _reconnectTimer = Timer(const Duration(milliseconds: 300), () {
      _reconnectTimer = null;
      connect();
    });
  }

  void connect() {
    if (_disposed) return;
    // Close any prior channel/subscription + cancel any pending reconnect
    // timer before starting a fresh attempt, otherwise repeated connect()
    // calls (e.g. the manual Retry button, or state transitions during a
    // reconnect) can leak a WebSocket and a stream subscription that both
    // keep firing in the background.
    disconnect();
    _retryS = 2;
    _consecutiveFailures = 0;
    _tryConnect();
  }

  void _tryConnect() {
    if (_disposed) return;
    _setState(WsState.connecting);

    // Auth is sent via the Authorization: Bearer header on the WebSocket
    // upgrade request. Previously the token was embedded in the URL as
    // ?token=<hex>, which (a) leaked it into every intermediary access
    // log (journalctl, proxies, router logs) and (b) made token rotation
    // pointless because the leaked query string is valid indefinitely.
    // The backend still honors the query-string path for backward
    // compatibility, but this client always uses the header.
    Uri uri;
    try {
      if (_baseUrl.startsWith('https://')) {
        uri = Uri.parse(
          '${_baseUrl.replaceFirst('https://', 'wss://')}/ws/telemetry');
      } else if (_baseUrl.startsWith('http://')) {
        uri = Uri.parse(
          '${_baseUrl.replaceFirst('http://', 'ws://')}/ws/telemetry');
      } else {
        uri = Uri.parse('ws://$_baseUrl/ws/telemetry');
      }
    } catch (e) {
      _handleConnectionError('Invalid URL: $e');
      return;
    }

    try {
      _ch = IOWebSocketChannel.connect(
        uri,
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      _handleConnectionError('Failed to create WebSocket: $e');
      return;
    }

    _sub = _ch!.stream.listen(
      (raw) {
        _retryS = 2;
        _consecutiveFailures = 0;
        _setState(WsState.connected);
        try {
          final j = jsonDecode(raw as String) as Map<String, dynamic>;
          _ctrl.add(TelemetryFrame.fromJson(j));
        } catch (e) {
          // Silently handle malformed JSON - log but don't break connection
          debugPrint('[WsService] Failed to parse telemetry frame: $e');
        }
      },
      onError: (e) {
        _handleConnectionError('WebSocket error: $e');
      },
      onDone:  ()  {
        _handleConnectionError('WebSocket connection closed');
      },
      cancelOnError: true,
    );
  }

  void _handleConnectionError(String error) {
    if (_disposed) return;
    _consecutiveFailures++;
    debugPrint('[WsService] Connection error ($_consecutiveFailures/$_maxConsecutiveFailures): $error');
    _lastError = error;

    // If we've failed too many times consecutively, stop trying to reconnect
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _setState(WsState.disconnected);
      _errorCtrl.add('Telemetry reconnect failed after $_maxConsecutiveFailures attempts.');
      debugPrint('[WsService] Max consecutive failures reached, stopping reconnection attempts');
      return;
    }

    _scheduleReconnect();
  }

  void _setState(WsState s) { _state = s; _stateCtrl.add(s); }

  void _scheduleReconnect() {
    if (_disposed) return;
    _setState(WsState.disconnected);
    // Cancel any in-flight timer first so two overlapping onDone/onError
    // callbacks can't stack up two pending _tryConnect calls.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _retryS), () {
      _reconnectTimer = null;
      _tryConnect();
    });
    _retryS = (_retryS * 2).clamp(2, 30);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _ch?.sink.close();
    _ch = null;
    _setState(WsState.disconnected);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _ctrl.close();
    _stateCtrl.close();
    _errorCtrl.close();
  }
}
