import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_utils.dart';

class AnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const AnimatedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  double _scale = 1.0;

  bool get _isDisabled => widget.isLoading || widget.onPressed == null;

  void _onTapDown(TapDownDetails _) {
    if (_isDisabled) return;
    setState(() => _scale = 0.96);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isDisabled) return;
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    if (_scale != 1.0) setState(() => _scale = 1.0);
  }

  void _handlePressed() {
    HapticUtils.light();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isDisabled ? null : _handlePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color ?? AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: (widget.color ?? AppColors.primary).withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
