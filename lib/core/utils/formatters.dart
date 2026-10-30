import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Shared formatting helpers used across features.
class Formatters {
  static String formatPrice(num price) {
    final rounded = (price * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(2);
  }

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String dayLabel(BuildContext context, DateTime d) =>
      DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(d);

  static String timeLabel(BuildContext context, DateTime d) =>
      DateFormat.jm(Localizations.localeOf(context).toString()).format(d);

  static String dateTimeLabel(BuildContext context, DateTime d) =>
      '${dayLabel(context, d)} · ${timeLabel(context, d)}';
}
