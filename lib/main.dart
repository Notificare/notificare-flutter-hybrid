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
    _notificare.onEventReceived.listen((NotificareEvent event) {
      if (event.name == 'ready') {
        debugPrint('Notificare is ready.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificare Demo'),
      ),
      body: Center(
        child: Text('Notificare Demo'),
      ),
    );
  }
}
