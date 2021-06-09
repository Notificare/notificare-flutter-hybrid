import 'dart:async';

import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/ui/account_validation.dart';
import 'package:demo_flutter/ui/analytics.dart';
import 'package:demo_flutter/ui/beacons.dart';
import 'package:demo_flutter/ui/forgot_password.dart';
import 'package:demo_flutter/ui/home.dart';
import 'package:demo_flutter/ui/inbox.dart';
import 'package:demo_flutter/ui/member_card.dart';
import 'package:demo_flutter/ui/onboarding.dart';
import 'package:demo_flutter/ui/profile.dart';
import 'package:demo_flutter/ui/regions.dart';
import 'package:demo_flutter/ui/reset_password.dart';
import 'package:demo_flutter/ui/settings.dart';
import 'package:demo_flutter/ui/sign_in.dart';
import 'package:demo_flutter/ui/sign_up.dart';
import 'package:demo_flutter/ui/splash.dart';
import 'package:demo_flutter/ui/storage.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
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

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription? _notificareSubscription;
  StreamSubscription? _deepLinksSubscription;

  @override
  void initState() {
    super.initState();

    _setupNotificare();
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
      title: 'Demo Flutter',
      scaffoldMessengerKey: _scaffoldMessengerKey,
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
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (!snapshot.hasError && snapshot.hasData) {
                              return MemberCard(serial: snapshot.data as String?);
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
        '/analytics': (context) => Analytics(),
        '/validate': (context) {
          final AccountValidationRouteParams arguments =
              ModalRoute.of(context)!.settings.arguments as AccountValidationRouteParams;

          return AccountValidation(
            token: arguments.token,
          );
        },
        '/reset-password': (context) {
          final ResetPasswordRouteParams arguments =
              ModalRoute.of(context)!.settings.arguments as ResetPasswordRouteParams;

          return ResetPassword(
            token: arguments.token,
          );
        },
      },
    );
  }

  void _setupNotificare() {
    _notificare.launch();

    _notificareSubscription = _notificare.onEventReceived.listen((NotificareEvent event) {
      print('Received Notificare event: ${event.name}');

      switch (event.name) {
        case 'ready':
          _handleNotificareReady();
          break;

        case 'remoteNotificationReceivedInBackground':
          print('Received a background notification.');
          final data = event.data as NotificareRemoteNotificationReceivedInBackgroundEvent;
          _notificare.presentNotification(data.notification);
          break;

        case 'urlOpened':
          print('=== URL OPENED ===');
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('URL = ${(event.data as NotificareUrlOpenedEvent).url}')),
          );
          break;
        case 'launchUrlReceived':
          print('=== LAUNCH URL RECEIVED ===');
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Launch URL = ${(event.data as NotificareLaunchUrlReceivedEvent).url}')),
          );
          break;
        case 'inboxLoaded':
          print('=== INBOX LOADED ===');
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Inbox count = ${(event.data as NotificareInboxLoadedEvent).inbox.length}')),
          );
      }
    });
  }

  Future<void> _handleNotificareReady() async {
    if (await _notificare.isRemoteNotificationsEnabled()) {
      print('Remote notifications are enabled. Registering for notifications...');
      _notificare.registerForNotifications();
    }

    if (await _notificare.isLocationServicesEnabled()) {
      _notificare.startLocationUpdates();
      _notificare.enableBeacons();
    }
  }
}
