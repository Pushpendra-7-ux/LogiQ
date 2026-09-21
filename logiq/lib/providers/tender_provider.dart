import 'package:flutter/foundation.dart';
import 'package:logiq/core/constants/app_constants.dart';
import 'package:logiq/core/constants/demo_constants.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/services/tender_service.dart';

class TenderProvider extends ChangeNotifier {
  final TenderService _tenderService = TenderService.instance;

  TenderProvider();

  List<Tender> _tenders = [];
  List<Transporter> _approvedTransporters = [];
  bool isLoading = false;
  String? error;

  List<Tender> get tenders => _tenders;
  List<Transporter> get approvedTransporters => _approvedTransporters;

  @visibleForTesting
  void setTendersForTesting(List<Tender> tenders) {
    _tenders = tenders;
    notifyListeners();
  }

  @visibleForTesting
  void addTenderForTesting(Tender tender) {
    _tenders.add(tender);
    notifyListeners();
  }

  Future<List<Transporter>> loadApprovedTransporters() async {
    try {
      _approvedTransporters = await _tenderService.getApprovedTransporters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading approved transporters: $e');
    }
    return _approvedTransporters;
  }

  List<Tender> get activeTenders => _tenders.where((t) =>
      t.status != TenderStatus.draft &&
      t.status != TenderStatus.pendingPublish &&
      t.status != TenderStatus.completed &&
      t.status != TenderStatus.cancelled).toList();

  List<Tender> get completedTenders => _tenders.where((t) =>
      t.status == TenderStatus.completed).toList();

  List<Tender> get scheduledTenders => _tenders.where((t) =>
      t.status == TenderStatus.scheduled).toList();

  List<Tender> get draftTenders => _tenders.where((t) =>
      t.status == TenderStatus.draft || t.status == TenderStatus.pendingPublish).toList();

  List<Tender> get pendingPublishTenders => _tenders.where((t) =>
      t.status == TenderStatus.pendingPublish).toList();

  int get activeTenderCount => activeTenders.length;
  int get draftCount => draftTenders.length;
  int get completedCount => completedTenders.length;

