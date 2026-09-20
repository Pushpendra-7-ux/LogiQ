import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logiq/core/theme/app_colors.dart';

class StitchHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final String roleBadge;
  final VoidCallback? onBack;

  const StitchHeader({
    super.key,
    this.title,
    this.showBack = false,
    this.roleBadge = 'CARRIER',
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button (if enabled) + Logo + Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBack) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.navy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onBack ?? () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
              // LOGIQ Logo Mark
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.trending_up, size: 20, color: AppColors.electricBlue),
                      Positioned(
                        right: 6,
                        top: 7,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (title != null && title!.isNotEmpty) ...[
                Container(width: 1, height: 16, color: AppColors.borderStrong),
                const SizedBox(width: 8),
                Text(
                  title!,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ] else ...[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LOGIQ',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      'FREIGHT TENDER',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Right: Role badge + User profile avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleBadge,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
