import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MemberCard extends StatelessWidget {
  final String? serial;

  MemberCard({this.serial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Member Card'),
      ),
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          controller.loadUrl(
            'https://push.notifica.re/pass/web/$serial?showWebVersion=1',
          );
        },
      ),
    );
  }
}
