import 'dart:convert';
import 'package:demo_flutter/models/demo_source_config.dart';
import 'package:http/http.dart' as http;

class AssetLoader {
  static Future<DemoSourceConfig> fetchDemoSourceConfig(String url) async {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return DemoSourceConfig.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load the demo source config.');
    }
  }

  static Future<String> fetchString(String url) async {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load string from: $url');
    }
  }
}
