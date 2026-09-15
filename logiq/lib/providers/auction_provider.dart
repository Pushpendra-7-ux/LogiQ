import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/auction_service.dart';
import '../models/auction.dart';
import '../models/ranking.dart';
import '../models/result.dart';
import '../core/network/websocket_service.dart';
import '../core/network/dio_client.dart';

class AuctionProvider extends ChangeNotifier {
  final AuctionService _service = AuctionService();
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  Timer? _timer;
  Timer? _extendedBannerTimer;
  bool _disposed = false;

  int _stage = 1;
  String _status = '';
  List<RankingEntry> _rankings = [];
  String? _myRank;
  double? _myBid;
  double? _currentL1;
  double? _minimumValidBid;
  int _remainingSeconds = 0;
  bool _isConnected = false;
  bool _isSubmitting = false;
  String? _error;
  String? _bidSuccess;
  bool _auctionExtended = false;
  AuctionResult? _result;
  bool _isLoadingStatus = false;

  int get stage => _stage;
  String get status => _status;
  List<RankingEntry> get rankings => List.unmodifiable(_rankings);
  String? get myRank => _myRank;
  double? get myBid => _myBid;
  double? get currentL1 => _currentL1;
  double? get minimumValidBid => _minimumValidBid;
  int get remainingSeconds => _remainingSeconds;
  bool get isConnected => _isConnected;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get bidSuccess => _bidSuccess;
  bool get auctionExtended => _auctionExtended;
  AuctionResult? get result => _result;
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isLive => _status == 'LIVE' || _status == 'EXTENDED';
  bool get isStage1 => _stage == 1;
  bool get isStage2 => _stage == 2;
  bool get isFinished => _status == 'STAGE_1_COMPLETED' || _status == 'STAGE_2_COMPLETED' || _status == 'WINNER_FINALIZED' || _status == 'COMPLETED' || _status == 'CANCELLED';

  String get formattedRemaining {
    final s = _remainingSeconds < 0 ? 0 : _remainingSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadAuctionStatus(int tenderId) async {
    _isLoadingStatus = true;
    _error = null;
    _safeNotify();
    try {
      final Auction auction = await _service.getStatus(tenderId);
      _stage = auction.stage;
      _status = auction.status;
      _remainingSeconds = auction.remainingSeconds.toInt();
      _error = null;
    } on DioException catch (e) {
      _error = DioClient().getErrorMessage(e);
    } catch (_) {
      _error = 'Failed to load auction status';
    } finally {
      _isLoadingStatus = false;
      _safeNotify();
    }
  }

  void connectWebSocket(int tenderId) {
    disconnectWebSocket(silent: true);
    try {
      _wsService.connect(tenderId);
      _isConnected = true;
    } catch (_) {
      _isConnected = false;
    }
    _wsSub = _wsService.messages.listen(
      _handleMessage,
      onError: (_) {
        _isConnected = false;
        _safeNotify();
      },
      onDone: () {
        _isConnected = false;
        _safeNotify();
      },
    );
    _startCountdown();
    _safeNotify();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        _safeNotify();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      final String? type = msg['type']?.toString();
      switch (type) {
        case 'ranking_update':
          final rawRankings = msg['rankings'];
          if (rawRankings is List) {
            _rankings = rawRankings.whereType<Map<String, dynamic>>().map((r) {
              try {
                return RankingEntry.fromJson(r);
              } catch (_) {
                return null;
              }
            }).whereType<RankingEntry>().toList();
          }
          _currentL1 = (msg['current_l1'] as num?)?.toDouble();
          _minimumValidBid = (msg['minimum_valid_bid'] as num?)?.toDouble();
          if (msg['your_rank'] != null) _myRank = msg['your_rank'].toString();
          if (msg['your_bid'] != null) _myBid = (msg['your_bid'] as num?)?.toDouble();
          final timer = msg['timer'];
          if (timer is Map && timer['remaining_seconds'] is num) {
            _remainingSeconds = (timer['remaining_seconds'] as num).toInt();
            _startCountdown();
          }
          break;
        case 'bid_accepted':
          if (msg['your_bid'] is num) _myBid = (msg['your_bid'] as num).toDouble();
          if (msg['your_rank'] != null) _myRank = msg['your_rank'].toString();
          if (msg['current_l1'] is num) _currentL1 = (msg['current_l1'] as num).toDouble();
          if (msg['minimum_valid_bid'] is num) _minimumValidBid = (msg['minimum_valid_bid'] as num).toDouble();
          break;
        case 'timer_update':
          if (msg['remaining_seconds'] is num) {
            _remainingSeconds = (msg['remaining_seconds'] as num).toInt();
          }
          break;
        case 'auction_extended':
          _auctionExtended = true;
          _status = 'EXTENDED';
          final extMin = (msg['extension_minutes'] as num?)?.toInt() ?? 0;
          if (msg['remaining_seconds'] is num) {
            _remainingSeconds = (msg['remaining_seconds'] as num).toInt();
          } else if (extMin > 0) {
            _remainingSeconds += extMin * 60;
          }
          _startCountdown();
          _extendedBannerTimer?.cancel();
          _extendedBannerTimer = Timer(const Duration(seconds: 5), () {
            _auctionExtended = false;
            _safeNotify();
          });
          break;
        case 'stage_1_complete':
          _status = 'STAGE_1_COMPLETED';
          _stage = 2;
          _timer?.cancel();
          break;
        case 'stage_2_complete':
          _status = 'STAGE_2_COMPLETED';
          _timer?.cancel();
          break;
        case 'winner_finalized':
          _status = 'WINNER_FINALIZED';
          _timer?.cancel();
          break;
        case 'auction_status':
        case 'status_update':
          if (msg['status'] is String) _status = msg['status'] as String;
          if (msg['stage'] is num) _stage = (msg['stage'] as num).toInt();
          if (msg['remaining_seconds'] is num) {
            _remainingSeconds = (msg['remaining_seconds'] as num).toInt();
            _startCountdown();
          }
          break;
        case 'error':
          _error = msg['message']?.toString() ?? 'Auction error';
          break;
        default:
          break;
      }
    } catch (_) {}
    _isConnected = _wsService.isConnected;
    _safeNotify();
  }

