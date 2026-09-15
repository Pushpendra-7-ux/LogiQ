import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/tender_service.dart';
import '../models/tender.dart';
import '../core/network/dio_client.dart';

class TenderProvider extends ChangeNotifier {
  final TenderService _service;

  TenderProvider({TenderService? service}) : _service = service ?? TenderService();

  List<Tender> _tenders = [];
  List<Tender> _drafts = [];
  List<Tender> _history = [];
  Tender? _currentTender;
  bool _isLoading = false;
  String? _error;

  List<Tender> get tenders => List.unmodifiable(_tenders);
  List<Tender> get drafts => List.unmodifiable(_drafts);
  List<Tender> get history => List.unmodifiable(_history);
  Tender? get currentTender => _currentTender;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void setCurrentTender(Tender? tender) {
    _currentTender = tender;
    notifyListeners();
  }

  void clearCurrentTender() {
    _currentTender = null;
    notifyListeners();
  }

  String _resolveError(Object e) {
    if (e is DioException) {
      return DioClient().getErrorMessage(e);
    }
    return e.toString();
  }

  Future<void> fetchTenders() async {
    _setLoading(true);
    try {
      _tenders = await _service.getTenders();
      _setError(null);
    } catch (e) {
      _setError(_resolveError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDrafts() async {
    _setLoading(true);
    try {
      _drafts = await _service.getDrafts();
      _setError(null);
    } catch (e) {
      _setError(_resolveError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchHistory() async {
    _setLoading(true);
    try {
      _history = await _service.getHistory();
      _setError(null);
    } catch (e) {
      _setError(_resolveError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTenderById(int id) async {
    _setLoading(true);
    try {
      _currentTender = await _service.getTenderById(id);
      _setError(null);
    } catch (e) {
      _currentTender = null;
      _setError(_resolveError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<Tender?> createTender(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final tender = await _service.createTender(data);
      _tenders = [..._tenders, tender];
      _setError(null);
      _setLoading(false);
      return tender;
    } catch (e) {
      _setError(_resolveError(e));
      _setLoading(false);
      return null;
    }
  }

  Future<bool> publishTender(int id) async {
    _setLoading(true);
    try {
      await _service.publishTender(id);
      await fetchTenders();
      await fetchDrafts();
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_resolveError(e));
      _setLoading(false);
      return false;
    }
  }

  void removeLocalTender(int id) {
    _tenders = _tenders.where((t) => t.id != id).toList();
    _drafts = _drafts.where((t) => t.id != id).toList();
    if (_currentTender?.id == id) {
      _currentTender = null;
    }
    notifyListeners();
  }

  void reset() {
    _tenders = [];
    _drafts = [];
    _history = [];
    _currentTender = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
