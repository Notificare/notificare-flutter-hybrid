import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/dialog_utils.dart';
import 'package:demo_flutter/utils/loyalty_utils.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class SignUp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _notificare = NotificarePushLib();
  final _nameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _passwordConfirmationTextController = TextEditingController();

  bool _isLoading = false;
  String _name = '';
  String _email = '';
  String _password = '';
  String _passwordConfirmation = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
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
                    'assets/images/account.png',
                    height: 160,
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _nameTextController,
                      decoration: InputDecoration(hintText: 'name'),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) => _name = value,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _emailTextController,
                      decoration: InputDecoration(hintText: 'email'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _email = value,
                    ),
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
                      decoration: InputDecoration(hintText: 'confirm password'),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      onChanged: (value) => _passwordConfirmation = value,
                      onSubmitted: (_) => _onSignUpPressed(),
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
                        child: Text('Create an account'.toUpperCase()),
                        onPressed: _onSignUpPressed,
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

  Future<void> _onSignUpPressed() async {
    if (_name.isEmpty &&
        _email.isEmpty &&
        _password.isEmpty &&
        _passwordConfirmation.isEmpty) {
      return await showAlertDialog(
        context: context,
        message: 'Please fill in all fields.',
      );
    }

    if (!_email.contains('@')) {
      return await showAlertDialog(
        context: context,
        message: 'Invalid email address.',
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

      await _notificare.createAccount(_email, _name, _password);
      await createMemberCard(_name, _email);

      await showAlertDialog(
        context: context,
        message: 'Account created successfully. You can now sign in.',
      );

      Navigator.of(context).pop();
    } catch (err) {
      await showAlertDialog(
        context: context,
        message: err.message,
      );

      setState(() => _isLoading = false);
    }
  }
}
