import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../widgets/tender/tender_card.dart';

class TenderHistoryScreen extends StatefulWidget {
  const TenderHistoryScreen({super.key});
  @override State<TenderHistoryScreen> createState() => _TenderHistoryScreenState();
}

class _TenderHistoryScreenState extends State<TenderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenderProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TenderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tender History')),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tp.history.isEmpty
              ? const Center(child: Text('No completed tenders in history.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tp.history.length,
                  itemBuilder: (ctx, i) => TenderCard(
                    tender: tp.history[i],
                    onTap: () => context.push('/auction/${tp.history[i].id}/result'),
                  ),
                ),
    );
  }
}