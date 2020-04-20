import 'dart:async';

import 'package:demo_flutter/models/demo_source_config.dart';
import 'package:demo_flutter/ui/account_validation.dart';
import 'package:demo_flutter/ui/reset_password.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:package_info/package_info.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _notificare = NotificarePushLib();
  final _controller = Completer<WebViewController>();

  bool _isLoading = true;
  DemoSourceConfig _demoSourceConfig;
  StreamSubscription<NotificareEvent> _notificareEventSubscription;

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
              _demoSourceConfig = config;
              webViewController.loadUrl(config.url);
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

  Future<void> _updateBadge([int unreadCount]) async {
    try {
      final script = await StorageManager.getCustomScript();

      if (unreadCount == null) {
        final inbox = await _notificare.fetchInbox();

        unreadCount = 0;
        for (var item in inbox) {
          if (!item.opened) unreadCount++;
        }
      }

      final badge = unreadCount > 0 ? unreadCount.toString() : '';
      final js = script.replaceAll('%@', badge);

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
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (err) {
      print('Failed to get the initial deep link: $err');
    }

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
        Navigator.of(context).pushNamed(uri.path);
        break;
      default:
        final config = await StorageManager.getDemoSourceConfig();
        if (config == null) return;
      // TODO do something with it
    }
  }

  bool _handleUrl(String url) {
    final configHostUri = Uri.parse(_demoSourceConfig.url);
    final uri = Uri.parse(url);

    if (uri.scheme != null &&
        uri.scheme.startsWith(_demoSourceConfig.urlScheme)) {
      switch (uri.path) {
        case '/analytics':
          _handleAnalyticsClick();
          break;
        default:
          // Handle recognized url schemes.
          Navigator.pushNamed(context, uri.path);
      }

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

  Future<void> _handleAnalyticsClick() async {
    final result = await _presentEventDialog();
    if (result == null) return;

    if (result.trim().length == 0) {
      await _presentEventAlertDialog('Please insert a valid event name');
    } else {
      try {
        await _notificare.logCustomEvent(result.trim(), {});
        await _presentEventAlertDialog(
            'Custom event registered successfully. Please check your dashboard to see the results for this event name.');
      } catch (err) {
        await _presentEventAlertDialog(
            'We could not register the event at this time, please try again later.');
      }
    }
  }

  Future<String> _presentEventDialog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    String eventName = '';

    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(packageInfo.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Register Custom Event'),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type an event name',
              ),
              onChanged: (value) => eventName = value,
            ),
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            child: Text('Send'),
            onPressed: () {
              Navigator.of(context).pop(eventName);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _presentEventAlertDialog(String message) async {
    final packageInfo = await PackageInfo.fromPlatform();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(packageInfo.appName),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
