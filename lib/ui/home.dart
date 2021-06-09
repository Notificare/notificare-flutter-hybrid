import 'dart:async';

import 'package:demo_flutter/models/demo_source_config.dart';
import 'package:demo_flutter/ui/account_validation.dart';
import 'package:demo_flutter/ui/reset_password.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _notificare = NotificarePushLib();
  final _controller = Completer<WebViewController>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  late DemoSourceConfig _demoSourceConfig;
  late StreamSubscription<NotificareEvent> _notificareEventSubscription;

  @override
  void initState() {
    super.initState();

    _notificareEventSubscription =
        _notificare.onEventReceived.listen((event) async {
      switch (event.name) {
        case 'badgeUpdated':
          print('Received a badge update event.');
          if (!_isLoading) {
            final data = event.data as NotificareBadgeUpdatedEvent;
            await _updateBadge(data.unreadCount);
          }
          break;
        case 'activationTokenReceived':
          print('Handling account validation.');

          final data = event.data as NotificareActivationTokenReceivedEvent;
          final arguments = AccountValidationRouteParams(data.token);

          Navigator.of(context).pushNamed('/validate', arguments: arguments);
          break;
        case 'resetPasswordTokenReceived':
          print('Handling password reset.');

          final data = event.data as NotificareResetPasswordTokenReceivedEvent;
          final arguments = ResetPasswordRouteParams(data.token);

          Navigator.of(context)
              .pushNamed('/reset-password', arguments: arguments);
          break;
        case 'scannableDetected':
          final data = event.data as NotificareScannableDetectedEvent;
          if (data.scannable.notification != null) {
            print('Presenting scannable.');
            await _notificare.presentScannable(data.scannable);
          } else {
            print('Scannable detected, but no notification in it.');

            _scaffoldKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  'Custom scannable found. The app is responsible for handling it.',
                ),
              ),
            );
          }
          break;
        case 'scannableSessionInvalidatedWithError':
          final data =
              event.data as NotificareScannableSessionInvalidatedWithErrorEvent;

          _scaffoldKey.currentState?.showSnackBar(
            SnackBar(content: Text(data.error)),
          );
          break;
        case 'urlOpened':
          print('=== URL OPENED ===');

          final data = event.data as NotificareUrlOpenedEvent;
          final uri = Uri.parse(data.url);
          _handleDeepLink(uri);
          break;
        case 'launchUrlReceived':
          print('=== LAUNCH URL RECEIVED ===');

          final data = event.data as NotificareLaunchUrlReceivedEvent;
          final uri = Uri.parse(data.url);
          _handleDeepLink(uri);
          break;
      }
    });

    _setupDeepLinking();
  }

  @override
  void dispose() {
    super.dispose();
    _notificareEventSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.black,
        ),
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          WebView(
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) async {
              _controller.complete(webViewController);

              final config = await StorageManager.getDemoSourceConfig();
              _demoSourceConfig = config!;
              webViewController.loadUrl(config.url!);
            },
            onPageStarted: (String url) {
              print('Page started loading: $url');
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) async {
              print('Page finished loading: $url');
              setState(() => _isLoading = false);

              await _updateBadge();
            },
            navigationDelegate: (NavigationRequest request) {
              return _handleUrl(request.url)
                  ? NavigationDecision.prevent
                  : NavigationDecision.navigate;
            },
          ),
          Visibility(
            visible: _isLoading,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateBadge([int? unreadCount]) async {
    try {
      final script = await StorageManager.getCustomScript();

      if (unreadCount == null) {
        final inbox = await _notificare.fetchInbox();

        int sum = 0;
        for (var item in inbox) {
          if (!item.opened!) sum++;
        }
        unreadCount = sum;
      }

      final badge = unreadCount > 0 ? unreadCount.toString() : '';
      final js = script!.replaceAll('%@', badge);

      final controller = await _controller.future;
      await controller.evaluateJavascript("javascript:(function() {" +
          "var parent = document.getElementsByTagName('head').item(0);" +
          "var script = document.createElement('script');" +
          "script.type = 'text/javascript';" +
          "script.innerHTML = $js;" +
          "parent.appendChild(script)" +
          "})()");
    } catch (err) {
      print('Failed to update the badge: $err');
    }
  }

  void _setupDeepLinking() async {
    // try {
    //   final initialUri = await getInitialUri();
    //   if (initialUri != null) _handleDeepLink(initialUri);
    // } catch (err) {
    //   print('Failed to get the initial deep link: $err');
    // }
    //
    // uriLinkStream.listen((Uri? uri) {
    //   if (!mounted) return;
    //   _handleDeepLink(uri!);
    // });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    switch (uri.path) {
      case '/inbox':
      case '/settings':
      case '/regions':
      case '/beacons':
      case '/profile':
      case '/membercard':
      case '/signin':
      case '/signup':
      case '/analytics':
      case '/storage':
        Navigator.of(context).pushNamed(uri.path);
        break;
      case '/scan':
        _notificare.startScannableSession();
        break;
      default:
        final config = await StorageManager.getDemoSourceConfig();
        if (config == null) return;
      // TODO do something with it
    }
  }

  bool _handleUrl(String url) {
    final configHostUri = Uri.parse(_demoSourceConfig.url!);
    final uri = Uri.parse(url);

    if (uri.scheme != null &&
        uri.scheme.startsWith(_demoSourceConfig.urlScheme!)) {
      _handleDeepLink(uri);

      return true;
    } else if (uri.host != null && uri.host != configHostUri.host) {
      // Handle https urls for other domains.
      launch(url);

      return true;
    } else if (uri.scheme != null && uri.host == null) {
      // Handle email links.
      launch(url);

      return true;
    }

    // Let the web view handle the url.
    return false;
  }
}
