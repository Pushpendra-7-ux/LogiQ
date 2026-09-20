import 'package:flutter/material.dart';
import 'package:logiq/core/theme/app_colors.dart';
import 'package:logiq/core/theme/app_text_styles.dart';
import 'package:logiq/core/utils/haptics.dart';

class BigButton extends StatefulWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  const BigButton({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.textColor,
    this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
      Haptics.tap();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    final Color bgColor = isDisabled
        ? AppColors.cardBorder
        : (widget.color ?? AppColors.navy);
    
    Color fgColor = widget.textColor ?? AppColors.white;
    if (widget.textColor == null) {
      if (widget.color == AppColors.white || widget.color == AppColors.slateLight || widget.color == AppColors.slateFaint) {
        fgColor = AppColors.navy;
      }
    }
    if (isDisabled) {
      fgColor = AppColors.slate;
    }

    final Color effectiveIconColor = widget.iconColor ?? fgColor;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          height: widget.subtitle != null ? 64 : 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: effectiveIconColor, size: widget.subtitle != null ? 22 : 24),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: widget.subtitle != null
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.label,
                                      style: AppTextStyles.button.copyWith(
                                        color: fgColor,
                                        fontSize: 14.5,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.subtitle!,
                                      style: TextStyle(
                                        color: fgColor.withValues(alpha: 0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                )
                              : Text(
                                  widget.label,
                                  style: AppTextStyles.button.copyWith(color: fgColor),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
