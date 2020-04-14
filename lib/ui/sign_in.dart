import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: SingleChildScrollView(
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
                decoration: InputDecoration(hintText: 'email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(hintText: 'password'),
                keyboardType: TextInputType.visiblePassword,
                obscureText: true,
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
                    style: Theme.of(context).textTheme.button.copyWith(
                          fontWeight: FontWeight.w100,
                        ),
                  ),
                  onPressed: onForgotPasswordPressed,
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
                  onPressed: onSignInPressed,
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
                  onPressed: onRegisterPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onForgotPasswordPressed() {}

  void onSignInPressed() {}

  void onRegisterPressed() {}
}
