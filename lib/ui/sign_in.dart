import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/dialog_utils.dart';
import 'package:demo_flutter/utils/loyalty_utils.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class SignIn extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _notificare = NotificarePushLib();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  bool _isLoading = false;
  String _email = '';
  String _password = '';

  @override
  void dispose() {
    super.dispose();
    _emailTextController.dispose();
    _passwordTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
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
                    'assets/images/padlock.png',
                    height: 160,
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: TextField(
                      controller: _emailTextController,
                      decoration: InputDecoration(hintText: 'email'),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => _email = value,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _passwordTextController,
                      decoration: InputDecoration(hintText: 'password'),
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      onChanged: (value) => _password = value,
                      onSubmitted: (_) => _onSignInPressed(),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 20, left: 4, right: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FlatButton(
                        textColor: NotificareColors.outerSpace,
                        child: Text(
                          'Forgotten password'.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .button!
                              .copyWith(fontWeight: FontWeight.w100),
                        ),
                        onPressed: _onForgotPasswordPressed,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: double.infinity),
                      child: RaisedButton(
                        color: NotificareColors.outerSpace,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(15),
                        child: Text('Sign In'.toUpperCase()),
                        onPressed: _onSignInPressed,
                      ),
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
                        onPressed: _onRegisterPressed,
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

  void _onForgotPasswordPressed() {
    Navigator.of(context).pushNamed('/forgotpassword');
  }

  Future<void> _onSignInPressed() async {
    if (_email.isEmpty && _password.isEmpty) {
      return await showAlertDialog(
        context: context,
        message: 'Invalid credentials.',
      );
    }

    if (!_email.contains('@')) {
      return await showAlertDialog(
        context: context,
        message: 'Invalid email address.',
      );
    }

    try {
      setState(() => _isLoading = true);

      await _notificare.login(_email, _password);
      final user = await _notificare.fetchAccountDetails();

      // Create and update the current member card
      await createMemberCard(user.userName!, user.userID!);

      Navigator.of(context).popAndPushNamed('/profile');
    } catch (err) {
      await showAlertDialog(
        context: context,
        message: 'Invalid credentials.',
      );
      _passwordTextController.clear();

      setState(() => _isLoading = false);
    }
  }

  void _onRegisterPressed() {
    Navigator.of(context).pushNamed('/signup');
  }
}
