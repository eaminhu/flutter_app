import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/errors.dart';

final class PlatformErrorObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    developer.log(
      'Data read failed',
      name: context.provider.name ?? 'platform',
      level: 1000,
      error: error is PlatformError ? error.code.name : error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}
