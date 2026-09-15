import '../core/network/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/tender.dart';

class TenderService {
  final _dio = DioClient();

  Future<List<Tender>> getTenders() async {
    final r = await _dio.get(ApiEndpoints.tenders);
    return _parseTenderList(r.data);
  }

  Future<Tender> createTender(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiEndpoints.tenders, data: data);
    return _parseTender(r.data);
  }

  Future<Tender> updateTender(int id, Map<String, dynamic> data) async {
    final r = await _dio.put(ApiEndpoints.tenderById(id), data: data);
    return _parseTender(r.data);
  }

  Future<Map<String, dynamic>> publishTender(int id) async {
    final r = await _dio.post(ApiEndpoints.publishTender(id));
    return _parseMap(r.data);
  }

  Future<Tender> getTenderById(int id) async {
    final r = await _dio.get(ApiEndpoints.tenderById(id));
    return _parseTender(r.data);
  }

  Future<List<Tender>> getDrafts() async {
    final r = await _dio.get(ApiEndpoints.draftTenders);
    return _parseTenderList(r.data);
  }

  Future<List<Tender>> getHistory() async {
    final r = await _dio.get(ApiEndpoints.tenderHistory);
    return _parseTenderList(r.data);
  }

  Future<List<Map<String, dynamic>>> getApprovedTransporters() async {
    final r = await _dio.get(ApiEndpoints.approvedTransporters);
    return _parseTransporterList(r.data);
  }

  Future<void> addParticipants(int tenderId, List<int> transporterIds) async {
    await _dio.post(
      ApiEndpoints.tenderParticipants(tenderId),
      data: {'transporter_ids': transporterIds},
    );
  }

  List<Tender> _parseTenderList(dynamic data) {
    if (data is List) {
      return data.map(_parseTender).toList();
    }

    if (data is Map) {
      final tenders = data['tenders'];
      if (tenders is List) {
        return tenders.map(_parseTender).toList();
      }
    }

    return <Tender>[];
  }

  Tender _parseTender(dynamic data) {
    if (data is Map) {
      final tender = data['tender'];
      if (tender is Map) {
        return Tender.fromJson(Map<String, dynamic>.from(tender));
      }

      return Tender.fromJson(Map<String, dynamic>.from(data));
    }

    throw StateError('Invalid tender response.');
  }

  List<Map<String, dynamic>> _parseTransporterList(dynamic data) {
    if (data is List) {
      return data.map(_parseMap).toList();
    }

    if (data is Map) {
      final transporters = data['transporters'];
      if (transporters is List) {
        return transporters.map(_parseMap).toList();
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }
}