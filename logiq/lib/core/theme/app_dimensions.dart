/// Centralized dimension constants for the LogiQ design system.
/// Designed for transport workers: big touch targets, generous spacing.
class AppDimensions {
  AppDimensions._();

  // Touch targets (minimum 48dp per Material, we go bigger)
  static const double touchTarget = 56.0;
  static const double buttonHeight = 60.0;
  static const double inputHeight = 56.0;
  static const double navBarHeight = 66.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  // Spacing scale (4px base)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Border radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 18.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 100.0;

  // Card dimensions
  static const double cardElevation = 0.0;

  // Bottom sheet
  static const double bottomSheetRadius = 26.0;

  // Animation durations (ms)
  static const int animFast = 150;
  static const int animNormal = 250;
  static const int animSlow = 400;
  static const int animSplash = 2500;
  static const int staggerDelay = 80;
}
