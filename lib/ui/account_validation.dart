import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class AccountValidation extends StatefulWidget {
  final String token;

  AccountValidation({
    required this.token,
  });

  @override
  State<StatefulWidget> createState() => _AccountValidationState();
}

class _AccountValidationState extends State<AccountValidation> {
  final _notificare = NotificarePushLib();

  Future<void>? _validationFuture;

  @override
  void initState() {
    super.initState();

    _validationFuture = _notificare.validateAccount(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          child: FutureBuilder(
            future: _validationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  print('Failed to validate the account: ${snapshot.error}');
                  return _buildErrorWidget();
                } else {
                  return _buildContentWidget();
                }
              }

              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.check_circle,
          color: Colors.greenAccent[700],
          size: 128,
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        Text(
          'Your account has been validated!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.title,
        ),
        Text(
          'You can login now.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle,
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        RaisedButton(
          child: Text('Take me home'),
          onPressed: () => Navigator.of(context).pop(),
        )
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.error,
          color: Theme.of(context).errorColor,
          size: 128,
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        Text(
          'Something went wrong.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.title,
        ),
        Text(
          'We couldn\'t validate your account.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.subtitle,
        ),
        Padding(padding: EdgeInsets.only(top: 20)),
        RaisedButton(
          child: Text('Try again'),
          onPressed: () => _retryValidation(),
        )
      ],
    );
  }

  void _retryValidation() {
    setState(() {
      _validationFuture = _notificare.validateAccount(widget.token);
    });
  }
}

class AccountValidationRouteParams {
  final String token;

  AccountValidationRouteParams(this.token);
}
