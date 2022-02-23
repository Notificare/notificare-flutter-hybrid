import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Analytics extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  final _notificare = NotificarePushLib();
  final _eventNameTextController = TextEditingController();

  bool _isLoading = false;
  String _eventName = '';
  String? _eventNameError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
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
                    'assets/images/profits.png',
                    height: 160,
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 10),
                    child: Center(
                      child: Text(
                        'Register a custom event.',
                        style: Theme.of(context).textTheme.subtitle1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _eventNameTextController,
                      decoration: InputDecoration(
                        hintText: 'event name',
                        errorText: _eventNameError,
                      ),
                      keyboardType: TextInputType.text,
                      onChanged: (value) => setState(() {
                        _eventName = value;
                        _eventNameError = null;
                      }),
                      onSubmitted: (_) => _onTrackEventPressed(),
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
                        child: Text('Track event'.toUpperCase()),
                        onPressed: _onTrackEventPressed,
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

  Future<void> _onTrackEventPressed() async {
    final eventName = _eventName.trim();

    if (eventName.length <= 0) {
      return setState(() => _eventNameError = 'Please fill in a value.');
    }

    try {
      setState(() => _isLoading = true);

      await _notificare.logCustomEvent(eventName, {});

      await showAlertDialog(
        context: context,
        message:
            'Custom event registered successfully. Please check your dashboard to see the results for this event name.',
      );

      setState(() {
        _isLoading = false;
        _eventNameTextController.clear();
      });
    } catch (err) {
      await showAlertDialog(
        context: context,
        message: 'err.message',
      );

      setState(() => _isLoading = false);
    }
  }
}
