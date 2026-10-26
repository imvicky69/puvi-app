import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:path_provider/path_provider.dart';

/// Manages persistent login session for the couple on local storage.
///
/// Ensures that when Puja or Vicky closes or restarts the app,
/// they stay logged into their intimate digital sanctuary.
abstract final class AuthSessionManager {
  static const _fileName = 'auth_session.json';

  /// Returns the saved user name (e.g. 'Vicky' or 'Puja') if a valid session exists.
  static Future<String?> getSavedUser() async {
    try {
      final isTesting = WidgetsBinding.instance.runtimeType.toString().contains(
        'Test',
      );
      if (isTesting) return null;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final dynamic data = json.decode(content);
      if (data is Map<String, dynamic> && data['isLoggedIn'] == true) {
        final userName = data['userName'] as String?;
        if (userName != null && userName.isNotEmpty) {
          return userName;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Saves the active user session persistently.
  static Future<void> saveSession({
    required String userName,
    required String email,
  }) async {
    try {
      final isTesting = WidgetsBinding.instance.runtimeType.toString().contains(
        'Test',
      );
      if (isTesting) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      final payload = {
        'userName': userName,
        'email': email,
        'isLoggedIn': true,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(json.encode(payload));
    } catch (_) {}
  }

  /// Clears the active session when the user explicitly signs out.
  static Future<void> clearSession() async {
    try {
      final isTesting = WidgetsBinding.instance.runtimeType.toString().contains(
        'Test',
      );
      if (isTesting) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
