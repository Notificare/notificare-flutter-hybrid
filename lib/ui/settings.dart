import 'dart:async';

import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:demo_flutter/utils/time_of_day_utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:package_info/package_info.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const defaultDnDStart = TimeOfDay(hour: 0, minute: 0);
  static const defaultDnDEnd = TimeOfDay(hour: 8, minute: 0);

  final _notificare = NotificarePushLib();
  final _listKey = GlobalKey<AnimatedListState>();
  final _listData = <_ListItem?>[];

  _PreferenceListItem? dndItem;
  TimeOfDay? dndStart, dndEnd;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _notificare.onEventReceived.listen((event) async {
      if (event.name == 'deviceRegistered') {
        _loadDataDelayed();
      } else if (event.name == 'notificationSettingsChanged') {
        _loadDataDelayed();
      }
    });

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (_isLoading) {
        print('Already running a load op. Skipping...');
        return;
      }

      print('Loading data.');
      _isLoading = true;

      final notificationSettings = await _loadNotificationSettings();
      final tags = await _loadTags();
      final about = await _loadAbout();

      setState(() {
        _clearListItems();

        notificationSettings.forEach((item) => _addListItem(item));
        tags.forEach((item) => _addListItem(item));
        about.forEach((item) => _addListItem(item));
      });
    } catch (err) {
      print('Something went wrong: $err');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadDataDelayed() async {
    await Future.delayed(Duration(seconds: 1));
    _loadData();
  }

  Future<List<_ListItem?>> _loadNotificationSettings() async {
    final result = <_ListItem?>[];

    result.add(_SectionListItem(title: 'Notification Settings'));

    result.add(_PreferenceListItem(
      title: 'Notifications',
      description:
          'Receive messages with our news, events or any other campaign we might find relevant for you',
      checked: await _notificare.isRemoteNotificationsEnabled(),
      onCheckChanged: (item, checked) async {
        setState(() => item.checked = checked);
        _handleNotificationsUpdate(checked);
      },
    ));

    final demoSourceConfig = await StorageManager.getDemoSourceConfig();
    if (demoSourceConfig!.config!.useLocationServices!) {
      result.add(_PreferenceListItem(
        title: 'Location Services',
        description:
            'Allow us to collect your location data in order to send notifications whenever you are around',
        checked: await _notificare.isLocationServicesEnabled(),
        onCheckChanged: (item, checked) async {
          setState(() => item.checked = checked);
          _handleLocationServicesUpdate(checked);
        },
      ));
    }

    if (await _notificare.isRemoteNotificationsEnabled() &&
        await _notificare.isAllowedUIEnabled()) {
      final dnd = await _notificare.fetchDoNotDisturb();

      dndItem = _PreferenceListItem(
        title: 'Do Not Disturb',
        description:
            'Configure a period of time where notifications will not generate alerts in the notification center',
        checked: dnd!.start != null && dnd.end != null,
        onCheckChanged: (item, checked) {
          setState(() {
            item.checked = checked;

            final index = _listData.indexOf(item);

            if (checked) {
              dndStart = defaultDnDStart;
              dndEnd = defaultDnDEnd;

              _addListItem(
                _createDoNotDisturbTimeListItem(dndStart, true),
                index + 1,
              );

              _addListItem(
                _createDoNotDisturbTimeListItem(dndEnd, false),
                index + 2,
              );
            } else {
              dndStart = null;
              dndEnd = null;

              _removeListItem(index + 1);
              _removeListItem(index + 1);
            }
          });

          _handleDoNotDisturbUpdate(checked);
        },
      );

      result.add(dndItem);

      if (dnd.start != null && dnd.end != null) {
        dndStart = TimeOfDayUtils.parse(dnd.start!);
        result.add(_createDoNotDisturbTimeListItem(
            TimeOfDayUtils.parse(dnd.start!), true));

        dndEnd = TimeOfDayUtils.parse(dnd.end!);
        result.add(_createDoNotDisturbTimeListItem(
            TimeOfDayUtils.parse(dnd.end!), false));
      }
    } else {
      dndItem = null;
    }

    return result;
  }

  Future<List<_ListItem>> _loadTags() async {
    final result = <_ListItem>[];
    final tags = await _notificare.fetchTags();

    result.add(_SectionListItem(title: 'Tags'));

    result.add(_PreferenceListItem(
      title: 'Press',
      description:
          'Subscribe me to the group of devices that would like to receive all the news via push notifications',
      checked: tags.contains('tag_press'),
      onCheckChanged: (item, checked) {
        setState(() => item.checked = checked);
        _handleTagUpdate('tag_press', checked);
      },
    ));

    result.add(_PreferenceListItem(
      title: 'Newsletter',
      description:
          'Subscribe me to the group of devices that would like to receive your newsletter',
      checked: tags.contains('tag_newsletter'),
      onCheckChanged: (item, checked) {
        setState(() => item.checked = checked);
        _handleTagUpdate('tag_newsletter', checked);
      },
    ));

    result.add(_PreferenceListItem(
      title: 'Events',
      description:
          'Subscribe me to the group of devices that would like to receive all the events via push notifications',
      checked: tags.contains('tag_events'),
      onCheckChanged: (item, checked) {
        setState(() => item.checked = checked);
        _handleTagUpdate('tag_events', checked);
      },
    ));

    return result;
  }

  Future<List<_ListItem>> _loadAbout() async {
    final result = <_ListItem>[];
    final packageInfo = await PackageInfo.fromPlatform();

    result.add(_SectionListItem(title: 'About this app'));

    result.add(_AdornedListItem(
      title: 'Leave your feedback',
      adornmentBuilder: () => Icon(
        Icons.keyboard_arrow_right,
        color: NotificareColors.gray,
      ),
      onTap: () => _openEmailClient(),
    ));

    result.add(_AdornedListItem(
      title: 'App version',
      adornmentBuilder: () => Text(
        packageInfo.version,
        style: Theme.of(context).textTheme.caption!.copyWith(fontSize: 14),
      ),
    ));

    result.add(_AdornedListItem(
      title: 'Launch Notificare',
      adornmentBuilder: () => Icon(
        Icons.keyboard_arrow_right,
        color: NotificareColors.gray,
      ),
      onTap: () async {
        await _notificare.launch();
      },
    ));

    result.add(_AdornedListItem(
      title: 'Un-launch Notificare',
      adornmentBuilder: () => Icon(
        Icons.keyboard_arrow_right,
        color: NotificareColors.gray,
      ),
      onTap: () async {
        await _notificare.unlaunch();
      },
    ));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _listData.length,
        itemBuilder: (context, index, animation) {
          return FadeTransition(
            opacity: animation,
            child: _listData[index]!.build(context, index),
          );
        },
      ),
    );
  }

  void _addListItem(_ListItem? item, [int? index]) {
    final insertIndex = index != null ? index : _listData.length;
    _listData.insert(insertIndex, item);
    _listKey.currentState?.insertItem(insertIndex);
  }

  void _removeListItem(int index, {bool animated = true}) {
    final removed = _listData.removeAt(index);
    _listKey.currentState?.removeItem(index, (context, animation) {
      // if (!animated) {
      //   return null;
      // }

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Interval(0.5, 1.0),
        ),
        child: SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Interval(0.0, 1.0),
          ),
          axisAlignment: 0.0,
          child: removed!.build(context),
        ),
      );
    });
  }

  void _clearListItems() {
    for (var i = _listData.length - 1; i >= 0; i--) {
      _removeListItem(i, animated: false);
    }
  }

  Future<void> _handleNotificationsUpdate(bool enabled) async {
    if (enabled) {
      await _notificare.registerForNotifications();
    } else {
      await _notificare.unregisterForNotifications();
    }
  }

  Future<void> _handleLocationServicesUpdate(bool enabled) async {
    if (enabled) {
      await _notificare.startLocationUpdates();
      await _notificare.enableBeacons();
    } else {
      await _notificare.stopLocationUpdates();
      await _notificare.disableBeacons();
    }
  }

  Future<void> _handleDoNotDisturbUpdate(bool enabled) async {
    if (enabled) {
      final dnd = NotificareDeviceDnD();
      dnd.start = TimeOfDayUtils.format(defaultDnDStart);
      dnd.end = TimeOfDayUtils.format(defaultDnDEnd);

      await _notificare.updateDoNotDisturb(dnd);
    } else {
      await _notificare.clearDoNotDisturb();
    }
  }

  Future<void> _handleTagUpdate(String tag, bool enabled) async {
    if (enabled) {
      _notificare.addTag(tag);
    } else {
      _notificare.removeTag(tag);
    }
  }

  Future<void> _handleDoNotDisturbTap(bool forStart) async {
    final initialValue = forStart ? dndStart! : dndEnd!;
    final value = await showTimePicker(
      context: context,
      initialTime: initialValue,
    );

    // The user cancelled the picker.
    if (value == null) return;

    setState(() {
      if (forStart) {
        dndStart = value;
      } else {
        dndEnd = value;
      }

      final dndIndex = _listData.indexOf(dndItem);
      final indexOffset = forStart ? 1 : 2;
      _listData[dndIndex + indexOffset] =
          _createDoNotDisturbTimeListItem(value, forStart);
    });

    final dnd = NotificareDeviceDnD();
    dnd.start = TimeOfDayUtils.format(forStart ? value : dndStart!);
    dnd.end = TimeOfDayUtils.format(!forStart ? value : dndEnd!);

    await _notificare.updateDoNotDisturb(dnd);
  }

  Future<void> _openEmailClient() async {
    final demoSourceConfig = await StorageManager.getDemoSourceConfig() ;
    final recipients = demoSourceConfig!.email!.split(',');

    // final email = Email(
    //   recipients: recipients,
    //   subject: 'your_subject',
    //   body: 'your_message',
    // );
    //
    // await FlutterEmailSender.send(email);
  }

  _AdornedListItem _createDoNotDisturbTimeListItem(
      TimeOfDay? timeOfDay, bool forStart) {
    return _AdornedListItem(
      title: forStart ? 'From' : 'To',
      adornmentBuilder: () => Text(
        TimeOfDayUtils.format(timeOfDay!),
      ),
      onTap: () => _handleDoNotDisturbTap(forStart),
    );
  }
}

