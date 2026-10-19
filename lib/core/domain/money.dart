import 'package:decimal/decimal.dart';

import '../api/errors.dart';

export 'package:decimal/decimal.dart';

Decimal? decOrNull(String? value, {String field = 'decimal'}) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = Decimal.tryParse(value.trim());
  if (parsed == null) {
    throw PlatformError(
      PlatformErrorCode.responseMalformed,
      'Invalid decimal field: $field.',
    );
  }
  return parsed;
}

Decimal decR(String? value, String field) {
  final parsed = decOrNull(value, field: field);
  if (parsed == null) {
    throw PlatformError(
      PlatformErrorCode.responseMalformed,
      'Missing required decimal field: $field.',
    );
  }
  return parsed;
}
