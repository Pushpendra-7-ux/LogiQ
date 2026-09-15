import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../widgets/tender/tender_card.dart';

class AuctionHistoryScreen extends StatefulWidget {
  const AuctionHistoryScreen({super.key});
  @override State<AuctionHistoryScreen> createState() => _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends State<AuctionHistoryScreen> {
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
      appBar: AppBar(title: const Text('My Past Auctions')),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tp.history.isEmpty
              ? const Center(child: Text('No auction records found.', style: TextStyle(color: Colors.grey)))
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