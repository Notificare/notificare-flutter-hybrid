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

  @override
  void initState() {
    super.initState();

    _notificare.onEventReceived.listen((NotificareEvent event) {
      if (event.name != 'ready') return;

      _startup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Image(image: AssetImage('assets/images/logo.png')),
        ),
      ),
    );
  }

  void _startup() async {
    await _fetchConfig();
    await _fetchCustomScript();
    await _fetchPassbookTemplate();

    await _continueToApp();
  }

  _fetchConfig() async {
    debugPrint('Fetching configuration assets.');

    try {
      final assets = await _notificare.fetchAssets("CONFIG");
      if (assets.isEmpty) {
        debugPrint(
            'The Notificare app is not correctly configured. Missing the CONFIG asset group and/or demoSourceConfig.json');
      }

      final config =
          await AssetLoader.fetchDemoSourceConfig(assets.last.assetUrl);
      await StorageManager.setDemoSourceConfig(config);
    } catch (err) {
      debugPrint('Failed to fetch the configuration assets: $err');
    }
  }

  _fetchCustomScript() async {
    debugPrint('Fetching custom script assets.');

    try {
      final assets = await _notificare.fetchAssets("CUSTOMJS");
      if (assets.isEmpty) {
        debugPrint(
            'The Notificare app is not correctly configured. Missing the CUSTOMJS asset group and/or customScriptsDemo.js');
      }

      final customScript = await AssetLoader.fetchString(assets.last.assetUrl);
      await StorageManager.setCustomScript(customScript);
    } catch (err) {
      debugPrint('Failed to fetch the custom script assets: $err');
    }
  }

  _fetchPassbookTemplate() async {
    debugPrint('Fetching passbook template.');

    try {
      final demoSourceConfig = await StorageManager.getDemoSourceConfig();

      final passbook = await _notificare
          .doCloudHostOperation('GET', '/api/passbook', {}, {}, {});

      final templates = passbook['passbooks'] as List;
      templates.forEach((template) {
        if (template['_id'] == demoSourceConfig.memberCard.templateId) {
          //StorageManager.setMemberCardTemplate(template);
          // TODO parse and store the template
        }
      });
    } catch (err) {
      debugPrint('Failed to fetch the passbook template: $err');
    }
  }

  _continueToApp() async {
    // TODO perhaps check the internet connectivity before moving forward

    if (await StorageManager.getOnboardingStatus()) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }
}
