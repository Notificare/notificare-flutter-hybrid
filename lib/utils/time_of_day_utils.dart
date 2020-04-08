import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeOfDayUtils {
  static TimeOfDay parse(String timeOfDayStr) {
    final date = DateFormat('HH:mm').parse(timeOfDayStr);
    return TimeOfDay.fromDateTime(date);
  }

  static String format(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final date = DateTime(
        now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

    return DateFormat('HH:mm').format(date);
  }
}
