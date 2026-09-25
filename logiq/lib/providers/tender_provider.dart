import 'package:flutter/foundation.dart';
import 'package:logiq/models/auction.dart';
import 'package:logiq/models/material.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/services/auction_service.dart';
import 'package:logiq/services/tender_service.dart';

class TenderProvider extends ChangeNotifier {
  final TenderService _tenderService = TenderService.instance;
  final AuctionService _auctionService = AuctionService.instance;

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

  List<Tender> get allTenders => List.unmodifiable(_tenders);

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

  Future<void> loadTendersForUser(int userId, {bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      _tenders = await _tenderService.getTendersForUser(userId);
      await _autoPublishExpired(userId);
    } catch (e) {
      error = e.toString();
    }

    if (!silent) {
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadTendersForTransporter(int transporterId, {bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      _tenders = await _tenderService.getTendersForTransporter(transporterId);
    } catch (e) {
      error = e.toString();
    }

    if (!silent) {
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadAllTenders({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      _tenders = await _tenderService.getAllTenders();
    } catch (e) {
      error = e.toString();
    }

    if (!silent) {
      isLoading = false;
    }
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
    DateTime? biddingStart,
    DateTime? biddingEnd,
    bool startNow = true,
    Duration biddingDuration = const Duration(minutes: 3),
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final effectiveStart = startNow ? now : (biddingStart ?? now);
      final effectiveEnd = biddingEnd ?? effectiveStart.add(biddingDuration);
      final hardStop = effectiveEnd.add(const Duration(minutes: 5));
      final publishAt = now.add(const Duration(minutes: 3));
      const status = TenderStatus.pendingPublish;

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
        closingDate: effectiveEnd,
        biddingStart: effectiveStart,
        softEnd: effectiveEnd,
        hardStop: hardStop,
        priceDifference: minDecrement,
        ceilingBid: ceilingBid,
        minDecrement: minDecrement,
        remarks: remarks,
        vehicleType: vehicleType,
        publishAt: publishAt,
        status: status,
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

  Future<bool> publishDraft({
    required int tenderId,
    required int userId,
    bool silent = false,
  }) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      var tender = tenderById(tenderId);
      tender ??= await _tenderService.getTenderById(tenderId);
      if (tender == null) throw Exception('Tender not found');

      final now = DateTime.now();
      final isScheduled = tender.biddingStart.isAfter(now);

      DateTime biddingStart;
      DateTime softEnd;
      DateTime hardStop;
      TenderStatus newStatus;
      AuctionStatus auctionStatus;

      if (isScheduled) {
        biddingStart = tender.biddingStart;
        softEnd = tender.softEnd;
        hardStop = tender.hardStop;
        newStatus = TenderStatus.scheduled;
        auctionStatus = AuctionStatus.scheduled;
      } else {
        final diff = tender.softEnd.difference(tender.biddingStart);
        final duration = diff.inSeconds > 0 ? diff : const Duration(minutes: 3);
        biddingStart = now;
        softEnd = biddingStart.add(duration);
        hardStop = softEnd.add(const Duration(minutes: 5));
        newStatus = TenderStatus.stage1;
        auctionStatus = AuctionStatus.stage1Live;
      }

      await _tenderService.updateStatusAndSchedule(
        tenderId: tenderId,
        status: newStatus,
        biddingStart: biddingStart,
        softEnd: softEnd,
        hardStop: hardStop,
      );

      await _tenderService.createAuctionForTender(
        tenderId: tenderId,
        biddingStart: biddingStart,
        softEnd: softEnd,
        hardStop: hardStop,
        status: auctionStatus,
      );

      await loadTendersForUser(userId);
      return true;
    } catch (e) {
      error = e.toString();
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> startRound2BlindAuction({
    required int tenderId,
    required int userId,
    Duration stage2Duration = const Duration(minutes: 2),
  }) async {
    try {
      await AuctionService.instance.startStage2ForTender(
        tenderId: tenderId,
        stage2Duration: stage2Duration,
      );
      await loadTendersForUser(userId);
      return true;
    } catch (e) {
      debugPrint('Error starting Round 2: $e');
      return false;
    }
  }

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

  Future<void> _autoPublishExpired(int userId) async {
    final expired = _tenders.where((t) => t.shouldAutoPublish).toList();
    for (final t in expired) {
      if (t.id != null) {
        try {
          await publishDraft(tenderId: t.id!, userId: userId, silent: true);
        } catch (e) {
          debugPrint('Auto-publish failed for tender ${t.id}: $e');
        }
      }
    }
  }

  Future<void> checkAutoPublish([
    int? currentUserId,
    String? role,
    int? transporterId,
  ]) async {
    try {
      final all = await _tenderService.getAllTenders();
      final expired = all.where((t) => t.shouldAutoPublish).toList();
      for (final t in expired) {
        if (t.id != null) {
          try {
            await publishDraft(tenderId: t.id!, userId: currentUserId ?? t.createdBy, silent: true);
          } catch (_) {}
        }
      }

      final active = all.where((t) =>
          t.status == TenderStatus.scheduled ||
          t.status == TenderStatus.stage1 ||
          t.status == TenderStatus.stage2).toList();
      for (final t in active) {
        if (t.id != null) {
          try {
            await _auctionService.checkAndTransitionAuction(t.id!);
          } catch (_) {}
        }
      }

      if (role == 'admin') {
        await loadAllTenders(silent: true);
      } else if (role == 'transporter' && transporterId != null) {
        await loadTendersForTransporter(transporterId, silent: true);
      } else if (currentUserId != null && role != 'admin' && role != 'transporter') {
        await loadTendersForUser(currentUserId, silent: true);
      }
    } catch (_) {}
  }
}
