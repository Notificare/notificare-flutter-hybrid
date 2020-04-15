import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:demo_flutter/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:package_info/package_info.dart';

class Profile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _notificare = NotificarePushLib();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.hasError && snapshot.hasData) {
              return _buildUserProfile(context, snapshot.data);
            }

            return Container();
          }

          // Loading
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, _ProfileResult result) {
    final profile = result.profile;
    final preferences = result.preferences;

    final items = List<Widget>();

    final email = profile.userID.toLowerCase().trim();
    final emailHash = md5.convert(utf8.encode(email)).toString();

    // region Profile section

    // Avatar
    items.add(CachedNetworkImage(
      imageUrl: "https://gravatar.com/avatar/$emailHash?s=512",
      placeholder: (context, url) => Image.asset('assets/images/account.png'),
      errorWidget: (context, url, error) =>
          Image.asset('assets/images/account.png'),
    ));

    // Name
    items.add(_buildListTile(
      label: 'Name',
      value: profile.userName,
    ));

    // Email
    items.add(_buildListTile(
      label: 'Email',
      value: email,
    ));

    // Push Email
    items.add(_buildListTile(
      label: 'Push Email',
      value: profile.accessToken,
      onTap: () => _openEmailClient(profile),
    ));

    // Open member card
    items.add(_buildListTile(
      label: 'Open Member Card',
      onTap: () => _openMemberCard(),
    ));

    // Change password
    items.add(_buildListTile(
      label: 'Change password',
      onTap: () => _changePassword(),
    ));

    // New push email
    items.add(_buildListTile(
      label: 'New Push Email',
      onTap: () => _generatePushEmail(),
    ));

    // Sign out
    items.add(_buildListTile(
      label: 'Sign Out',
      onTap: () => _signOut(),
    ));

    // endregion

    // region Preferences section

    items.add(_buildSectionHeader(label: 'User Preferences'));

    if (preferences.isEmpty) {
      items.add(_buildListTile(label: 'You have no preferences yet.'));
    } else {}

    // endregion

    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: items,
      ).toList(),
    );
  }

  Widget _buildSectionHeader({@required String label}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.subhead,
      ),
    );
  }

  Widget _buildListTile({
    @required String label,
    String value,
    GestureTapCallback onTap,
  }) {
    return Ink(
      color: Colors.white,
      child: ListTile(
        title: Text(
          label,
          style: Theme.of(context).textTheme.body1,
        ),
        trailing: value != null
            ? Text(
                value,
                style: Theme.of(context).textTheme.caption,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Future<_ProfileResult> _loadData() async {
    final user = await _notificare.fetchAccountDetails();
    final userPreferences = await _notificare.fetchUserPreferences();

    return _ProfileResult(profile: user, preferences: userPreferences);
  }

  void _reloadData() {
    setState(() {});
  }

  Future<void> _openEmailClient(NotificareUser profile) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final email = Email(
      recipients: ["${profile.accessToken}@pushmail.notifica.re"],
      subject: "${Platform.operatingSystem} ${packageInfo.appName}",
      body: '',
    );

    await FlutterEmailSender.send(email);
  }

  Future<void> _openMemberCard() async {
    //final serial = await StorageManager.getMemberCardSerial();
    // TODO add passbookManager.open(serial);
  }

  Future<void> _changePassword() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangePasswordForm(
        onCancel: () {},
        onSubmit: (password) async {
          try {
            await _notificare.changePassword(password);
            await showAlertDialog(
              context: context,
              message: 'Password changed sucessfully.',
            );
          } catch (err) {
            await showAlertDialog(
              context: context,
              message: 'Could not change your password.',
            );
          }
        },
      ),
    );
  }

  Future<void> _generatePushEmail() async {
    try {
      await _notificare.generateAccessToken();

      showAlertDialog(
        context: context,
        message: 'New token generated successfully.',
        onPositiveButtonPressed: () => _reloadData(),
      );
    } catch (err) {
      showAlertDialog(
        context: context,
        message: 'Could not generate a new token.',
        onPositiveButtonPressed: () => _reloadData(),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _notificare.logout();

      Navigator.of(context).pop();
    } catch (err) {
      showAlertDialog(
        context: context,
        message: 'Could not log you out.',
        onPositiveButtonPressed: () => _reloadData(),
      );
    }
  }
}

class _ProfileResult {
  final NotificareUser profile;
  final List<NotificareUserPreference> preferences;

  _ProfileResult({this.profile, this.preferences});
}

// region Change password form

typedef _OnChangePasswordFormSubmitCallback = void Function(String);

class _ChangePasswordForm extends StatefulWidget {
  final _OnChangePasswordFormSubmitCallback onSubmit;
  final VoidCallback onCancel;

  _ChangePasswordForm({
    @required this.onSubmit,
    @required this.onCancel,
  });

  @override
  State<StatefulWidget> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  String _password = '';
  String _passwordConfirmation = '';

  String _passwordError;
  String _passwordConfirmationError;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change your password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'New password',
              errorText: _passwordError,
            ),
            onChanged: (value) => setState(() {
              _passwordError = null;
              _password = value;
            }),
          ),
          Padding(padding: EdgeInsets.only(top: 20)),
          TextField(
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              errorText: _passwordConfirmationError,
            ),
            onChanged: (value) => setState(() {
              _passwordConfirmationError = null;
              _passwordConfirmation = value;
            }),
          ),
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            widget.onCancel();
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Change'),
          onPressed: () {
            if (_password.isEmpty) {
              return setState(() {
                _passwordError = 'Please fill in a new password.';
                _passwordConfirmationError = null;
              });
            }

            if (_password.length < 6) {
              return setState(() {
                _passwordError = 'The password is too short.';
                _passwordConfirmationError = null;
              });
            }

            if (_password != _passwordConfirmation) {
              return setState(() {
                _passwordError = null;
                _passwordConfirmationError =
                    'The confirmation does not match with the password.';
              });
            }

            widget.onSubmit(_password);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

// endregion
