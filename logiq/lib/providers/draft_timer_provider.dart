import 'dart:async';
import 'package:flutter/foundation.dart';

class DraftTimerProvider extends ChangeNotifier {
  Timer? _timer;
  final Map<int, DateTime> _publishTimes = {};
  bool _isDisposed = false;

  Map<int, DateTime> get publishTimes => Map.unmodifiable(_publishTimes);

  void registerDraft(int tenderId, DateTime publishAt) {
    _publishTimes[tenderId] = publishAt;
    _ensureTimerRunning();
    notifyListeners();
  }

  void unregisterDraft(int tenderId) {
    _publishTimes.remove(tenderId);
    if (_publishTimes.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  int secondsRemaining(int tenderId) {
    final publishAt = _publishTimes[tenderId];
    if (publishAt == null) return 0;
    final remaining = publishAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  String countdownString(int tenderId) {
    final secs = secondsRemaining(tenderId);
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool isExpired(int tenderId) => secondsRemaining(tenderId) <= 0;

  bool get hasActiveDrafts => _publishTimes.isNotEmpty;

  List<int> get expiredDraftIds => _publishTimes.entries
      .where((e) => DateTime.now().isAfter(e.value))
      .map((e) => e.key)
      .toList();

  void clearExpired(List<int> publishedIds) {
    for (final id in publishedIds) {
      _publishTimes.remove(id);
    }
    if (_publishTimes.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
    notifyListeners();
  }

  void _ensureTimerRunning() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
