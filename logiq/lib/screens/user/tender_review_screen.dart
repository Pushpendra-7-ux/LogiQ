import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../services/tender_service.dart';
import '../../models/tender.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';

class TenderReviewScreen extends StatefulWidget {
  final int tenderId;
  const TenderReviewScreen({super.key, required this.tenderId});
  @override State<TenderReviewScreen> createState() => _TenderReviewScreenState();
}

class _TenderReviewScreenState extends State<TenderReviewScreen> {
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

  Future<void> _publish() async {
    final ok = await context.read<TenderProvider>().publishTender(widget.tenderId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Tender Published Successfully!'), backgroundColor: AppColors.success),
      );
      context.go('/user');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final t = _tender;
    if (t == null) return const Scaffold(body: Center(child: Text('Tender not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Review Tender')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(Formatters.route(t.pickupLocation, t.dropLocation), style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const Divider(height: 24),
                  _RowItem('Delivery Window', Formatters.dateRange(t.deliveryStart, t.deliveryEnd)),
                  _RowItem('Minimum Decrement', Formatters.currency(t.priceDifference)),
                  _RowItem('Status', t.status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Materials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...t.materials.map((m) => Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text('${m.quantity} ${m.unit} — ${m.description}'),
                  subtitle: Text('HSN: ${m.hsnCode ?? "N/A"}'),
                ),
              )),
          const SizedBox(height: 32),
          if (t.status == 'DRAFT')
            ElevatedButton(
              onPressed: _publish,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('PUBLISH TENDER NOW'),
            ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String val;
  const _RowItem(this.label, this.val);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}