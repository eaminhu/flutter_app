/// Registration field validation rules (v1 parity). Pure functions so the
/// register page and unit tests share one authority; no invented formats.
library;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _usernamePattern = RegExp(r'^(?=.*[a-zA-Z])(?!.*@).{5,30}$');
final _emailCodePattern = RegExp(r'^[A-Za-z0-9]{6}$');
final _digitPattern = RegExp(r'^\d+$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

bool isValidUsername(String value) => _usernamePattern.hasMatch(value.trim());

/// Phone must be plain digits, at least 5.
bool isValidPhone(String value) {
  final v = value.trim();
  return v.length >= 5 && _digitPattern.hasMatch(v);
}

bool isValidEmailCode(String value) => _emailCodePattern.hasMatch(value.trim());

/// Password rule checklist: 8–20 chars + lowercase + uppercase + digit +
/// special character. Each rule is reported individually for the live
/// checklist on the register page.
class PasswordRuleCheck {
  const PasswordRuleCheck({
    required this.lengthOk,
    required this.hasLower,
    required this.hasUpper,
    required this.hasDigit,
    required this.hasSpecial,
  });

  final bool lengthOk;
  final bool hasLower;
  final bool hasUpper;
  final bool hasDigit;
  final bool hasSpecial;

  bool get allOk => lengthOk && hasLower && hasUpper && hasDigit && hasSpecial;
}

PasswordRuleCheck checkPasswordRules(String value) => PasswordRuleCheck(
  lengthOk: value.length >= 8 && value.length <= 20,
  hasLower: value.contains(RegExp(r'[a-z]')),
  hasUpper: value.contains(RegExp(r'[A-Z]')),
  hasDigit: value.contains(RegExp(r'[0-9]')),
  hasSpecial: value.contains(RegExp(r'[^a-zA-Z0-9\s]')),
);
