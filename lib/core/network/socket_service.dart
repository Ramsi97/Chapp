import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../session/session_manager.dart';
import 'api_constants.dart';

/// Single authenticated WebSocket to the backend.
///
/// - Connects with the JWT as a query param (`/ws?token=...`).
/// - Ref-counts topic subscriptions and re-subscribes on reconnect.
/// - Auto-reconnects with capped exponential backoff.
/// - Exposes a broadcast [events] stream of decoded server events; the data
///   sources filter it (by `chatId` / `userId`) to drive their model streams.
class SocketService {
  SocketService({required SessionManager session}) : _session = session;

  final SessionManager _session;

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  /// topic -> active listener count (ref-counted subscribe/unsubscribe).
  final Map<String, int> _topics = {};

  bool _connected = false;
  bool _manuallyClosed = false;
  int _retry = 0;
  Timer? _reconnectTimer;

  Stream<Map<String, dynamic>> get events => _controller.stream;

  void connect() {
    if (_channel != null || !_session.isLoggedIn) return;
    _manuallyClosed = false;

    final uri = Uri.parse('${ApiConstants.wsUrl}?token=${_session.token}');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _connected = true;
      // Re-assert any topics that were active before a reconnect.
      for (final topic in _topics.keys) {
        _send({'action': 'subscribe', 'topic': topic});
      }
      channel.stream.listen(
        _onData,
        onError: (_) => _onDisconnected(),
        onDone: _onDisconnected,
        cancelOnError: false,
      );
    } catch (_) {
      _connected = false;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    _retry = 0;
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is Map<String, dynamic>) _controller.add(decoded);
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _onDisconnected() {
    _connected = false;
    _channel = null;
    if (!_manuallyClosed) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    _reconnectTimer?.cancel();
    final seconds = (1 << _retry).clamp(1, 30);
    _retry = (_retry + 1).clamp(0, 5);
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {
      // Sink not ready / closed; topics resync on the next (re)connect.
    }
  }

  void subscribe(String topic) {
    final count = _topics[topic] ?? 0;
    _topics[topic] = count + 1;
    if (count == 0 && _connected) {
      _send({'action': 'subscribe', 'topic': topic});
    }
  }

  void unsubscribe(String topic) {
    final count = _topics[topic] ?? 0;
    if (count <= 1) {
      _topics.remove(topic);
      if (_connected) _send({'action': 'unsubscribe', 'topic': topic});
    } else {
      _topics[topic] = count - 1;
    }
  }

  /// Close the socket (e.g. on logout). Clears topics; safe to [connect] again.
  void disconnect() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
    _topics.clear();
    _retry = 0;
  }
}
