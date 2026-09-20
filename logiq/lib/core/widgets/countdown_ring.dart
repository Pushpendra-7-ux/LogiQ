import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'dart:math' as math;

class CountdownRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final double size;

  const CountdownRing({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.size = 120,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalSeconds > 0 ? (secondsRemaining / totalSeconds).clamp(0.0, 1.0) : 0.0;
    
    Color ringColor = AppColors.success;
    if (secondsRemaining <= 30) {
      ringColor = AppColors.danger;
    } else if (secondsRemaining <= 60) {
      ringColor = AppColors.warning;
    }

    final isPulsing = secondsRemaining <= 30 && secondsRemaining > 0;
    
    Widget timerText = Text(
      _formatTime(secondsRemaining),
      style: AppTextStyles.timer.copyWith(color: AppColors.ink),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              progress: progress,
              color: ringColor,
              backgroundColor: AppColors.outline,
            ),
          ),
          Center(
            child: isPulsing
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 1.0, end: 1.1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (context, val, child) {
                      final scale = secondsRemaining % 2 == 0 ? val : 2.1 - val; 
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: timerText,
                  )
                : timerText,
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.08;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
