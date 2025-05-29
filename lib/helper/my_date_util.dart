import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyDateUtil {
  static String getFormattedTime({
    required BuildContext context,
    required String time,
  }) {
    DateTime date;

    try {
      if (time.contains('-') && time.contains('T')) {
        // ISO8601 format
        date = DateTime.parse(time);
      } else {
        // millisecondsSinceEpoch format
        date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
      }
    } catch (e) {
      date = DateTime.now(); // fallback to current time
    }

    return TimeOfDay.fromDateTime(date).format(context);
  }

  // getting formatted time for read and sent
  static String getMessageTime({
    required BuildContext context,
    required String lastTime,
  }) {
    DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(lastTime));
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(sent).format(context);
    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }

    return now.year == sent.year ?
        '$formattedTime - ${sent.day} ${_getMonth(sent)}'
        : '$formattedTime - ${sent.day} ${_getMonth(sent)} ${sent.year}';
  }

  // Last Active time
  static String getLastActiveTime({
    required BuildContext context,
    required String lastActive,
  }) {
    final int i = int.tryParse(lastActive) ?? -1;
    // if time is nor available
    if (i == -1) return 'Last seen not available';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return 'Last seen today at $formattedTime';
    }

    if ((now.difference(time).inHours / 24).round() == 1) {
      return 'Last seen yesterday at $formattedTime';
    }

    String month = _getMonth(time);
    return 'Last seen at ${time.day} $month on $formattedTime';
  }

  // get last msg time (used in chat user card)
  static String getLastMessageTime({
    required BuildContext context,
    required String time,
    bool showYear = false,
  }) {
    DateTime sent;

    try {
      if (time.contains('-') && time.contains('T')) {
        sent = DateTime.parse(time);
      } else {
        sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
      }
    } catch (e) {
      sent = DateTime.now(); // fallback
    }

    final DateTime now = DateTime.now();
    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return TimeOfDay.fromDateTime(sent).format(context);
    }

    return showYear
        ? '${sent.day} ${_getMonth(sent)} ${sent.year}'
        : '${sent.day} ${_getMonth(sent)}';
  }

  // get month name from month no. or index
  static String _getMonth(DateTime date) {
    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      // default:
      //   return 'NA';
    }
    return 'NA';
  }
}
