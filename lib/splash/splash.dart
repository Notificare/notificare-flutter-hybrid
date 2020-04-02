import 'package:demo_flutter/utils/asset_loader.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Splash extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final _notificare = NotificarePushLib();

  @override
  void initState() {
    super.initState();

    _notificare.onEventReceived.listen((NotificareEvent event) {
      if (event.name != 'ready') return;

      _fetchConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Splash'),
      ),
    );
  }

  void _fetchConfig() async {
    debugPrint('Fetching configuration assets.');

    try {
      final assets = await _notificare.fetchAssets("CONFIG");
      if (assets.isEmpty) {
        debugPrint(
            'The Notificare app is not correctly configured. Missing the CONFIG asset group and/or demoSourceConfig.json');
      }

      final config = await AssetLoader.fetchDemoSourceConfig(assets.last.assetUrl);
      debugPrint('useLocationServices: ${config.config.useLocationServices}');
    } catch (err) {
      debugPrint('Failed to fetch the configuration assets: $err');
    }
  }
}
