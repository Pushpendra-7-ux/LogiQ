import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/tender_provider.dart';
import '../../widgets/tender/tender_card.dart';

class DraftTendersScreen extends StatefulWidget {
  const DraftTendersScreen({super.key});
  @override State<DraftTendersScreen> createState() => _DraftTendersScreenState();
}

class _DraftTendersScreenState extends State<DraftTendersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenderProvider>().fetchDrafts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TenderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Draft Tenders')),
      body: tp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tp.drafts.isEmpty
              ? const Center(child: Text('No drafts saved.', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tp.drafts.length,
                  itemBuilder: (ctx, i) => TenderCard(
                    tender: tp.drafts[i],
                    onTap: () => context.push('/user/tender/${tp.drafts[i].id}/review'),
                  ),
                ),
    );
  }
}