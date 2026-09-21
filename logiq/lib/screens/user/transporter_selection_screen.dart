import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/data/mock/mock_transporters.dart';
import 'package:logiq/models/transporter.dart';

class TransporterSelectionScreen extends StatefulWidget {
  final List<int> initialSelectedIds;

  const TransporterSelectionScreen({
    super.key,
    this.initialSelectedIds = const [],
  });

  @override
  State<TransporterSelectionScreen> createState() => _TransporterSelectionScreenState();
}

class _TransporterSelectionScreenState extends State<TransporterSelectionScreen> {
  late Set<int> _selectedIds;
  List<Transporter> _transporters = [];
  List<Transporter> _filteredTransporters = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  final List<Color> _avatarColors = const [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
    _loadTransporters();
  }

  Future<void> _loadTransporters() async {
    try {
      final tenderProvider = context.read<TenderProvider>();
      final transporters = await tenderProvider.loadApprovedTransporters();
      final enriched = MockTransporters.enrichWithDisplayData(transporters);
      setState(() {
        _transporters = enriched;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransporters = _transporters.where((t) {
        final matchesSearch = _searchQuery.isEmpty ||
            t.companyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.transportCode.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesSearch) return false;

        if (_selectedFilterIndex == 1) {
          return t.rating >= 4.8;
        } else if (_selectedFilterIndex == 2) {
          final fleetNum = int.tryParse(t.fleetSize.replaceAll('+', '')) ?? 0;
          return fleetNum >= 100;
        } else if (_selectedFilterIndex == 3) {
          return t.rating >= 4.8 && t.tripCount >= 2000;
        }
        return true;
      }).toList();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds = _filteredTransporters
          .where((t) => t.id != null)
          .map((t) => t.id!)
          .toSet();
    });
  }

  void _clearAll() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tender Details', style: AppTextStyles.h3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.logiqGreen))
          : Column(
              children: [
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Select Transporters', style: AppTextStyles.h2),
                          const SizedBox(width: 10),
                          _badge('Admin-Approved', AppColors.logiqGreenBg, AppColors.logiqGreen),
                          const SizedBox(width: 8),
                          _badge('${_transporters.length} Total', AppColors.logiqGreenBg, AppColors.logiqGreen),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select verified carrier partners permitted to place bids in this freight tender.',
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        onChanged: (v) {
                          _searchQuery = v;
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search transporters by name, fleet, or ID...',
                          hintStyle: AppTextStyles.bodyMuted.copyWith(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppColors.inkFaint, size: 20),
                          filled: true,
                          fillColor: AppColors.surfaceCanvas,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            borderSide: const BorderSide(color: AppColors.logiqGreen, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 4,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final isSelected = _selectedFilterIndex == index;
                            final labels = [
                              'All (${_transporters.length})',
                              '★ 4.8+ Rated',
                              '100+ Fleet',
                              'Express Lane',
                            ];
                            return GestureDetector(
                              onTap: () {
                                _selectedFilterIndex = index;
                                _applyFilters();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.logiqGreen : AppColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.logiqGreen : AppColors.outline,
                                  ),
                                ),
                                child: Text(
                                  labels[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.white : AppColors.inkSoft,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Showing ${_filteredTransporters.length} approved carriers',
                            style: AppTextStyles.caption.copyWith(color: AppColors.inkFaint),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _selectAll,
                            child: const Text(
                              'Select All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.logiqGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _clearAll,
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredTransporters.length,
                    itemBuilder: (context, index) {
                      final t = _filteredTransporters[index];
                      final isSelected = t.id != null && _selectedIds.contains(t.id);
                      final avatarColor = _avatarColors[index % _avatarColors.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => t.id != null ? _toggleSelection(t.id!) : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.logiqGreenBorder : AppColors.outline,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: avatarColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    t.monogram,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: avatarColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              t.companyName,
                                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (t.transportCode.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.logiqGreenBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                t.transportCode,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.logiqGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                                          const SizedBox(width: 3),
                                          Text(
                                            t.rating.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${t.tripCount} trips',
                                            style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Fleet: ${t.fleetSize}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.logiqGreen : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.logiqGreen : AppColors.outline,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: AppColors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_selectedIds.length} transporters selected',
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Eligible for spot bidding',
                                style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _selectedIds.isEmpty
                              ? null
                              : () => Navigator.pop(context, _selectedIds.toList()),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Confirm Selection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.logiqGreen,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.outline,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
