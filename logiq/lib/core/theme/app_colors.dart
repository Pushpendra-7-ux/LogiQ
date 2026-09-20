import 'package:flutter/material.dart';

/// LogiQ design tokens — Google Stitch Enterprise Logistics design system.
class AppColors {
  AppColors._();

  // Legacy mappings - remapped to Google Stitch palette to eliminate yellow
  static const Color yellow = electricBlue; // Remapped from yellow to Electric Blue
  static const Color yellowDeep = navy; // Remapped from yellowDeep to Deep Navy
  static const Color yellowSoft = electricBlueLight; // Remapped from yellowSoft to Electric Blue Light
  static const Color ink = navy; // primary text on light surfaces
  static const Color inkSoft = slate;
  static const Color inkFaint = Color(0xFF94A3B8);

  // Surfaces
  static const Color white = Colors.white;
  static const Color background = Color(0xFFF8FAFC); // Cool slate off-white background
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFE2E8F0);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  // Common aliases — Enterprise Logistics
  static const Color primary = navy; // Deep Navy primary action color
  static const Color primaryBlue = electricBlue; // Electric Blue brand accent
  static const Color textPrimary = navy;
  static const Color textSecondary = slate;
  static const Color border = cardBorder;
  static const Color divider = cardBorder;

  // Enterprise Logistics Colors (Google Stitch Design System)
  static const Color navy = Color(0xFF0F172A); // Dark navy for buttons and dark contrast surfaces
  static const Color navySurface = Color(0xFF1E293B);
  static const Color electricBlue = Color(0xFF2563EB); // Deep modern electric blue
  static const Color electricBlueLight = Color(0xFFEFF6FF);
  static const Color electricBlueBorder = Color(0xFFBFDBFE);
  static const Color emerald = Color(0xFF059669); // Enterprise green
  static const Color emeraldBright = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);
  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFFF1F5F9);
  static const Color slateFaint = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);

  // Exact Stitch Token Aliases
  static const Color surfaceCanvas = Color(0xFFF8FAFC);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceNavy = Color(0xFF1E293B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color secondary = Color(0xFF2563EB);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color roseAlert = Color(0xFFEF4444);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color blueSoft = Color(0xFFEFF6FF);

  // LogiQ Green Identity — User-side primary palette
  static const Color logiqGreen = Color(0xFF0D6B4A);
  static const Color logiqGreenLight = Color(0xFF10B981);
  static const Color logiqGreenBg = Color(0xFFECFDF5);
  static const Color logiqGreenDark = Color(0xFF064E3B);
  static const Color logiqGreenMuted = Color(0xFF6EE7B7);
  static const Color logiqGreenBorder = Color(0xFFD1FAE5);
}
