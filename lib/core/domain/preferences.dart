enum AppLanguage { enUs, zhCn, zhTw }

enum AppTheme { system, light, dark }

class AppPreferences {
  const AppPreferences({this.language, this.theme = AppTheme.system});
  final AppLanguage? language;
  final AppTheme theme;
}

AppLanguage languageForTags(
  String languageCode, {
  String? scriptCode,
  String? countryCode,
}) {
  if (languageCode != 'zh') return AppLanguage.enUs;
  return scriptCode == 'Hant' || (scriptCode != 'Hans' && countryCode == 'TW')
      ? AppLanguage.zhTw
      : AppLanguage.zhCn;
}

String languageHeader(AppLanguage language) => switch (language) {
  AppLanguage.enUs => 'en-US',
  AppLanguage.zhCn => 'zh-CN',
  AppLanguage.zhTw => 'zh-TW',
};
