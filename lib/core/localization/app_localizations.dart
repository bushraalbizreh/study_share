import 'package:app_study_share/core/error/failures.dart';
import 'package:app_study_share/core/localization/strings_ar.dart';
import 'package:app_study_share/core/localization/strings_en.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  Map<String, String> get _strings =>
      locale.languageCode == 'ar' ? stringsAr : stringsEn;

  bool has(String key) => _strings.containsKey(key);

  String tr(String key, [Map<String, String> params = const {}]) {
    var text = _strings[key] ?? stringsEn[key] ?? key;
    params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppL10nContext on BuildContext {
  String tr(String key, [Map<String, String> params = const {}]) =>
      AppLocalizations.of(this).tr(key, params);

  /// Localized text for an error: `err.<code>` if known, else [message].
  String errorText(String? code, String message) {
    final l = AppLocalizations.of(this);
    if (code != null && l.has('err.$code')) return l.tr('err.$code');
    return message.isEmpty ? l.tr('err.generic') : message;
  }

  String failureText(Failure f) => errorText(f.code, f.message);
}
