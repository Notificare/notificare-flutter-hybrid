import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

Future<void> createMemberCard(String name, String email) async {
  name = name.trim();
  email = email.trim().toLowerCase();

  print('Creating member card for: $email');
  Map<String, dynamic>? payload;

  try {
    payload = await StorageManager.getMemberCardTemplate();
    payload!['passbook'] = payload['_id'];

    final emailHash = md5.convert(utf8.encode(email)).toString();
    final url = 'https://gravatar.com/avatar/$emailHash?s=512';
    payload['data']['thumbnail'] = url;

    final primaryFields = payload['data']['primaryFields'] as List;
    primaryFields.forEach((field) {
      if (field['key'] == 'name') {
        field['value'] = name;
      }
    });

    final secondaryFields = payload['data']['secondaryFields'] as List;
    secondaryFields.forEach((field) {
      if (field['key'] == 'email') {
        field['value'] = email;
      }
    });
  } catch (err) {
    print('Failed to parse and prefill the member card: $err');
    return;
  }

  try {
    final notificare = NotificarePushLib();
    final result = await notificare.doCloudHostOperation(
      'POST',
      '/pass',
      {},
      {},
      payload,
    );

    final serial = result!['pass']['serial'] as String;
    await StorageManager.setMemberCardSerial(serial);
  } catch (err) {
    print('Failed to create a member card: $err');
  }
}
