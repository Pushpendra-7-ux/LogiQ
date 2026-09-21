import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/providers/admin_provider.dart';
import 'package:logiq/models/user.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final adminProv = context.read<AdminProvider>();
    _users = await adminProv.allUsers();
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
      SnackBar(
        content: Text('Status updated for ${user.name}'),
        backgroundColor: approved ? AppColors.logiqGreen : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      if (!u.isUser) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.companyName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Shipper Accounts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(65),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search shippers by name, company, email...',
                    hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.inkSoft),
                    filled: true,
                    fillColor: AppColors.surfaceCanvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.logiqGreen),
                    ),
                  ),
                ),
              ),
              Container(color: AppColors.outline, height: 1),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.logiqGreen,
              child: filteredUsers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No shipper accounts found.',
                            style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.companyName.isNotEmpty ? user.companyName : user.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (user.companyName.isNotEmpty && user.name != user.companyName) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        user.name,
                                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: user.isApproved,
                                    activeThumbColor: AppColors.white,
                                    activeTrackColor: AppColors.logiqGreen,
                                    onChanged: (val) => _updateUserApproval(user, val),
                                  ),
                                  Text(
                                    user.isApproved ? 'Approved' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: user.isApproved ? AppColors.logiqGreen : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
