import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isDisposed = false;
  int _reconnectAttempts = 0;
  int? _currentTenderId;
  int? get currentTenderId => _currentTenderId;

  static const int _maxReconnectAttempts = 10;

  Future<void> connect(int tenderId) async {
    if (_isDisposed) return;
    if (_isConnected && _currentTenderId == tenderId) return;

    _currentTenderId = tenderId;
    _reconnectTimer?.cancel();
    await _cleanupChannel();

    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      _setConnected(false);
      return;
    }
    if (_isDisposed || _currentTenderId != tenderId) return;

    final url = '${AppConstants.wsBaseUrl}/ws/auction/$tenderId?token=$token';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _setConnected(true);
      _reconnectAttempts = 0;
      _startPing();

      _subscription = _channel!.stream.listen(
        _handleData,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleData(dynamic data) {
    if (_isDisposed || _controller.isClosed) return;
    try {
      final String raw = data is String ? data : data.toString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _controller.add(decoded);
      } else if (decoded is Map) {
        _controller.add(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  void _handleDisconnect() {
    if (_isDisposed) return;
    _setConnected(false);
    _stopPing();
    _cleanupChannel();
    _scheduleReconnect();
  }

  void _setConnected(bool value) {
    if (_isDisposed) return;
    if (_isConnected == value) return;
    _isConnected = value;
    if (!_connectionController.isClosed) {
      _connectionController.add(value);
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _isDisposed) return;
    final tenderId = _currentTenderId;
    if (tenderId == null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    final seconds = (_reconnectAttempts * 2).clamp(2, 30);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!_isDisposed && _currentTenderId == tenderId && !_isConnected) {
        connect(tenderId);
      }
    });
  }

  bool send(Map<String, dynamic> payload) {
    if (!_isConnected || _channel == null) return false;
    try {
      _channel!.sink.add(jsonEncode(payload));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool sendRaw(String message) {
    if (!_isConnected || _channel == null) return false;
    try {
      _channel!.sink.add(message);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendRaw('{"type":"ping"}');
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _cleanupChannel() async {
    _stopPing();
    try {
      await _subscription?.cancel();
    } catch (_) {}
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _currentTenderId = null;
    _reconnectAttempts = 0;
    await _cleanupChannel();
    _setConnected(false);
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _currentTenderId = null;
    _stopPing();
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _subscription = null;
    _isConnected = false;
    if (!_controller.isClosed) _controller.close();
    if (!_connectionController.isClosed) _connectionController.close();
  }
}
