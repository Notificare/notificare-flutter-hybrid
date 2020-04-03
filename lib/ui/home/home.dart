import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _notificare = NotificarePushLib();
  WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _notificare.onEventReceived.listen((e) async {
      if (e.name == 'badgeUpdated' && !_isLoading) {
        debugPrint('Received a badge update event.');

        final event = e as NotificareBadgeUpdatedEvent;
        await _updateBadge(event.unreadCount);
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
}
