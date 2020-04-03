import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Inbox extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  final _notificare = NotificarePushLib();
  bool _loading = false;
  final _inbox = List<NotificareInboxItem>();

  @override
  void initState() {
    super.initState();

    _fetchInbox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.delete_sweep), onPressed: _clearInbox)
        ],
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          ListView(),
          Visibility(
            visible: !_loading && _inbox.isEmpty,
            child: Text(
              'No messages found',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Visibility(
            visible: _loading,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  _fetchInbox() async {
    setState(() => _loading = true);

    final result = await _notificare.fetchInbox();
    setState(() {
      _loading = false;

      _inbox.clear();
      _inbox.addAll(result);
    });
  }

  _clearInbox() async {
    setState(() => _loading = true);

    try {
      await _notificare.clearInbox();
      await _fetchInbox();
    } catch (err) {
      setState(() => _loading = false);
    }
  }
}
