import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/currency_formatter.dart';

class PriceDisplay extends StatefulWidget {
  final double amount;
  final TextStyle? style;
  final String? prefix;
  final bool showChange;

  const PriceDisplay({
    super.key,
    required this.amount,
    this.style,
    this.prefix,
    this.showChange = false,
  });

  @override
  State<PriceDisplay> createState() => _PriceDisplayState();
}

class _PriceDisplayState extends State<PriceDisplay> {
  Color? _flashColor;

  @override
  void didUpdateWidget(PriceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showChange && oldWidget.amount != widget.amount) {
      setState(() {
        _flashColor = widget.amount > oldWidget.amount ? AppColors.success : AppColors.danger;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _flashColor = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? AppTextStyles.amount;
    final animatedStyle = style.copyWith(color: _flashColor ?? style.color);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final inAnimation = Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation);
        final outAnimation = Tween<Offset>(begin: const Offset(0.0, -0.5), end: Offset.zero).animate(animation);

        if (child.key == ValueKey<double>(widget.amount)) {
          return SlideTransition(position: inAnimation, child: FadeTransition(opacity: animation, child: child));
        } else {
          return SlideTransition(position: outAnimation, child: FadeTransition(opacity: animation, child: child));
        }
      },
      child: Text(
        '${widget.prefix ?? ''}${CurrencyFormatter.format(widget.amount)}',
        key: ValueKey<double>(widget.amount),
        style: animatedStyle,
      ),
    );
  }
}
