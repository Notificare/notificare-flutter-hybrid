import 'dart:async';

import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_events.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Beacons extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BeaconsState();
}

class _BeaconsState extends State<Beacons> {
  final _notificare = NotificarePushLib();
  final _beacons = List<NotificareBeacon>();

  StreamSubscription<NotificareEvent> _notificareEventSubscription;

  @override
  void initState() {
    super.initState();

    _notificareEventSubscription = _notificare.onEventReceived.listen((event) {
      if (event.name == 'beaconsInRangeForRegion') {
        final data = event.data as NotificareBeaconsInRangeForRegionEvent;

        setState(() {
          _beacons.clear();
          _beacons.addAll(data.beacons);
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _notificareEventSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beacons'),
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          ListView.separated(
            itemCount: _beacons.length,
            itemBuilder: _buildBeaconItem,
            separatorBuilder: (context, position) => Divider(
              height: 1,
            ),
          ),
          Visibility(
            visible: _beacons.isEmpty,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'No beacons found',
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeaconItem(BuildContext context, int index) {
    final item = _beacons[index];

    return ListTile(
      key: ValueKey<NotificareBeacon>(item),
      title: Text(item.beaconName),
    );
  }
}
