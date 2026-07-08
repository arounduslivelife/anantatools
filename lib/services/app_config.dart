import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';

class AppConfig {
  static const String _filePath = 'ananta_config.json';
  
  static String uiLanguage = 'id';
  static bool translateServices = true;
  static String themeMode = 'system';
  
  // Notifier untuk mengubah tema secara real-time
  static final ValueNotifier<String> themeNotifier = ValueNotifier('system');

  static Future<void> load() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        String jsonStr = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonStr);
        uiLanguage = data['uiLanguage'] ?? 'id';
        translateServices = data['translateServices'] ?? true;
        themeMode = data['themeMode'] ?? 'system';
        themeNotifier.value = themeMode;
      }
    } catch (e) {
      // Abaikan jika gagal baca
    }
  }

  static Future<void> save() async {
    try {
      final file = File(_filePath);
      Map<String, dynamic> data = {
        'uiLanguage': uiLanguage,
        'translateServices': translateServices,
        'themeMode': themeMode,
      };
      await file.writeAsString(jsonEncode(data));
      themeNotifier.value = themeMode;
    } catch (e) {
      // Abaikan jika gagal simpan
    }
  }
}
