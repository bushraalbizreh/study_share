import 'package:app_study_share/core/localization/strings_ar.dart';
import 'package:app_study_share/core/localization/strings_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Arabic define exactly the same keys', () {
    expect(stringsAr.keys.toSet(), stringsEn.keys.toSet());
  });

  test('placeholders match between languages', () {
    final placeholder = RegExp(r'\{(\w+)\}');
    for (final key in stringsEn.keys) {
      final en = placeholder.allMatches(stringsEn[key]!).map((m) => m.group(1)).toSet();
      final ar = placeholder.allMatches(stringsAr[key]!).map((m) => m.group(1)).toSet();
      expect(ar, en, reason: 'placeholders differ for $key');
    }
  });
}
