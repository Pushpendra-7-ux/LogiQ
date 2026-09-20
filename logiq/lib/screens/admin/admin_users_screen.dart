import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/models/user.dart';
import 'package:logiq/models/transporter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  List<Transporter> _transporters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        Haptics.selection();
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final adminProv = context.read<AdminProvider>();
    
    _users = await adminProv.allUsers();
    _transporters = await adminProv.allTransporters();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserApproval(AppUser user, bool approved) async {
    Haptics.selection();
    final adminProv = context.read<AdminProvider>();
    if (user.id != null) {
      if (approved) {
        await adminProv.approveUser(user.id!);
      } else {
        await adminProv.rejectUser(user.id!);
      }
    }
    if (!mounted) return;
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated for ${user.name}')),
    );
  }

  Future<void> _updateTransporterApproval(Transporter t, bool approved) async {
    Haptics.selection();
    final adminProv = context.read<AdminProvider>();
    if (approved) {
      await adminProv.approveUser(t.userId);
    } else {
      await adminProv.rejectUser(t.userId);
    }
    if (!mounted) return;
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated for ${t.companyName}')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Management', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Transporters'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(),
                _buildTransportersList(),
              ],
            ),
    );
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) return const Center(child: Text('No users found.'));
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: ListTile(
              title: Text(user.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              trailing: Switch(
                value: user.isApproved,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => _updateUserApproval(user, val),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransportersList() {
    if (_transporters.isEmpty) return const Center(child: Text('No transporters found.'));
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transporters.length,
        itemBuilder: (context, index) {
          final t = _transporters[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
            child: ListTile(
              title: Text(t.companyName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('GSTIN: ${t.gstin}', style: AppTextStyles.bodySmall),
              trailing: Switch(
                value: t.isApproved,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => _updateTransporterApproval(t, val),
              ),
            ),
          );
        },
      ),
    );
  }
}
