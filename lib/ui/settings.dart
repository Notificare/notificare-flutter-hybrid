import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:package_info/package_info.dart';

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _notificare = NotificarePushLib();
  final _listItems = List<_ListItem>();

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView.separated(
        itemCount: _listItems.length,
        itemBuilder: _buildListItem,
        separatorBuilder: (context, index) => Divider(height: 1),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    return _listItems[index].build();
  }

  Future<void> _loadData() async {
    final data = List<_ListItem>();
    await _loadNotificationSettings(data);
    await _loadTags(data);
    await _loadAbout(data);

    setState(() {
      _listItems.clear();
      _listItems.addAll(data);
    });
  }

  Future<void> _loadNotificationSettings(List<_ListItem> data) async {
    data.add(_SectionListItem(title: 'Notification Settings'));
    data.add(_PreferenceListItem(
      title: 'Notifications',
      description:
          'Receive messages with our news, events or any other campaign we might find relevant for you',
      checked: await _notificare.isRemoteNotificationsEnabled(),
      onChanged: (checked) => _handleNotificationsToggle(checked),
    ));

    final demoSourceConfig = await StorageManager.getDemoSourceConfig();
    if (demoSourceConfig.config.useLocationServices) {
      data.add(_PreferenceListItem(
        title: 'Location Services',
        description:
            'Allow us to collect your location data in order to send notifications whenever you are around',
      ));
    }

    if (await _notificare.isAllowedUIEnabled()) {
      final dnd = await _notificare.fetchDoNotDisturb();

      if (dnd.start != null && dnd.end != null) {
        data.add(_PreferenceListItem(
          title: 'Do Not Disturb',
          description:
              'Configure a period of time where notifications will not generate alerts in the notification center',
          checked: true,
        ));

        data.add(_SectionListItem(title: 'From'));
        data.add(_SectionListItem(title: 'To'));
      } else {
        data.add(_PreferenceListItem(
          title: 'Do Not Disturb',
          description:
              'Configure a period of time where notifications will not generate alerts in the notification center',
          checked: false,
        ));
      }
    }
  }

  Future<void> _loadTags(List<_ListItem> data) async {
    final tags = await _notificare.fetchTags();
    data.add(_SectionListItem(title: 'Tags'));

    data.add(_PreferenceListItem(
      title: 'Press',
      description:
          'Subscribe me to the group of devices that would like to receive all the news via push notifications',
      checked: tags.contains('tag_press'),
      onChanged: (checked) => _handleChangedTag('tag_press', checked),
    ));

    data.add(_PreferenceListItem(
      title: 'Newsletter',
      description:
          'Subscribe me to the group of devices that would like to receive your newsletter',
      checked: tags.contains('tag_newsletter'),
      onChanged: (checked) => _handleChangedTag('tag_newsletter', checked),
    ));

    data.add(_PreferenceListItem(
      title: 'Events',
      description:
          'Subscribe me to the group of devices that would like to receive all the events via push notifications',
      checked: tags.contains('tag_events'),
      onChanged: (checked) => _handleChangedTag('tag_events', checked),
    ));
  }

  Future<void> _loadAbout(List<_ListItem> data) async {
    final packageInfo = await PackageInfo.fromPlatform();

    data.add(_SectionListItem(title: 'About this app'));

    data.add(_AdornedListItem(
      title: 'Leave your feedback',
      adornment: Icon(
        Icons.keyboard_arrow_right,
        color: NotificareColors.gray,
      ),
      onTap: () => _openEmailClient(),
    ));

    data.add(_AdornedListItem(
      title: 'App version',
      adornment: Text(
        packageInfo.version,
        style: TextStyle(
          fontFamily: 'Lato',
          fontSize: 14,
          fontWeight: FontWeight.w300,
        ),
      ),
    ));
  }

  Future<void> _openEmailClient() async {
    final demoSourceConfig = await StorageManager.getDemoSourceConfig();
    final recipients = demoSourceConfig.email.split(',');

    final email = Email(
      recipients: recipients,
      subject: 'your_subject',
      body: 'your_message',
    );

    await FlutterEmailSender.send(email);
  }

  Future<void> _handleNotificationsToggle(bool checked) async {
    if (checked) {
      await _notificare.registerForNotifications();
    } else {
      await _notificare.unregisterForNotifications();
    }

    // The checked prop gets updated internally but we still need to trigger
    // a rebuild.
    setState(() {});
  }

  Future<void> _handleChangedTag(String tag, bool checked) async {
    print('Handling tag toggle: $tag -> $checked');

    // The checked prop gets updated internally but we still need to trigger
    // a rebuild.
    setState(() {});

    if (checked) {
      await _notificare.addTag(tag);
    } else {
      await _notificare.removeTag(tag);
    }
  }
}

abstract class _ListItem {
  Widget build();
}

class _SectionListItem extends _ListItem {
  final String title;

  _SectionListItem({this.title});

  @override
  Widget build() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title?.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Lato',
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PreferenceListItem extends _ListItem {
  final String title;
  final String description;
  bool checked;
  final ValueChanged<bool> onChanged;

  _PreferenceListItem({
    this.title,
    this.description,
    this.checked = false,
    this.onChanged,
  });

  @override
  Widget build() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: checked,
            onChanged: (value) {
              // Update self
              this.checked = value;

              // Execute consumer's callback
              onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _AdornedListItem extends _ListItem {
  final String title;
  final Widget adornment;
  final GestureTapCallback onTap;

  _AdornedListItem({this.title, this.adornment, this.onTap});

  @override
  Widget build() {
    return GestureDetector(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16,
              ),
            ),
          ),
          adornment,
        ]),
      ),
      onTap: onTap,
    );
  }
}