  Future<void> loadTendersForUser(int userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _tenders = await _tenderService.getTendersForUser(userId);
      // Auto-publish any expired pending-publish tenders
      await _autoPublishExpired(userId);
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadTendersForTransporter(int transporterId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _tenders = await _tenderService.getTendersForTransporter(transporterId);
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllTenders() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _tenders = await _tenderService.getAllTenders();
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Tender? tenderById(int id) {
    try {
      return _tenders.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void markTenderCompletedLocally(int tenderId) {
    final index = _tenders.indexWhere((t) => t.id == tenderId);
    if (index != -1) {
      _tenders[index] = _tenders[index].copyWith(status: TenderStatus.completed);
      notifyListeners();
    }
  }

  Future<Tender?> getOrFetchTender(int tenderId) async {
    final cached = tenderById(tenderId);
    if (cached != null) return cached;
    try {
      final fetched = await _tenderService.getTenderById(tenderId);
      if (fetched != null) {
        _tenders.removeWhere((t) => t.id == tenderId);
        _tenders.add(fetched);
        notifyListeners();
      }
      return fetched;
    } catch (e) {
      debugPrint('Error fetching tender $tenderId: $e');
      return null;
    }
  }

  Future<List<MaterialItem>> materialsFor(int tenderId) async {
    return await _tenderService.getMaterials(tenderId);
  }

  Future<List<int>> participantsFor(int tenderId) async {
    return await _tenderService.getParticipantIds(tenderId);
  }

  Future<int> participantCountFor(int tenderId) async {
    return await _tenderService.getParticipantCount(tenderId);
  }

  /// Create a tender as a "Pending Publish" draft with 3-minute countdown.
  /// Returns the tender ID if successful.
  Future<int?> createTenderAsDraft({
    required String title,
    required String pickup,
    required String drop,
    required DateTime deliveryStart,
    required DateTime deliveryEnd,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
    required double ceilingBid,
    required double minDecrement,
    required int createdBy,
    String remarks = '',
    String vehicleType = 'Truck',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final publishAt = now.add(AppConstants.draftCountdownDuration);
      final biddingStart = publishAt;
      final softEnd = biddingStart.add(DemoConstants.stage1Duration);
      final hardStop = softEnd.add(DemoConstants.hardStopBuffer);

      var resolvedTransporterIds = transporterIds;
      if (resolvedTransporterIds.isEmpty) {
        final all = await _tenderService.getApprovedTransporters();
        resolvedTransporterIds = all.where((t) => t.id != null).map((t) => t.id!).toList();
      }

      final newTender = Tender(
        title: title,
        createdBy: createdBy,
        pickup: pickup,
        drop: drop,
        deliveryStart: deliveryStart,
        deliveryEnd: deliveryEnd,
        closingDate: publishAt,
        biddingStart: biddingStart,
        softEnd: softEnd,
        hardStop: hardStop,
        priceDifference: minDecrement,
        ceilingBid: ceilingBid,
        minDecrement: minDecrement,
        remarks: remarks,
        vehicleType: vehicleType,
        publishAt: publishAt,
        status: TenderStatus.pendingPublish,
        createdAt: now,
      );

      final tenderId = await _tenderService.createTender(
        tender: newTender,
        materials: materials,
        transporterIds: resolvedTransporterIds,
        auction: null,
      );

      await loadTendersForUser(createdBy);
      isLoading = false;
      notifyListeners();
      return tenderId;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createTender({
    required String title,
    required String pickup,
    required String drop,
    required DateTime deliveryStart,
    required DateTime deliveryEnd,
    required DateTime closingDate,
    required DateTime biddingStart,
    required DateTime softEnd,
    required DateTime hardStop,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
    required double priceDifference,
    required int createdBy,
    bool isDraft = false,
    double ceilingBid = 75000.0,
    double minDecrement = 500.0,
    String remarks = '',
    String vehicleType = 'Truck',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final status = isDraft ? TenderStatus.draft : TenderStatus.scheduled;

      var resolvedTransporterIds = transporterIds;
      if (resolvedTransporterIds.isEmpty) {
        final all = await _tenderService.getApprovedTransporters();
        resolvedTransporterIds = all.where((t) => t.id != null).map((t) => t.id!).toList();
      }

      final newTender = Tender(
        id: null,
        title: title,
        createdBy: createdBy,
        pickup: pickup,
        drop: drop,
        deliveryStart: deliveryStart,
        deliveryEnd: deliveryEnd,
        closingDate: closingDate,
        biddingStart: biddingStart,
        softEnd: softEnd,
        hardStop: hardStop,
        priceDifference: priceDifference,
        ceilingBid: ceilingBid,
        minDecrement: minDecrement,
        remarks: remarks,
        vehicleType: vehicleType,
        status: status,
        createdAt: now,
      );

      final auctionMap = isDraft
          ? null
          : {
              'current_stage': 1,
              'stage1_start': biddingStart.toIso8601String(),
              'stage1_end': softEnd.toIso8601String(),
              'stage2_start': softEnd.toIso8601String(),
              'stage2_end': hardStop.toIso8601String(),
              'status': 'scheduled',
            };

      await _tenderService.createTender(
        tender: newTender,
        materials: materials,
        transporterIds: resolvedTransporterIds,
        auction: auctionMap,
      );

      await loadTendersForUser(createdBy);
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Publish a pending-publish draft immediately (auto or manual).
  Future<bool> publishDraft({
    required int tenderId,
    required int userId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final tender = tenderById(tenderId);
      if (tender == null) throw Exception('Tender not found');

      final now = DateTime.now();
      final biddingStart = now;
      final softEnd = biddingStart.add(DemoConstants.stage1Duration);
      final hardStop = softEnd.add(DemoConstants.hardStopBuffer);

      // Update tender to scheduled
      await _tenderService.setStatus(tenderId, TenderStatus.scheduled);

      // Create the auction record
      await _tenderService.createAuctionForTender(
        tenderId: tenderId,
        biddingStart: biddingStart,
        softEnd: softEnd,
        hardStop: hardStop,
      );

      await loadTendersForUser(userId);
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel a draft during the 3-minute window.
  Future<bool> cancelDraft({
    required int tenderId,
    required int userId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _tenderService.setStatus(tenderId, TenderStatus.cancelled);
      await loadTendersForUser(userId);
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDraft({
    required int tenderId,
    required Tender tender,
    required List<MaterialItem> materials,
    required List<int> transporterIds,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      var resolvedTransporterIds = transporterIds;
      if (resolvedTransporterIds.isEmpty) {
        final all = await _tenderService.getApprovedTransporters();
        resolvedTransporterIds = all.where((t) => t.id != null).map((t) => t.id!).toList();
      }

      await _tenderService.updateDraft(
        tenderId: tenderId,
        tender: tender,
        materials: materials,
        transporterIds: resolvedTransporterIds,
      );
      await loadTendersForUser(tender.createdBy);
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDraft({
    required int tenderId,
    required int userId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _tenderService.deleteDraft(tenderId);
      await loadTendersForUser(userId);
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Auto-publish all expired pending-publish tenders.
  Future<void> _autoPublishExpired(int userId) async {
    final expired = _tenders.where((t) => t.shouldAutoPublish).toList();
    for (final t in expired) {
      if (t.id != null) {
        try {
          await publishDraft(tenderId: t.id!, userId: userId);
        } catch (e) {
          debugPrint('Auto-publish failed for tender ${t.id}: $e');
        }
      }
    }
  }

  /// Check and auto-publish expired drafts (called by timer).
  Future<void> checkAutoPublish(int userId) async {
    final expired = _tenders.where((t) => t.shouldAutoPublish).toList();
    if (expired.isEmpty) return;

    for (final t in expired) {
      if (t.id != null) {
        try {
          await publishDraft(tenderId: t.id!, userId: userId);
        } catch (e) {
          debugPrint('Auto-publish failed for tender ${t.id}: $e');
        }
      }
    }
  }
}
