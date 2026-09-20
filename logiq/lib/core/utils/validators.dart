class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _phone = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _gstin = RegExp(
      r'^[1-9][0-9][A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email.';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password.';
    if (v.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!_phone.hasMatch(v)) return 'Please enter a valid 10-digit mobile number.';
    return null;
  }

  static String? gstin(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return null;
    if (!_gstin.hasMatch(v)) return 'Please enter a valid GSTIN.';
    return null;
  }

  static String? positiveAmount(String? value, {double minimum = 0}) {
    final v = double.tryParse((value ?? '').trim());
    if (v == null) return 'Please enter a valid amount.';
    if (v <= minimum) return 'Amount must be greater than ₹${minimum.round()}.';
    return null;
  }
}
