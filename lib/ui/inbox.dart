import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:timeago/timeago.dart' as timeago;

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

    _notificare.onEventReceived.listen((event) {
      if (event.name == 'inboxLoaded') {
        final data = event.data as NotificareInboxLoadedEvent;
        debugPrint('Notificare inbox reloaded.');

        setState(() {
          _inbox.clear();
          _inbox.addAll(data.inbox);
        });
      }
    });

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
          ListView.separated(
            itemCount: _inbox.length,
            itemBuilder: _buildInboxItem,
            separatorBuilder: (context, position) => Divider(
              height: 1,
            ),
          ),
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

  Widget _buildInboxItem(BuildContext context, int position) {
    final item = _inbox[position];

    final cell = Container(
        height: 120,
        color: Colors.white,
        padding: EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Opacity(
              opacity: item.opened ? 0.5 : 1,
              child: item.attachment?.uri != null
                  ? Image.network(item.attachment.uri)
                  : Image.asset('assets/images/no_attachment.png'),
            ),
            Padding(padding: EdgeInsets.only(right: 10)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 1,
                    style: TextStyle(
                      color: item.opened ? Colors.grey : Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.message,
                    maxLines: 4,
                    style: TextStyle(
                      color: item.opened ? Colors.grey : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeago.format(DateTime.parse(item.time)),
                        maxLines: 1,
                        style: TextStyle(
                          color: item.opened ? Colors.grey : Colors.black,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));

    return GestureDetector(
      child: cell,
      onTap: () => _onInboxItemTap(item),
      onLongPress: () => {
        // TODO implement the contextual app bar
      },
    );
  }

  _onInboxItemTap(NotificareInboxItem item) async {
    debugPrint('Opening Notificare inbox item.');

    try {
      _notificare.presentInboxItem(item);
      debugPrint('Notification presented...');
    } catch (err) {
      debugPrint('Failed to mark as read: $err');
    }
  }
}
