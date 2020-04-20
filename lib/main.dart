import 'dart:async';

import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/ui/beacons.dart';
import 'package:demo_flutter/ui/forgot_password.dart';
import 'package:demo_flutter/ui/home.dart';
import 'package:demo_flutter/ui/inbox.dart';
import 'package:demo_flutter/ui/member_card.dart';
import 'package:demo_flutter/ui/onboarding.dart';
import 'package:demo_flutter/ui/profile.dart';
import 'package:demo_flutter/ui/regions.dart';
import 'package:demo_flutter/ui/settings.dart';
import 'package:demo_flutter/ui/sign_in.dart';
import 'package:demo_flutter/ui/sign_up.dart';
import 'package:demo_flutter/ui/splash.dart';
import 'package:demo_flutter/ui/storage.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:uni_links/uni_links.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _notificare = NotificarePushLib();
  final _navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription _notificareSubscription;
  StreamSubscription _deepLinksSubscription;

  @override
  void initState() {
    super.initState();

    _setupNotificare();
    _setupDeepLinking();
  }

  @override
  void dispose() {
    _notificareSubscription?.cancel();
    _deepLinksSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Demo Flutter',
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
        buttonTheme: ButtonThemeData(
          buttonColor: NotificareColors.outerSpace,
          textTheme: ButtonTextTheme.primary,
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
        '/signin': (context) => SignIn(),
        '/signup': (context) => SignUp(),
        '/forgotpassword': (context) => ForgotPassword(),
        '/profile': (context) => FutureBuilder(
              future: _notificare.isLoggedIn(),
              builder: (context, snapshot) {
                // TODO deal with the other possible scenarios
                if (snapshot.connectionState == ConnectionState.done) {
                  final isLoggedIn = snapshot.data as bool;
                  if (isLoggedIn) {
                    return Profile();
                  } else {
                    return SignIn();
                  }
                }

                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
        '/membercard': (context) => FutureBuilder(
              future: _notificare.isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (!snapshot.hasError && snapshot.hasData) {
                    final isLoggedIn = snapshot.data as bool;
                    if (isLoggedIn) {
                      return FutureBuilder(
                        future: StorageManager.getMemberCardSerial(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (!snapshot.hasError && snapshot.hasData) {
                              return MemberCard(serial: snapshot.data);
                            }
                          }

                          return Scaffold(
                            body: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      );
                    } else {
                      return SignIn();
                    }
                  }
                }

                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
      },
    );
  }

  void _setupNotificare() {
    _notificare.launch();

    _notificareSubscription =
        _notificare.onEventReceived.listen((NotificareEvent event) {
      print('Received Notificare event: ${event.name}');

      switch (event.name) {
        case 'ready':
          _handleNotificareReady();
          break;
        case 'activationTokenReceived':
          final data = event.data as NotificareActivationTokenReceivedEvent;
          _handleAccountValidation(data.token);
          break;
        case 'resetPasswordTokenReceived':
          final data = event.data as NotificareResetPasswordTokenReceivedEvent;
          _handlePasswordReset(data.token);
          break;
      }
    });
  }

  void _setupDeepLinking() async {
    getUriLinksStream().listen((Uri uri) {
      if (!mounted) return;
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    switch (uri.path) {
      case '/inbox':
      case '/settings':
      case '/regions':
      case '/profile':
      case '/membercard':
      case '/signin':
      case '/signup':
      case '/analytics':
        _navigatorKey.currentState.pushNamed(uri.path);
        break;
      default:
        final config = await StorageManager.getDemoSourceConfig();
        if (config == null) return;
      // TODO do something with it
    }
  }

  Future<void> _handleNotificareReady() async {
    if (await _notificare.isRemoteNotificationsEnabled()) {
      print(
          'Remote notifications are enabled. Registering for notifications...');
      _notificare.registerForNotifications();
    }

    if (await _notificare.isLocationServicesEnabled()) {
      _notificare.startLocationUpdates();
      _notificare.enableBeacons();
    }
  }

}
