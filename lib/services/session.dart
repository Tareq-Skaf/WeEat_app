import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String userId = "";
  static String email = "";
  static String firstName = "";
  static String lastName = "";
  static String displayName = "";
  static String username = "";
  static String tag = "";
  static String handle = "";
  static String avatarUrl = "";
  static String bio = "";

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('email', email);
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('displayName', displayName);
    await prefs.setString('username', username);
    await prefs.setString('tag', tag);
    await prefs.setString('handle', handle);
    await prefs.setString('avatarUrl', avatarUrl);
    await prefs.setString('bio', bio);
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';
    email = prefs.getString('email') ?? '';
    firstName = prefs.getString('firstName') ?? '';
    lastName = prefs.getString('lastName') ?? '';
    displayName = prefs.getString('displayName') ?? '';
    username = prefs.getString('username') ?? '';
    tag = prefs.getString('tag') ?? '';
    handle = prefs.getString('handle') ?? '';
    avatarUrl = prefs.getString('avatarUrl') ?? '';
    bio = prefs.getString('bio') ?? '';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userId = "";
    email = "";
    firstName = "";
    lastName = "";
    displayName = "";
    username = "";
    tag = "";
    handle = "";
    avatarUrl = "";
    bio = "";
  }

  static bool get isLoggedIn => email.isNotEmpty;
}