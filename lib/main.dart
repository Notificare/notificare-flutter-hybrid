import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/ui/beacons.dart';
import 'package:demo_flutter/ui/home.dart';
import 'package:demo_flutter/ui/inbox.dart';
import 'package:demo_flutter/ui/onboarding.dart';
import 'package:demo_flutter/ui/regions.dart';
import 'package:demo_flutter/ui/settings.dart';
import 'package:demo_flutter/ui/sign_in.dart';
import 'package:demo_flutter/ui/splash.dart';
import 'package:demo_flutter/ui/storage.dart';
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

          if (await _notificare.isLocationServicesEnabled()) {
            _notificare.startLocationUpdates();
            _notificare.enableBeacons();
          }

          break;
        case 'deviceRegistered':
          debugPrint('The device has been registered/updated.');
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
        fontFamily: 'ProximaNova',
        textTheme: TextTheme(
          body2: TextStyle(
            fontWeight: FontWeight.w700,
          ),
          caption: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w100,
          ),
        ),
      ),
      home: Splash(),
      routes: {
        '/splash': (context) => Splash(),
        '/onboarding': (context) => Onboarding(),
        '/home': (context) => Home(),
        '/inbox': (context) => Inbox(),
        '/beacons': (context) => Beacons(),
        '/regions': (context) => Regions(),
        '/settings': (context) => Settings(),
        '/storage': (context) => Storage(),
        '/sign-in': (context) => SignIn(),
        '/forgot-password': (context) => ForgotPassword(),
      },
    );
  }
}
