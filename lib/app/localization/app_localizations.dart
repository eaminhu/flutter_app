import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/domain/preferences.dart';
import '../../core/localization/strings.dart';

export '../../core/localization/strings.dart';

Locale localeFor(AppLanguage language) => switch (language) {
  AppLanguage.enUs => const Locale('en', 'US'),
  AppLanguage.zhCn => const Locale('zh', 'CN'),
  AppLanguage.zhTw => const Locale('zh', 'TW'),
};

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    if (locale.languageCode == 'zh') {
      return localeFor(
        languageForTags(
          locale.languageCode,
          scriptCode: locale.scriptCode,
          countryCode: locale.countryCode,
        ),
      );
    }
    if (locale.languageCode == 'en') return localeFor(AppLanguage.enUs);
  }
  return localeFor(AppLanguage.enUs);
}

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;
  AppLanguage get language => languageForTags(
    locale.languageCode,
    scriptCode: locale.scriptCode,
    countryCode: locale.countryCode,
  );
  String text(AppText key) => translatedText(language, key);
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  static const delegate = _AppLocalizationsDelegate();
  static final supportedLocales = AppLanguage.values.map(localeFor).toList();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'zh';
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
