import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';

class RouteDisplay extends StatelessWidget {
  final String pickup;
  final String drop;
  final bool compact;
  final bool isCorridor;
  final String? originSubtitle;
  final String? destSubtitle;
  final String? distanceText;

  const RouteDisplay({
    super.key,
    required this.pickup,
    required this.drop,
    this.compact = false,
    this.isCorridor = false,
    this.originSubtitle,
    this.destSubtitle,
    this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    if (isCorridor) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origin
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORIGIN',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pickup,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  originSubtitle ?? 'Logistics Center',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Corridor arrow + distance
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        distanceText ?? 'DIRECT ROUTE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.electricBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.electricBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.electricBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: AppColors.electricBlueBorder,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_right_rounded,
                        size: 16,
                        color: AppColors.electricBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DIRECT TRANSIT CORRIDOR',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Destination
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  drop,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  destSubtitle ?? 'Delivery Hub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final textStyle = compact ? AppTextStyles.bodyStrong : AppTextStyles.h3;
    final iconSize = compact ? 20.0 : 28.0;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.success, size: iconSize),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickup,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _Dot(),
              _Dot(),
              Icon(Icons.local_shipping, color: AppColors.inkSoft, size: iconSize * 0.8),
              _Dot(),
              _Dot(),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.danger, size: iconSize),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drop,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.outline,
        shape: BoxShape.circle,
      ),
    );
  }
}
