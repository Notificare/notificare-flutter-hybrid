import 'dart:async';

import 'package:demo_flutter/utils/asset_loader.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Splash extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  final _notificare = NotificarePushLib();
  StreamSubscription<NotificareEvent> _notificareSubscription;

  @override
  void initState() {
    super.initState();

    _notificare.setPresentationOptions(['alert']);
    _notificare.launch();

    _notificareSubscription =
        _notificare.onEventReceived.listen((NotificareEvent event) {
      if (event.name != 'ready') return;

      _startup();
    });
  }

  @override
  void dispose() {
    _notificareSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: LimitedBox(
              maxHeight: 100,
              child: Container(
                child: Center(
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startup() async {
    print('Starting up, refresh the local config.');

    await _fetchConfig();
    await _fetchCustomScript();
    await _fetchPassbookTemplate();

    await _continueToApp();
  }

  _fetchConfig() async {
    print('Fetching configuration assets.');

    try {
      final assets = await _notificare.fetchAssets("CONFIG");
      if (assets.isEmpty) {
        print(
            'The Notificare app is not correctly configured. Missing the CONFIG asset group and/or demoSourceConfig.json');
      }

      final config =
          await AssetLoader.fetchDemoSourceConfig(assets.last.assetUrl);
      await StorageManager.setDemoSourceConfig(config);
    } catch (err) {
      print('Failed to fetch the configuration assets: $err');
    }
  }

  _fetchCustomScript() async {
    print('Fetching custom script assets.');

    try {
      final assets = await _notificare.fetchAssets("CUSTOMJS");
      if (assets.isEmpty) {
        print(
            'The Notificare app is not correctly configured. Missing the CUSTOMJS asset group and/or customScriptsDemo.js');
      }

      final customScript = await AssetLoader.fetchString(assets.last.assetUrl);
      await StorageManager.setCustomScript(customScript);
    } catch (err) {
      print('Failed to fetch the custom script assets: $err');
    }
  }

  _fetchPassbookTemplate() async {
    print('Fetching passbook template.');

    try {
      final demoSourceConfig = await StorageManager.getDemoSourceConfig();

      final passbook = await _notificare.doCloudHostOperation(
        'GET',
        '/passbook',
        null,
        null,
        null,
      );

      final templates = passbook['passbooks'] as List;
      templates.forEach((template) async {
        if (template['_id'] == demoSourceConfig.memberCard.templateId) {
          await StorageManager.setMemberCardTemplate(template);
        }
      });
    } catch (err) {
      print('Failed to fetch the passbook template: $err');
    }
  }

  _continueToApp() async {
    print('Continuing to the app.');
    if (!mounted) return;

    if (await StorageManager.getOnboardingStatus()) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }
}
