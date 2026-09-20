import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/haptics.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/models/tender.dart';
import 'package:logiq/core/widgets/tender_card.dart';

class AdminTendersScreen extends StatefulWidget {
  const AdminTendersScreen({super.key});

  @override
  State<AdminTendersScreen> createState() => _AdminTendersScreenState();
}

class _AdminTendersScreenState extends State<AdminTendersScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenderProvider>().loadAllTenders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenderProv = context.watch<TenderProvider>();
    
    // Derived filtered list logic based on existing provider structure
    List<Tender> filteredTenders = [];
    final all = tenderProv.activeTenders + tenderProv.completedTenders + tenderProv.scheduledTenders; // assuming mock structure
    
    if (_filter == 'All') {
      filteredTenders = all;
    } else if (_filter == 'Active') {
      filteredTenders = tenderProv.activeTenders;
    } else if (_filter == 'Completed') {
      filteredTenders = tenderProv.completedTenders;
    } else if (_filter == 'Cancelled') {
      filteredTenders = all.where((t) => t.status == TenderStatus.cancelled).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Tenders', style: AppTextStyles.h2),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Active'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: tenderProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () => tenderProv.loadAllTenders(),
                    color: AppColors.primary,
                    child: filteredTenders.isEmpty
                        ? const Center(child: Text('No tenders found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredTenders.length,
                            itemBuilder: (context, index) {
                              final tender = filteredTenders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TenderCard(
                                  tender: tender,
                                  bidCount: 0,
                                  animationIndex: index,
                                  onTap: () {
                                    Haptics.light();
                                    // Admin views the same tender detail screen
                                    context.push('/tender/${tender.id}');
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = label;
          });
          Haptics.selection();
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
