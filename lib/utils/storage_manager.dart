import 'dart:convert';
import 'package:demo_flutter/models/demo_source_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  static final _kOnboardingStatus = 'onboarding_status';
  static final _kDemoSourceConfig = 'demo_source_config';
  static final _kCustomScript = 'custom_script';
  static final _kMemberCardTemplate = 'member_card_template';
  static final _kMemberCardSerial = 'member_card_serial';

  static Future<bool> getOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kOnboardingStatus) &&
        prefs.getBool(_kOnboardingStatus)!;
  }

  static Future<bool> setOnboardingStatus(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_kOnboardingStatus, shown);
  }

  static Future<DemoSourceConfig?> getDemoSourceConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonStr = prefs.getString(_kDemoSourceConfig);
    if (jsonStr == null) return null;

    try {
      final value = json.decode(jsonStr);
      return DemoSourceConfig.fromJson(value);
    } catch (err) {
      // The JSON string may have been tampered with.
      // Let's reset it just to play safe.
      await prefs.remove(_kDemoSourceConfig);
      return null;
    }
  }

  static Future<bool> setDemoSourceConfig(DemoSourceConfig value) async {
    final prefs = await SharedPreferences.getInstance();
    final dynamicStuff = value.toJson();
    return prefs.setString(_kDemoSourceConfig, json.encode(dynamicStuff));
  }

  static Future<String?> getCustomScript() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCustomScript);
  }

  static Future<bool> setCustomScript(String value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kCustomScript, value);
  }

  static Future<Map<String, dynamic>?> getMemberCardTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    return jsonDecode(prefs.getString(_kMemberCardTemplate)!);
  }

  static Future<bool> setMemberCardTemplate(
      Map<String, dynamic> template) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kMemberCardTemplate, jsonEncode(template));
  }

  static Future<String?> getMemberCardSerial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kMemberCardSerial);
  }

  static Future<bool> setMemberCardSerial(String memberCardSerial) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_kMemberCardSerial, memberCardSerial);
  }
}