  Future<bool> submitBid(int tenderId, double amount) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    _bidSuccess = null;
    _safeNotify();
    try {
      final Map<String, dynamic> data = await _service.submitBid(tenderId, amount, _stage);
      _bidSuccess = data['message']?.toString() ?? 'Bid placed successfully';
      _myBid = amount;
      if (data['your_rank'] != null) _myRank = data['your_rank'].toString();
      if (data['current_l1'] is num) _currentL1 = (data['current_l1'] as num).toDouble();
      if (data['minimum_valid_bid'] is num) _minimumValidBid = (data['minimum_valid_bid'] as num).toDouble();
      _isSubmitting = false;
      _safeNotify();
      return true;
    } on DioException catch (e) {
      _error = DioClient().getErrorMessage(e);
      _isSubmitting = false;
      _safeNotify();
      return false;
    } catch (_) {
      _error = 'Failed to submit bid';
      _isSubmitting = false;
      _safeNotify();
      return false;
    }
  }

  Future<void> loadRanking(int tenderId, int transporterId) async {
    try {
      final Map<String, dynamic> data = await _service.getRanking(tenderId);
      final raw = data['rankings'];
      if (raw is List) {
        _rankings = raw.whereType<Map<String, dynamic>>().map((r) {
          try {
            return RankingEntry.fromJson(r);
          } catch (_) {
            return null;
          }
        }).whereType<RankingEntry>().toList();
      }
      if (data['your_rank'] != null) _myRank = data['your_rank'].toString();
      _myBid = (data['your_bid'] as num?)?.toDouble();
      _currentL1 = (data['current_l1'] as num?)?.toDouble();
      _minimumValidBid = (data['minimum_valid_bid'] as num?)?.toDouble();
      if (data['remaining_seconds'] is num) {
        _remainingSeconds = (data['remaining_seconds'] as num).toInt();
      }
      _safeNotify();
    } catch (_) {}
  }

  Future<void> loadResult(int tenderId) async {
    try {
      _result = await _service.getResult(tenderId);
      _safeNotify();
    } catch (_) {}
  }

  void disconnectWebSocket({bool silent = false}) {
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _wsService.disconnect();
    } catch (_) {}
    _timer?.cancel();
    _isConnected = false;
    if (!silent) _safeNotify();
  }

  void reset() {
    _stage = 1;
    _status = '';
    _rankings = [];
    _myRank = null;
    _myBid = null;
    _currentL1 = null;
    _minimumValidBid = null;
    _remainingSeconds = 0;
    _error = null;
    _bidSuccess = null;
    _auctionExtended = false;
    _result = null;
    _isSubmitting = false;
    _safeNotify();
  }

  void clearBidSuccess() {
    _bidSuccess = null;
    _safeNotify();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  void clearExtended() {
    _auctionExtended = false;
    _extendedBannerTimer?.cancel();
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _wsSub?.cancel();
    _timer?.cancel();
    _extendedBannerTimer?.cancel();
    try {
      _wsService.disconnect();
      _wsService.dispose();
    } catch (_) {}
    super.dispose();
  }
}
