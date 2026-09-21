import 'package:flutter/foundation.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/models/transporter.dart';
import 'package:logiq/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService.instance;

  AdminProvider();

  int activeTenderCount = 0;
  int liveAuctionCount = 0;
  int totalTransporterCount = 0;
  int pendingApprovalCount = 0;

  List<AppUser> registrationRequests = [];
  List<AppUser> pendingUsers = [];
  List<AppUser> approvedUsers = [];
  List<AppUser> rejectedUsers = [];
  List<Transporter> pendingTransporters = [];
  List<Transporter> get transporters => pendingTransporters;
  bool isLoading = false;

  Future<void> loadDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      final stats = await _adminService.getDashboardStats();
      activeTenderCount = stats.activeTenders;
      liveAuctionCount = stats.liveAuctions;
      totalTransporterCount = stats.totalTransporters;
      pendingApprovalCount = stats.pendingApprovals;

      final allUsers = await _adminService.getAllUsers();
      registrationRequests =
          allUsers.where((u) => u.role != AppUser.roleAdmin).toList();

      pendingUsers = registrationRequests
          .where((u) => u.status == AppUser.statusPending)
          .toList();
      approvedUsers = registrationRequests
          .where((u) => u.status == AppUser.statusApproved)
          .toList();
      rejectedUsers = registrationRequests
          .where((u) => u.status == AppUser.statusRejected)
          .toList();

      pendingTransporters =
          await _adminService.getAllTransporters(approvedOnly: false);
    } catch (e) {
      debugPrint('Error loading admin dashboard: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> approveRegistration(int userId) async {
    await _adminService.approveRegistration(userId);
    await loadDashboard();
  }

  Future<void> rejectRegistration(int userId, {String? reason}) async {
    await _adminService.rejectRegistration(userId, reason: reason);
    await loadDashboard();
  }

  Future<void> approveUser(int userId) => approveRegistration(userId);
  Future<void> rejectUser(int userId) => rejectRegistration(userId);

  Future<List<AppUser>> allUsers() async {
    return await _adminService.getAllUsers(role: AppUser.roleUser);
  }

  Future<List<Transporter>> allTransporters() async {
    return await _adminService.getAllTransporters();
  }
}
