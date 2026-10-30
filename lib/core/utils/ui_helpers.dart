import 'package:app_study_share/core/localization/app_localizations.dart';
import 'package:app_study_share/core/utils/formatters.dart';
import 'package:flutter/widgets.dart';

extension UiHelpers on BuildContext {
  String levelLabel(String level) => tr('level.$level');

  String priceLabel(num price) => '${Formatters.formatPrice(price)} ${tr('currency')}';

  String when(DateTime d) => Formatters.dateTimeLabel(this, d);
}
