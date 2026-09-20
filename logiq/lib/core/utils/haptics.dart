import 'package:flutter/services.dart';

/// Haptics used only at meaningful moments (not every tap).
class Haptics {
  Haptics._();

  static void tap() => HapticFeedback.lightImpact();
  static void bidSubmitted() => HapticFeedback.mediumImpact();
  static void invalid() => HapticFeedback.vibrate();
  static void extended() => HapticFeedback.mediumImpact();
  static void ended() => HapticFeedback.heavyImpact();
  static void winner() => HapticFeedback.heavyImpact();

  // Aliases
  static void light() => tap();
  static void selection() => HapticFeedback.selectionClick();
  static void success() => winner();
  static void error() => invalid();
  static void warning() => invalid();
}
