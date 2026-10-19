import 'dart:io';

List<String> validateImports(String sourcePath, String source) {
  final violations = <String>[];
  final ui =
      sourcePath.startsWith('modules/') ||
      sourcePath.startsWith('shell/') ||
      sourcePath.startsWith('design_system/') ||
      sourcePath.startsWith('app/');
  final pureCore =
      sourcePath.startsWith('core/domain/') ||
      sourcePath.startsWith('core/api/') ||
      sourcePath.startsWith('core/config/') ||
      sourcePath.startsWith('core/localization/');
  final directives = RegExp(r'(?:import|export)\s+([^;]+);');
  final uris = RegExp(r"""['"]([^'"]+)['"]""");
  final imports = directives
      .allMatches(source)
      .expand((directive) => uris.allMatches(directive.group(1)!));
  for (final match in imports) {
    final imported = match.group(1)!;
    final String target;
    if (imported.startsWith('package:flutter_nexusft/')) {
      target = Uri.parse(imported).pathSegments.skip(1).join('/');
    } else if (!imported.contains(':')) {
      target = Uri.parse(sourcePath).resolve(imported).path;
    } else {
      target = imported;
    }
    if (sourcePath.startsWith('modules/') && target.startsWith('modules/')) {
      if (sourcePath.split('/')[1] != target.split('/')[1]) {
        violations.add('$sourcePath: cross-module import $imported');
      }
    }
    if (ui &&
        (target.startsWith('core/adapters/') ||
            target.startsWith('core/http/') ||
            target.startsWith('core/storage/') ||
            imported.startsWith('package:shared_preferences/') ||
            imported.startsWith('package:flutter_secure_storage/') ||
            imported == 'dart:io' ||
            imported == 'dart:html' ||
            imported.startsWith('package:http/') ||
            imported.startsWith('package:dio/'))) {
      violations.add('$sourcePath: UI bypasses core boundary: $imported');
    }
    if (pureCore &&
        (imported.startsWith('package:flutter/') ||
            imported.startsWith('package:flutter_riverpod/') ||
            imported.startsWith('package:forui/') ||
            imported.startsWith('package:shared_preferences/') ||
            imported.startsWith('package:flutter_secure_storage/') ||
            imported.startsWith('package:material_ui/') ||
            imported.startsWith('package:cupertino_ui/'))) {
      violations.add('$sourcePath: pure core imports UI framework: $imported');
    }
  }
  return violations;
}

void main() {
  final root = Directory('lib').absolute;
  final violations = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative = entity.path
        .substring(root.path.length + 1)
        .replaceAll('\\', '/');
    violations.addAll(validateImports(relative, entity.readAsStringSync()));
  }
  if (violations.isNotEmpty) {
    for (final violation in violations) {
      stderr.writeln(violation);
    }
    exitCode = 1;
  } else {
    stdout.writeln('Architecture boundaries passed.');
  }
}
