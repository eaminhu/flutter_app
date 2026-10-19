import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_nexusft/app/nexus_app.dart';

void main() {
  testWidgets('system Hant locale selects Traditional Chinese', (tester) async {
    tester.platformDispatcher.localesTestValue = [
      const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'HK',
      ),
    ];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: NexusApp()));
    await tester.pumpAndSettle();
    expect(find.text('交易服務尚未連接。'), findsOneWidget);
  });
  testWidgets('launches Spot with an explicit disconnected state', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: NexusApp()));
    await tester.pumpAndSettle();
    expect(find.text('Spot'), findsWidgets);
    expect(find.text('Trading service is not connected.'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('settings switches theme and language across navigation', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: NexusApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settingsAction')));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    await tester.tap(find.byKey(const Key('theme.dark')));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(const Key('settingsScreen'))))
          .brightness,
      Brightness.dark,
    );
    await tester.tap(find.byKey(const Key('language.zhCn')));
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    expect(find.text('语言'), findsOneWidget);
    await tester.tap(find.byKey(const Key('spotTab')));
    await tester.pumpAndSettle();
    expect(find.text('现货'), findsWidgets);
    expect(find.text('交易服务尚未连接。'), findsOneWidget);
  });
}
