import 'package:demo_flutter/models/demo_source_config.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _notificare = NotificarePushLib();
  WebViewController _controller;
  bool _isLoading = true;
  DemoSourceConfig _demoSourceConfig;

  @override
  void initState() {
    super.initState();

    _notificare.onEventReceived.listen((event) async {
      if (event.name == 'badgeUpdated' && !_isLoading) {
        debugPrint('Received a badge update event.');

        final data = event.data as NotificareBadgeUpdatedEvent;
        await _updateBadge(data.unreadCount);
      }
    });
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
              _controller = webViewController;

              final config = await StorageManager.getDemoSourceConfig();
              _demoSourceConfig = config;
              _controller.loadUrl(config.url);
            },
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) async {
              debugPrint('Page finished loading: $url');
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
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: _isLoading,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  _updateBadge([int unreadCount]) async {
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

    await _controller.evaluateJavascript("javascript:(function() {" +
        "var parent = document.getElementsByTagName('head').item(0);" +
        "var script = document.createElement('script');" +
        "script.type = 'text/javascript';" +
        "script.innerHTML = $js;" +
        "parent.appendChild(script)" +
        "})()");
  }

  bool _handleUrl(String url) {
    final configHostUri = Uri.parse(_demoSourceConfig.url);
    final uri = Uri.parse(url);

    if (uri.scheme != null &&
        uri.scheme.startsWith(_demoSourceConfig.urlScheme)) {
      // Handle recognized url schemes.
      Navigator.pushNamed(context, uri.path);

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
