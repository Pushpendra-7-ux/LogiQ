import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';
  static final Map<String, String> _memCache = {};

  static Future<void> saveToken(String token) async {
    _memCache[_tokenKey] = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorage write error, using memory fallback: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      final val = await _storage.read(key: _tokenKey);
      if (val != null) {
        _memCache[_tokenKey] = val;
        return val;
      }
    } catch (e) {
      debugPrint('SecureStorage read error, using memory fallback: $e');
    }
    return _memCache[_tokenKey];
  }

  static Future<void> deleteToken() async {
    _memCache.remove(_tokenKey);
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('SecureStorage delete error: $e');
    }
  }

  static Future<void> clearAll() async {
    _memCache.clear();
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorage clearAll error: $e');
    }
  }
}