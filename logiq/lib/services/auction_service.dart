import '../core/network/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/auction.dart';
import '../models/result.dart';

class AuctionService {
  final DioClient _dio;

  AuctionService({DioClient? dio}) : _dio = dio ?? DioClient();

  Future<Auction> getStatus(int tenderId) async {
    final response = await _dio.get(ApiEndpoints.auctionStatus(tenderId));
    return Auction.fromJson(response.data);
  }

  Future<Map<String, dynamic>> submitBid(
    int tenderId,
    double amount,
    int stage,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.submitBid(tenderId),
      data: {
        'amount': amount,
        'stage': stage,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getRanking(int tenderId) async {
    final response = await _dio.get(ApiEndpoints.ranking(tenderId));
    return response.data as Map<String, dynamic>;
  }

  Future<AuctionResult> getResult(int tenderId) async {
    final response = await _dio.get(ApiEndpoints.auctionResult(tenderId));
    return AuctionResult.fromJson(response.data);
  }

  Future<void> startStage1(int tenderId) async {
    await _dio.post(ApiEndpoints.startStage1(tenderId));
  }

  Future<void> completeStage1(int tenderId) async {
    await _dio.post(ApiEndpoints.completeStage1(tenderId));
  }

  Future<void> startStage2(int tenderId) async {
    await _dio.post(ApiEndpoints.startStage2(tenderId));
  }

  Future<void> completeStage2(int tenderId) async {
    await _dio.post(ApiEndpoints.completeStage2(tenderId));
  }
}