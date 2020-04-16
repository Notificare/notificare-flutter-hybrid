import 'dart:collection';
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
  final _preferencesToggles = Map<String, bool>();

  Future<_ProfileResult> _profileFuture;

  @override
  void initState() {
    super.initState();

    _profileFuture = _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder(
        future: _profileFuture,
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
      labelStyle: TextStyle(color: Theme.of(context).errorColor),
      onTap: () => _signOut(),
    ));

    // endregion

    // region Preferences section

    items.add(_buildSectionHeader(label: 'User Preferences'));

    if (preferences.isEmpty) {
      items.add(_buildListTile(label: 'You have no preferences yet.'));
    } else {
      preferences.forEach((preference) {
        if (preference.preferenceType == 'choice') {
          items.add(_buildListTile(
            label: preference.preferenceLabel,
            value: preference.preferenceOptions
                .firstWhere((option) => option.selected)
                ?.segmentLabel,
            onTap: () => _changePreferenceChoice(preference),
          ));
        } else if (preference.preferenceType == 'single') {
          items.add(_buildListTile(
            label: preference.preferenceLabel,
            trailing: Switch(
              value: _preferencesToggles[preference.preferenceId],
              onChanged: (value) async {
                setState(() {
                  _preferencesToggles[preference.preferenceId] = value;
                });

                await _updatePreferenceSingle(
                  preference: preference,
                  checked: value,
                );
              },
            ),
          ));
        } else if (preference.preferenceType == 'select') {
          items.add(_buildListTile(
            label: preference.preferenceLabel,
            value: preference.preferenceOptions
                .where((e) => e.selected)
                .length
                .toString(),
            onTap: () => _changePreferenceMulti(preference),
          ));
        }
      });
    }

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
    TextStyle labelStyle,
    String value,
    Widget trailing,
    GestureTapCallback onTap,
  }) {
    assert((value == null && trailing == null) ||
        (value != null && trailing == null) ||
        (value == null && trailing != null));

    TextStyle mergedLabelStyle = Theme.of(context).textTheme.body1;
    if (labelStyle != null) {
      mergedLabelStyle = mergedLabelStyle.merge(labelStyle);
    }

    final trailingWidget = trailing != null
        ? trailing
        : value != null
            ? Text(
                value,
                style: Theme.of(context).textTheme.caption,
              )
            : null;

    return Ink(
      color: Colors.white,
      child: ListTile(
        title: Text(
          label,
          style: mergedLabelStyle,
        ),
        trailing: trailingWidget,
        onTap: onTap,
      ),
    );
  }

  Future<_ProfileResult> _loadData() async {
    final user = await _notificare.fetchAccountDetails();
    final userPreferences = await _notificare.fetchUserPreferences();

    _populateStateToggles(userPreferences);

    return _ProfileResult(profile: user, preferences: userPreferences);
  }

  void _reloadData() {
    setState(() {
      _preferencesToggles.clear();
      _profileFuture = _loadData();
    });
  }

  void _populateStateToggles(List<NotificareUserPreference> preferences) {
    preferences
        .where((preference) => preference.preferenceType == 'single')
        .forEach((preference) => _preferencesToggles[preference.preferenceId] =
            preference.preferenceOptions.first.selected);
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

  void _openMemberCard() {
    Navigator.of(context).pushNamed('/membercard');
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

  Future<void> _changePreferenceChoice(
      NotificareUserPreference preference) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PreferenceChoiceForm(
        preference: preference,
        updateCallback: _updatePreferenceChoice,
      ),
    );
  }

  Future<void> _changePreferenceMulti(
      NotificareUserPreference preference) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PreferenceMultiChoiceForm(
        preference: preference,
        updateCallback: _updatePreferenceMultiChoice,
      ),
    );
  }

  Future<void> _updatePreferenceChoice({
    @required NotificareUserPreference preference,
    @required String selectedValue,
  }) async {
    try {
      final segment = NotificareUserSegment()
        ..segmentId = selectedValue
        ..segmentLabel = preference.preferenceOptions
            .firstWhere((option) => option.segmentId == selectedValue)
            .segmentLabel;

      await _notificare.addSegmentToUserPreference(segment, preference);
    } catch (err) {
      print('Failed to update user preference: $err');
    } finally {
      _reloadData();
    }
  }

  Future<void> _updatePreferenceSingle({
    @required NotificareUserPreference preference,
    @required bool checked,
  }) async {
    try {
      final segment = NotificareUserSegment()
        ..segmentId = preference.preferenceOptions.first.segmentId
        ..segmentLabel = preference.preferenceOptions.first.segmentLabel;

      if (checked) {
        await _notificare.addSegmentToUserPreference(segment, preference);
      } else {
        await _notificare.removeSegmentFromUserPreference(segment, preference);
      }
    } catch (err) {
      print('Failed to update user preference: $err');
    } finally {
      _reloadData();
    }
  }

  Future<void> _updatePreferenceMultiChoice({
    @required NotificareUserPreference preference,
    @required Map<String, bool> currentValues,
  }) async {
    final diffValues = HashMap<String, bool>.from(currentValues);

    // Keep just the items that have been modified.
    diffValues.removeWhere((segmentId, checked) {
      final original = preference.preferenceOptions
          .firstWhere((option) => option.segmentId == segmentId);

      return original.selected == checked;
    });

    try {
      for (var segmentId in diffValues.keys) {
        final checked = diffValues[segmentId];

        final segment = NotificareUserSegment()
          ..segmentId = segmentId
          ..segmentLabel = preference.preferenceOptions
              .firstWhere((option) => option.segmentId == segmentId)
              .segmentLabel;

        if (checked) {
          await _notificare.addSegmentToUserPreference(
            segment,
            preference,
          );
        } else {
          await _notificare.removeSegmentFromUserPreference(
            segment,
            preference,
          );
        }
      }
    } catch (err) {
      print('Failed to update user preference: $err');
    } finally {
      _reloadData();
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

// region Preference choice form

typedef _OnUpdatePreferenceChoiceCallback = Future<void> Function({
  @required NotificareUserPreference preference,
  @required String selectedValue,
});

class _PreferenceChoiceForm extends StatefulWidget {
  final NotificareUserPreference preference;
  final _OnUpdatePreferenceChoiceCallback updateCallback;

  _PreferenceChoiceForm({
    @required this.preference,
    @required this.updateCallback,
  });

  @override
  State<StatefulWidget> createState() => _PreferenceChoiceFormState();
}

class _PreferenceChoiceFormState extends State<_PreferenceChoiceForm> {
  String _selectedValue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _selectedValue = widget.preference.preferenceOptions
        .firstWhere((p) => p.selected)
        ?.segmentId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.preference.preferenceLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.preference.preferenceOptions
            .map((option) =>
                _buildRadioButtonForOption(option, enabled: !_isLoading))
            .toList(),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        FlatButton(
          child: Text('Save'),
          onPressed: _selectedValue == null || _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);

                  try {
                    await widget.updateCallback(
                      preference: widget.preference,
                      selectedValue: _selectedValue,
                    );
                  } finally {
                    setState(() => _isLoading = false);
                    Navigator.of(context).pop();
                  }
                },
        ),
      ],
    );
  }

  Widget _buildRadioButtonForOption(NotificareUserPreferenceOption option,
      {bool enabled = true}) {
    return RadioListTile(
      title: Text(option.segmentLabel),
      value: option.segmentId,
      groupValue: _selectedValue,
      onChanged: enabled
          ? (value) {
              setState(() => _selectedValue = value);
            }
          : null,
    );
  }
}

