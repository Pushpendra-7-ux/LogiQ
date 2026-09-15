import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class CountdownTimer extends StatelessWidget {
  final int remainingSeconds;
  final double fontSize;

  const CountdownTimer({
    super.key,
    required this.remainingSeconds,
    this.fontSize = 36,
  });

  Color get _color {
    if (remainingSeconds <= 60) return AppColors.timerDanger;
    if (remainingSeconds <= 300) return AppColors.timerWarning;
    return AppColors.timerNormal;
  }

  String get _label {
    if (remainingSeconds <= 0) return 'ENDED';
    return Formatters.timer(remainingSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _label,
        key: ValueKey(remainingSeconds <= 0 ? 'ended' : remainingSeconds),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: _color,
        ),
      ),
    );
  }
}