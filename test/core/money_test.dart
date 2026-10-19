import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/core/domain/money.dart';
import 'package:flutter_nexusft/core/api/errors.dart';

void main() {
  test('decimal input keeps exact addition and venue precision', () {
    expect(() => decR('0.1', 'amount'), returnsNormally);
    expect((decR('0.1', 'amount') + decR('0.2', 'amount')).toString(), '0.3');
    expect(
      decR('1150.568611564028596513', 'price').toString(),
      '1150.568611564028596513',
    );
  });
  test('absence differs from a genuine zero', () {
    expect(() => decOrNull(null), returnsNormally);
    expect(decOrNull(null), isNull);
    expect(decOrNull('  '), isNull);
    expect(decOrNull('0'), Decimal.zero);
  });
  test('required missing or malformed numbers refuse with a named field', () {
    for (final value in [null, '', 'NaN', 'not-a-number']) {
      expect(
        () => decR(value, 'lastPrice'),
        throwsA(
          isA<PlatformError>()
              .having(
                (error) => error.code,
                'code',
                PlatformErrorCode.responseMalformed,
              )
              .having(
                (error) => error.diagnosticMessage,
                'field',
                contains('lastPrice'),
              ),
        ),
      );
    }
  });
}
