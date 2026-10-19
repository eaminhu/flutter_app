import 'package:flutter_test/flutter_test.dart';

import '../tool/check_architecture.dart';

void main() {
  test(
    'UI cannot directly use transport/storage and domain cannot use Forui',
    () {
      expect(
        validateImports(
          'modules/spot/screen.dart',
          "import '../../core/http/dio_http.dart';",
        ),
        isNotEmpty,
      );
      expect(
        validateImports(
          'shell/settings/view.dart',
          "import 'package:shared_preferences/shared_preferences.dart';",
        ),
        isNotEmpty,
      );
      expect(
        validateImports(
          'core/domain/model.dart',
          "import 'package:forui/forui.dart';",
        ),
        isNotEmpty,
      );
    },
  );

  test('conditional import and export branches enforce boundaries', () {
    for (final directive in ['import', 'export']) {
      expect(
        validateImports(
          'modules/spot/screen.dart',
          "$directive '../../core/api/contract.dart' if (dart.library.io) '../../core/adapters/unconfigured/unconfigured_adapter.dart';",
        ),
        isNotEmpty,
      );
    }
  });
  test('relative adapter imports cannot bypass feature boundary', () {
    expect(
      () => validateImports(
        'modules/spot/screen.dart',
        "import '../../core/adapters/v1/adapter.dart';",
      ),
      returnsNormally,
    );
    expect(
      validateImports(
        'modules/spot/screen.dart',
        "import '../../core/adapters/v1/adapter.dart';",
      ),
      isNotEmpty,
    );
  });
  test('verticals cannot import each other', () {
    expect(
      () => validateImports(
        'modules/spot/screen.dart',
        "import '../perps/screen.dart';",
      ),
      returnsNormally,
    );
    expect(
      validateImports(
        'modules/spot/screen.dart',
        "import 'package:flutter_nexusft/modules/perps/screen.dart';",
      ),
      isNotEmpty,
    );
  });
  test('domain stays pure Dart and feature transport stays in core', () {
    expect(
      () => validateImports(
        'core/domain/market.dart',
        "import 'package:flutter/material.dart';",
      ),
      returnsNormally,
    );
    expect(
      validateImports(
        'core/domain/market.dart',
        "import 'package:flutter/material.dart';",
      ),
      isNotEmpty,
    );
    expect(
      validateImports('modules/spot/screen.dart', "import 'dart:io';"),
      isNotEmpty,
    );
    expect(
      validateImports(
        'modules/spot/screen.dart',
        "import '../../core/api/contract.dart';",
      ),
      isEmpty,
    );
    expect(
      validateImports(
        'app/router.dart',
        "import '../modules/spot/spot_screen.dart';",
      ),
      isEmpty,
    );
  });
}
