import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tender_service.dart';
import '../../models/tender.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class TenderDetailScreen extends StatefulWidget {
  final int tenderId;
  const TenderDetailScreen({super.key, required this.tenderId});
  @override State<TenderDetailScreen> createState() => _TenderDetailScreenState();
}

class _TenderDetailScreenState extends State<TenderDetailScreen> {
  Tender? _tender;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await TenderService().getTenderById(widget.tenderId);
      setState(() => _tender = t);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final t = _tender;
    if (t == null) return const Scaffold(body: Center(child: Text('Tender not found')));

    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(t.pickupLocation, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Icon(Icons.arrow_downward, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: AppColors.accent, size: 28),
                        const SizedBox(width: 12),
                        Text(t.dropLocation, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 32),
                    _Item(Icons.inventory_2, 'Load', t.materials.isNotEmpty ? '${t.materials.first.quantity} ${t.materials.first.unit} ${t.materials.first.description}' : 'Transport Load'),
                    const SizedBox(height: 12),
                    _Item(Icons.calendar_today, 'Dates', Formatters.dateRange(t.deliveryStart, t.deliveryEnd)),
                    const SizedBox(height: 12),
                    _Item(Icons.trending_down, 'Min Decrement', Formatters.currency(t.priceDifference)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (t.status.contains('STAGE_2')) {
                    context.push('/auction/${t.id}/stage2');
                  } else {
                    context.push('/auction/${t.id}/stage1');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('BID NOW', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String val;
  const _Item(this.icon, this.label, this.val);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Expanded(child: Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ],
    );
  }
}