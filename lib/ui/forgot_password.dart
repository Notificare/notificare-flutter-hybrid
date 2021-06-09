import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:package_info/package_info.dart';

class ForgotPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ForgotPassword();
}

class _ForgotPassword extends State<ForgotPassword> {
  final _notificare = NotificarePushLib();
  final _emailTextController = TextEditingController();

  bool _isLoading = false;
  String _email = '';

  @override
  void dispose() {
    super.dispose();
    _emailTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot password'),
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Visibility(
            visible: _isLoading,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Visibility(
            visible: !_isLoading,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 20)),
                  Image.asset(
                    'assets/images/key.png',
                    height: 160,
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      controller: _emailTextController,
                      decoration: InputDecoration(hintText: 'email'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _email = value,
                      onSubmitted: (_) => _onRecoverPasswordPressed(),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: double.infinity),
                      child: RaisedButton(
                        color: NotificareColors.outerSpace,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(15),
                        child: Text('Recover password'.toUpperCase()),
                        onPressed: _onRecoverPasswordPressed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _onRecoverPasswordPressed() async {
    if (_email == null || _email.isEmpty || !_email.contains('@')) {
      await _showAlertDialog('Please fill in a valid email.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _notificare.sendPassword(_email);
      await _showAlertDialog(
        'Account found. Please check your mailbox for more information.',
        onOkPressed: () => Navigator.of(context).pop(),
      );
    } catch (err) {
      await _showAlertDialog('err.message');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAlertDialog(String? message,
      {VoidCallback? onOkPressed}) async {
    final packageInfo = await PackageInfo.fromPlatform();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(packageInfo.appName),
        content: Text(message!),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              // Dismiss dialog
              Navigator.of(context).pop();

              if (onOkPressed != null) {
                onOkPressed();
              }
            },
          ),
        ],
      ),
    );
  }
}
