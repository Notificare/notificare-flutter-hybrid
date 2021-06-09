import 'package:demo_flutter/utils/dialog_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class ResetPassword extends StatefulWidget {
  final String token;

  ResetPassword({
    required this.token,
  });

  @override
  State<StatefulWidget> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _notificare = NotificarePushLib();
  final _passwordTextController = TextEditingController();
  final _passwordConfirmationTextController = TextEditingController();

  bool _isLoading = false;
  String _password = '';
  String _passwordConfirmation = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset password"),
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
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _passwordTextController,
                      decoration: InputDecoration(hintText: 'password'),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      onChanged: (value) => _password = value,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _passwordConfirmationTextController,
                      decoration:
                          InputDecoration(hintText: 'password confirmation'),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      onChanged: (value) => _passwordConfirmation = value,
                      onSubmitted: (_) => _onResetPasswordPressed(),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: double.infinity),
                      child: RaisedButton(
                        padding: EdgeInsets.all(15),
                        child: Text('Reset password'.toUpperCase()),
                        onPressed: () => _onResetPasswordPressed(),
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

  Future<void> _onResetPasswordPressed() async {
    if (_password.isEmpty && _passwordConfirmation.isEmpty) {
      return await showAlertDialog(
        context: context,
        message: 'Please fill in all fields.',
      );
    }

    if (_password.length < 6) {
      return await showAlertDialog(
        context: context,
        message: 'Password is too short.',
      );
    }

    if (_password != _passwordConfirmation) {
      return await showAlertDialog(
        context: context,
        message:
            'Passwords do not match. Please confirm the same password twice.',
      );
    }

    try {
      setState(() => _isLoading = true);

      await _notificare.resetPassword(_password, widget.token);

      await showAlertDialog(
        context: context,
        message: 'Password reset successfully.',
      );

      Navigator.of(context).pop();
    } catch (err) {
      await showAlertDialog(
        context: context,
        message: 'err.message',
      );

      setState(() => _isLoading = false);
    }
  }
}

class ResetPasswordRouteParams {
  final String token;

  ResetPasswordRouteParams(this.token);
}