typedef _PreferenceCheckChangedCallback = void Function(
    _PreferenceListItem, bool);

typedef _AdornmentBuilderCallback = Widget Function();

abstract class _ListItem {
  Widget build(BuildContext context, [int? index]);

  Decoration buildDecoration(BuildContext context, {Color? color}) {
    final dividerColor = Theme.of(context).dividerColor;

    final decoration = BoxDecoration(
      color: color,
      border: Border(bottom: BorderSide(color: dividerColor)),
    );

    return decoration;
  }
}

class _SectionListItem extends _ListItem {
  String title;

  _SectionListItem({required this.title});

  @override
  Widget build(BuildContext context, [int? index]) {
    return Container(
      key: ValueKey<_SectionListItem>(this),
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: buildDecoration(context),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.subtitle2,
      ),
    );
  }
}

class _PreferenceListItem extends _ListItem {
  String title;
  String description;
  bool checked;
  _PreferenceCheckChangedCallback onCheckChanged;

  _PreferenceListItem({
    required this.title,
    required this.description,
    this.checked = false,
    required this.onCheckChanged,
  });

  @override
  Widget build(BuildContext context, [int? index]) {
    return Container(
      key: ValueKey<_PreferenceListItem>(this),
      decoration: buildDecoration(context, color: Colors.white),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          title,
          style: Theme.of(context).textTheme.subtitle2,
        ),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.caption,
        ),
        trailing: Switch(
          value: checked,
          onChanged: (value) => onCheckChanged(this, value),
        ),
      ),
    );
  }
}

class _AdornedListItem extends _ListItem {
  String title;
  _AdornmentBuilderCallback? adornmentBuilder;
  GestureTapCallback? onTap;

  _AdornedListItem({
    required this.title,
    this.adornmentBuilder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, [int? index]) {
    final isBeingRemoved = index == null;

    return Ink(
      key: ValueKey<_AdornedListItem>(this),
      decoration:
          isBeingRemoved ? null : buildDecoration(context, color: Colors.white),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.subtitle2,
        ),
        trailing: adornmentBuilder != null ? adornmentBuilder!() : null,
        onTap: onTap != null ? onTap : null,
      ),
    );
  }
}
