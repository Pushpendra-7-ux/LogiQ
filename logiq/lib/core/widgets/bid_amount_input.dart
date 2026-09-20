import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/haptics.dart';

class BidAmountInput extends StatefulWidget {
  final double currentAmount;
  final ValueChanged<double> onAmountChanged;
  final double minDecrement;

  const BidAmountInput({
    super.key,
    required this.currentAmount,
    required this.onAmountChanged,
    this.minDecrement = 25,
  });

  @override
  State<BidAmountInput> createState() => _BidAmountInputState();
}

class _BidAmountInputState extends State<BidAmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAmount.toInt().toString());
  }

  @override
  void didUpdateWidget(BidAmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAmount != widget.currentAmount) {
      final newText = widget.currentAmount.toInt().toString();
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decrement(double amount) {
    Haptics.tap();
    final newAmount = widget.currentAmount - amount;
    if (newAmount > 0) {
      widget.onAmountChanged(newAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline, width: 2),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '₹',
                  style: AppTextStyles.h1.copyWith(color: AppColors.inkSoft),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.h1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final amount = double.tryParse(value);
                    if (amount != null && amount > 0) {
                      widget.onAmountChanged(amount);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [25.0, 50.0, 100.0, 500.0].map((amount) {
            return _QuickDecrementChip(
              amount: amount,
              onTap: () => _decrement(amount),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickDecrementChip extends StatefulWidget {
  final double amount;
  final VoidCallback onTap;

  const _QuickDecrementChip({
    required this.amount,
    required this.onTap,
  });

  @override
  State<_QuickDecrementChip> createState() => _QuickDecrementChipState();
}

class _QuickDecrementChipState extends State<_QuickDecrementChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '-₹${widget.amount.toInt()}',
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.danger),
          ),
        ),
      ),
    );
  }
}
