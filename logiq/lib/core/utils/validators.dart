class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    if (value.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? gst(String? value) {
    if (value == null || value.isEmpty) return 'GST number is required';
    if (value.length != 15) return 'GST number must be 15 characters';
    return null;
  }

  static String? positiveNumber(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final num? n = num.tryParse(value);
    if (n == null || n <= 0) return 'Enter a valid positive amount';
    return null;
  }
}