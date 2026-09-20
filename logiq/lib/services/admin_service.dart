import 'package:logiq/data/local/local_auction_data_source.dart';
import 'package:logiq/data/local/local_tender_data_source.dart';
import 'package:logiq/data/local/local_user_data_source.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/models/user.dart';

class AdminDashboardStats {
  final int activeTenders;
  final int liveAuctions;
  final int totalTransporters;
  final int pendingApprovals;

  const AdminDashboardStats({
    required this.activeTenders,
    required this.liveAuctions,
    required this.totalTransporters,
    required this.pendingApprovals,
  });
}

/// Service layer abstraction for Admin operations.
/// Providers communicate with this service instead of LocalUserDataSource directly.
/// When REST APIs arrive, only this service will be updated to use DioClient.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final LocalUserDataSource _userDataSource = LocalUserDataSource.instance;
  final LocalTenderDataSource _tenderDataSource = LocalTenderDataSource.instance;
  final LocalAuctionDataSource _auctionDataSource = LocalAuctionDataSource.instance;

  Future<List<AppUser>> getAllUsers({
    String? role,
    String? status,
    bool? approved,
  }) async {
    return await _userDataSource.all(
      role: role,
      status: status,
      approved: approved,
    );
  }

  Future<AppUser?> getUserById(int id) async {
    return await _userDataSource.findById(id);
  }

  Future<void> setApproval(int userId, bool approved) async {
    await _userDataSource.setApproval(userId, approved);
  }

  Future<void> approveRegistration(int userId) async {
    await _userDataSource.setStatus(userId, AppUser.statusApproved);
  }

  Future<void> rejectRegistration(int userId, {String? reason}) async {
    await _userDataSource.setStatus(
      userId,
      AppUser.statusRejected,
      rejectionReason: reason,
    );
  }

  Future<void> deleteUser(int userId) async {
    await _userDataSource.deleteUser(userId);
  }

  Future<List<Transporter>> getAllTransporters({bool approvedOnly = false}) async {
    return await _userDataSource.allCompanies(approvedOnly: approvedOnly);
  }

  Future<Transporter?> getTransporterById(int id) async {
    return await _userDataSource.byId(id);
  }

  Future<Transporter?> getTransporterByUserId(int userId) async {
    return await _userDataSource.byUserId(userId);
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    final tenders = await _tenderDataSource.all();
    final activeTenders = tenders.where((t) => t.status.isActive).length;

    final runningAuctions = await _auctionDataSource.running();
    final liveAuctions = runningAuctions.length;

    final transporters = await _userDataSource.allCompanies();
    final totalTransporters = transporters.length;

    final pendingUsers =
        await _userDataSource.all(status: AppUser.statusPending);
    final pendingApprovals = pendingUsers.length;

    return AdminDashboardStats(
      activeTenders: activeTenders,
      liveAuctions: liveAuctions,
      totalTransporters: totalTransporters,
      pendingApprovals: pendingApprovals,
    );
  }
}
