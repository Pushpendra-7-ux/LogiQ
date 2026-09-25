import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/widgets/empty_state.dart';
import 'package:logiq/core/widgets/tender_card.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/services/auth_service.dart';

class AvailableTendersScreen extends StatefulWidget {
  const AvailableTendersScreen({super.key});

  @override
  State<AvailableTendersScreen> createState() => _AvailableTendersScreenState();
}

class _AvailableTendersScreenState extends State<AvailableTendersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData(silent: false));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = true}) async {
    final auth = context.read<AuthProvider>();
    var tid = auth.currentTransporter?.id;
    if (tid == null && auth.currentUser != null) {
      final profile = await AuthService.instance.ensureTransporterProfile(auth.currentUser!);
      tid = profile?.id;
    }
    if (!mounted) return;
    if (tid != null) {
      await context.read<TenderProvider>().loadTendersForTransporter(tid, silent: silent);
    } else {
      await context.read<TenderProvider>().loadAllTenders(silent: silent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenderProvider = context.watch<TenderProvider>();
    final activeTenders = tenderProvider.activeTenders;

    final filteredTenders = activeTenders.where((t) {
      if (_selectedFilter == 'Round 1 Live' && t.status != TenderStatus.stage1) {
        return false;
      }
      if (_selectedFilter == 'Round 2 Live' && t.status != TenderStatus.stage2) {
        return false;
      }
      if (_selectedFilter == 'Scheduled' && t.status != TenderStatus.scheduled) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(query);
        final matchPickup = t.pickup.toLowerCase().contains(query);
        final matchDrop = t.drop.toLowerCase().contains(query);
        final matchVehicle = t.vehicleType.toLowerCase().contains(query);
        if (!matchTitle && !matchPickup && !matchDrop && !matchVehicle) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Text(
              'Available Tenders',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${filteredTenders.length}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: const TextStyle(fontSize: 13.5, color: AppColors.navy),
                  decoration: InputDecoration(
                    hintText: 'Search route, material, or vehicle...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.slate),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.slate),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceCanvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Round 1 Live', 'Round 2 Live', 'Scheduled'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.navy,
                          ),
                          selectedColor: AppColors.navy,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppColors.navy : AppColors.borderSubtle,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Expanded(
            child: tenderProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : filteredTenders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => _loadData(silent: false),
                        color: AppColors.secondary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(top: 80),
                            child: const EmptyState(
                              icon: Icons.local_shipping_outlined,
                              title: 'No Available Tenders',
                              subtitle: 'No active or scheduled tenders match your current criteria.',
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.secondary,
                        onRefresh: () => _loadData(silent: false),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTenders.length,
                          itemBuilder: (context, index) {
                            final tender = filteredTenders[index];
                            return TenderCard(
                              tender: tender,
                              animationIndex: index,
                              onTap: () => context.push('/tender/${tender.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