// endregion

// region Preference multi-choice form

typedef _OnUpdatePreferenceMultiChoiceCallback = Future<void> Function({
  @required NotificareUserPreference preference,
  @required Map<String, bool> currentValues,
});

class _PreferenceMultiChoiceForm extends StatefulWidget {
  final NotificareUserPreference preference;
  final _OnUpdatePreferenceMultiChoiceCallback updateCallback;

  _PreferenceMultiChoiceForm({
    @required this.preference,
    @required this.updateCallback,
  });

  @override
  State<StatefulWidget> createState() => _PreferenceMultiChoiceFormState();
}

class _PreferenceMultiChoiceFormState
    extends State<_PreferenceMultiChoiceForm> {
  final _checkBoxStateMap = Map<String, bool>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    widget.preference.preferenceOptions.forEach(
        (option) => _checkBoxStateMap[option.segmentId] = option.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.preference.preferenceLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.preference.preferenceOptions
            .map((option) =>
                _buildCheckBoxForOption(option, enabled: !_isLoading))
            .toList(),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancel'),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        FlatButton(
          child: Text('Save'),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);

                  try {
                    await widget.updateCallback(
                      preference: widget.preference,
                      currentValues: _checkBoxStateMap,
                    );
                  } finally {
                    setState(() => _isLoading = false);
                    Navigator.of(context).pop();
                  }
                },
        ),
      ],
    );
  }

  Widget _buildCheckBoxForOption(NotificareUserPreferenceOption option,
      {bool enabled = true}) {
    return CheckboxListTile(
      title: Text(option.segmentLabel),
      value: _checkBoxStateMap[option.segmentId],
      onChanged: enabled
          ? (value) {
              setState(() => _checkBoxStateMap[option.segmentId] = value);
            }
          : null,
    );
  }
}

// endregion
