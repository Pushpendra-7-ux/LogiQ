import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/providers/auth_provider.dart';
import 'package:logiq/providers/tender_provider.dart';
import 'package:logiq/providers/draft_timer_provider.dart';
import 'package:logiq/models/tender.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  bool _showSuccessBanner = false;
  Timer? _autoPublishTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndRegisterDrafts());
    _autoPublishTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkAndPublishExpired());
  }

  @override
  void dispose() {
    _autoPublishTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAndRegisterDrafts() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.id == null) return;
    await context.read<TenderProvider>().loadTendersForUser(user!.id!);
    if (!mounted) return;
    final draftTimer = context.read<DraftTimerProvider>();
    for (final draft in context.read<TenderProvider>().pendingPublishTenders) {
      if (draft.id != null && draft.publishAt != null) {
        draftTimer.registerDraft(draft.id!, draft.publishAt!);
      }
    }
  }

  void _checkAndPublishExpired() {
    if (!mounted) return;
    final draftTimer = context.read<DraftTimerProvider>();
    final tenderProvider = context.read<TenderProvider>();
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    for (final draft in tenderProvider.pendingPublishTenders) {
      if (draft.id != null && draftTimer.isExpired(draft.id!)) {
        draftTimer.unregisterDraft(draft.id!);
        tenderProvider.publishDraft(tenderId: draft.id!, userId: userId).then((success) {
          if (mounted && success) {
            setState(() => _showSuccessBanner = true);
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) setState(() => _showSuccessBanner = false);
            });
          }
        });
      }
    }
  }

  void _cancelDraft(Tender draft) {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null && draft.id != null) {
      context.read<DraftTimerProvider>().unregisterDraft(draft.id!);
      context.read<TenderProvider>().cancelDraft(tenderId: draft.id!, userId: userId);
    }
  }

  void _editDraft(Tender draft) {
    context.push('/tender/edit', extra: draft).then((_) {
      if (mounted) _loadAndRegisterDrafts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tenderProvider = context.watch<TenderProvider>();
    context.watch<DraftTimerProvider>();
    final drafts = tenderProvider.pendingPublishTenders;

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text('Draft Tenders', style: AppTextStyles.h2.copyWith(color: AppColors.ink)),
      ),
      body: Column(
        children: [
          if (_showSuccessBanner) _SuccessBanner(onDismiss: () => setState(() => _showSuccessBanner = false)),
          Expanded(
            child: drafts.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: drafts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (_, index) => _DraftCard(
                      draft: drafts[index],
                      onCancel: () => _cancelDraft(drafts[index]),
                      onEdit: () => _editDraft(drafts[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.logiqGreenBg, shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_unread_outlined, size: 48, color: AppColors.logiqGreen),
          ),
          const SizedBox(height: 24),
          const Text('No Drafts', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any tenders pending auto-publish.',
            style: AppTextStyles.bodyMuted.copyWith(color: AppColors.inkFaint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/tender/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.logiqGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Create Tender', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SuccessBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.logiqGreenBorder,
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.logiqGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tender published to active carriers.',
              style: AppTextStyles.body.copyWith(color: AppColors.logiqGreen, fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: AppColors.logiqGreen, size: 16),
          ),
        ],
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  final Tender draft;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  const _DraftCard({required this.draft, required this.onCancel, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final draftTimer = context.watch<DraftTimerProvider>();
    final tenderId = draft.id ?? 0;
    final countdownStr = draftTimer.countdownString(tenderId);
    final secs = draftTimer.secondsRemaining(tenderId);
    const totalSecs = 180;
    final progress = secs > 0 ? secs / totalSecs : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(draft.title, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(8)),
                child: Text('Draft', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Expanded(child: Text(draft.shortRoute, style: AppTextStyles.bodyMuted, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.inkSoft),
              const SizedBox(width: 4),
              Text(draft.vehicleType, style: AppTextStyles.bodyMuted),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.logiqGreenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.logiqGreenBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.logiqGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-publishes in $countdownStr',
                      style: AppTextStyles.labelBold.copyWith(color: AppColors.logiqGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.logiqGreenLight),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.logiqGreen,
                    side: const BorderSide(color: AppColors.logiqGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
