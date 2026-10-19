import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_nexusft/core/domain/register_rules.dart';

void main() {
  test('email rule matches the v1 format', () {
    expect(isValidEmail('user@example.com'), isTrue);
    expect(isValidEmail('a.b+c@sub.example.org'), isTrue);
    expect(isValidEmail('no-at.com'), isFalse);
    expect(isValidEmail('a@b'), isFalse);
    expect(isValidEmail('a b@c.com'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('username rule: 5-30 chars, contains a letter, no @', () {
    expect(isValidUsername('trader1'), isTrue);
    expect(isValidUsername('abcd'), isFalse);
    expect(isValidUsername('a' * 31), isFalse);
    expect(isValidUsername('12345'), isFalse);
    expect(isValidUsername('user@name'), isFalse);
  });

  test('phone rule: plain digits, at least 5', () {
    expect(isValidPhone('13800138000'), isTrue);
    expect(isValidPhone('12345'), isTrue);
    expect(isValidPhone('1234'), isFalse);
    expect(isValidPhone('1380013800a'), isFalse);
    expect(isValidPhone('+8613800138000'), isFalse);
  });

  test('email code rule: 6 alphanumeric', () {
    expect(isValidEmailCode('A1b2C3'), isTrue);
    expect(isValidEmailCode('12345'), isFalse);
    expect(isValidEmailCode('1234567'), isFalse);
    expect(isValidEmailCode('12345!'), isFalse);
  });

  test('password rules report each requirement individually', () {
    final weak = checkPasswordRules('abc');
    expect(weak.allOk, isFalse);
    expect(weak.lengthOk, isFalse);
    expect(weak.hasLower, isTrue);
    expect(weak.hasUpper, isFalse);

    final strong = checkPasswordRules('Abcdef1!');
    expect(strong.allOk, isTrue);

    final tooLong = checkPasswordRules('Aa1!${'a' * 20}');
    expect(tooLong.lengthOk, isFalse);
    expect(tooLong.allOk, isFalse);

    final noSpecial = checkPasswordRules('Abcdef12');
    expect(noSpecial.hasSpecial, isFalse);
    expect(noSpecial.allOk, isFalse);
  });
}
