import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';
  static const _keyHostIp = 'hostIp';
  static const _keyFcmToken = 'fcmToken';

  static Future<void> setUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, value);
  }

  static Future<void> setPassword(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, value);
  }

  static Future<void> setHostIp(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHostIp, value);
  }

  static Future<void> setFcmToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, value);
  }

  static Future<void> saveCredentials({
    required String username,
    required String password,
    required String hostIp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyUsername, username),
      prefs.setString(_keyPassword, password),
      prefs.setString(_keyHostIp, hostIp),
    ]);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  static Future<String?> getHostIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHostIp);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  static Future<({String? username, String? password, String? hostIp})>
  getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      username: prefs.getString(_keyUsername),
      password: prefs.getString(_keyPassword),
      hostIp: prefs.getString(_keyHostIp),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
