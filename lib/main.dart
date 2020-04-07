import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/ui/home.dart';
import 'package:demo_flutter/ui/inbox.dart';
import 'package:demo_flutter/ui/onboarding.dart';
import 'package:demo_flutter/ui/splash.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _notificare = NotificarePushLib();

  @override
  void initState() {
    super.initState();
    _notificare.launch();
    _notificare.onEventReceived.listen((NotificareEvent event) async {
      switch (event.name) {
        case 'ready':
          debugPrint('Notificare is ready.');

          if (await _notificare.isRemoteNotificationsEnabled()) {
            debugPrint(
                'Remote notifications are enabled. Registering for notifications...');
            _notificare.registerForNotifications();
          }

          break;
        case 'deviceRegistered':
          debugPrint('The device is ready for push.');
          break;
        default:
          debugPrint('Received Notificare event: ${event.name}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: NotificareColors.wildSand,
        primaryColor: NotificareColors.outerSpace,
        accentColor: NotificareColors.gray,
      ),
      home: Splash(),
      routes: {
        '/splash': (context) => Splash(),
        '/onboarding': (context) => Onboarding(),
        '/home': (context) => Home(),
        '/inbox': (context) => Inbox(),
      },
    );
  }
}
