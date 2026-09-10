/// File-based asset loading for the CLI and tests. The Flutter app loads the
/// same JSON through rootBundle and calls the `fromJsonString` factories.
library;

import 'dart:io';
import 'dart:isolate';

import 'mutant_core.dart';

/// `mutant_core/assets`, resolved through the package config so it works
/// from any working directory.
Directory mutantCoreAssetsDir() {
  final lib = Isolate.resolvePackageUriSync(
    Uri.parse('package:mutant_core/mutant_core.dart'),
  );
  if (lib != null && lib.scheme == 'file') {
    return Directory.fromUri(lib.resolve('../assets/'));
  }
  return Directory('assets');
}

CardCatalog loadCatalog({Directory? assets}) => CardCatalog.fromJsonString(
  File('${(assets ?? mutantCoreAssetsDir()).path}/cards.json').readAsStringSync(),
);

NameTables loadNameTables({Directory? assets}) => NameTables.fromJsonString(
  File('${(assets ?? mutantCoreAssetsDir()).path}/names.json').readAsStringSync(),
);

MutantEngine loadEngine({Directory? assets}) =>
    MutantEngine(loadCatalog(assets: assets), loadNameTables(assets: assets));
