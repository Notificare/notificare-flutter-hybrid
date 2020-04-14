import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

Future<void> showAlertDialog({
  @required BuildContext context,
  @required String message,
  String positiveButtonLabel = 'OK',
  VoidCallback onPositiveButtonPressed,
}) async {
  final packageInfo = await PackageInfo.fromPlatform();

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(packageInfo.appName),
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          child: Text(positiveButtonLabel),
          onPressed: () {
            // Dismiss dialog
            Navigator.of(context).pop();

            if (onPositiveButtonPressed != null) {
              onPositiveButtonPressed();
            }
          },
        ),
      ],
    ),
  );
}
