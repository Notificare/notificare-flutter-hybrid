import 'dart:async';

import 'package:demo_flutter/ui/widgets/animated_app_bar.dart';
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
  final _inbox = List<NotificareInboxItem>();
  final _selectedItems = List<NotificareInboxItem>();
  final _appBarKey = GlobalKey<AnimatedAppBarState>();

  bool _loading = false;
  StreamSubscription<NotificareEvent> _notificareSubscription;

  @override
  void initState() {
    super.initState();

    _notificareSubscription = _notificare.onEventReceived.listen((event) {
      if (event.name == 'inboxLoaded') {
        final data = event.data as NotificareInboxLoadedEvent;
        print('Notificare inbox reloaded.');

        setState(() {
          _inbox.clear();
          _inbox.addAll(data.inbox);
        });
      }
    });

    _fetchInbox();
  }

  @override
  void dispose() {
    _notificareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        key: _appBarKey,
        primaryAppBar: AppBar(
          title: Text('Inbox'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.delete_sweep), onPressed: _clearInbox)
          ],
        ),
        secondaryContent: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            _selectedItems.length.toString(),
            style: TextStyle(color: Colors.black54),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: () {
              _selectedItems.clear();
              _appBarKey.currentState?.dismissSecondaryContent();
            },
          ),
          actionsIconTheme: IconThemeData(color: Colors.black54),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.drafts), onPressed: _markSelectionRead),
            IconButton(icon: Icon(Icons.delete), onPressed: _deleteSelection),
          ],
        ),
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Visibility(
            visible: !_loading,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            child: ListView.separated(
              itemCount: _inbox.length,
              itemBuilder: _buildInboxItem,
              separatorBuilder: (context, position) => Divider(
                height: 1,
              ),
            ),
          ),
          Visibility(
            visible: !_loading && _inbox.isEmpty,
            child: Text(
              'No messages found',
              style: Theme.of(context).textTheme.caption,
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

  Widget _buildInboxItem(BuildContext context, int position) {
    final item = _inbox[position];
    final isSelected = _selectedItems.contains(item);

    final cell = Container(
        height: 120,
        color: isSelected ? Colors.grey[200] : Colors.white,
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
                    item.title ?? "",
                    maxLines: 1,
                    style: Theme.of(context).textTheme.body2.copyWith(
                          color: item.opened ? Colors.grey : Colors.black,
                        ),
                  ),
                  Text(
                    item.message,
                    maxLines: 4,
                    style: Theme.of(context).textTheme.caption.copyWith(
                          color: item.opened ? Colors.grey : Colors.black,
                        ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeago.format(DateTime.parse(item.time)),
                        maxLines: 1,
                        style: Theme.of(context).textTheme.caption.copyWith(
                              color: item.opened ? Colors.grey : Colors.black,
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
      onLongPress: () => _onInboxItemLongPress(item),
    );
  }

  Future<void> _fetchInbox() async {
    setState(() => _loading = true);

    final result = await _notificare.fetchInbox();
    setState(() {
      _loading = false;

      _inbox.clear();
      _inbox.addAll(result);
    });
  }

  Future<void> _clearInbox() async {
    setState(() => _loading = true);

    try {
      await _notificare.clearInbox();
      await _fetchInbox();
    } catch (err) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markSelectionRead() async {
    setState(() => _loading = true);

    try {
      for (var item in _selectedItems) {
        // The call below will trigger an inbox update, forcing the list
        // to update its data.
        await _notificare.markAsRead(item);
      }
    } catch (err) {
      print('Failed to mark item as read: $err');
    }

    await Future.delayed(Duration(milliseconds: 250), () {
      setState(() {
        _loading = false;
        _selectedItems.clear();
        _appBarKey.currentState?.dismissSecondaryContent();
      });
    });
  }

  Future<void> _deleteSelection() async {
    setState(() => _loading = true);

    try {
      for (var item in _selectedItems) {
        // The call below will trigger an inbox update, forcing the list
        // to update its data.
        await _notificare.removeFromInbox(item);
      }
    } catch (err) {
      print('Failed to delete item: $err');
    }

    await Future.delayed(Duration(milliseconds: 250), () {
      setState(() {
        _loading = false;
        _selectedItems.clear();
        _appBarKey.currentState?.dismissSecondaryContent();
      });
    });
  }

  Future<void> _onInboxItemTap(NotificareInboxItem item) async {
    if (_selectedItems.isNotEmpty) {
      print('Handling item selection.');

      _onInboxItemLongPress(item);
      return;
    }

    print('Opening Notificare inbox item.');

    try {
      await _notificare.presentInboxItem(item);
      print('Notification presented...');
    } catch (err) {
      print('Failed to mark as read: $err');
    }
  }

  void _onInboxItemLongPress(NotificareInboxItem item) {
    final selectionInProgress = _selectedItems.length > 0;
    final isSelected = _selectedItems.contains(item);

    setState(() {
      if (!isSelected) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }

      if (!selectionInProgress) {
        _appBarKey.currentState?.showSecondaryContent();
      } else if (_selectedItems.length == 0) {
        _appBarKey.currentState?.dismissSecondaryContent();
      }
    });
  }
}
