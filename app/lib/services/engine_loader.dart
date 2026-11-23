import 'package:flutter/services.dart';
import 'package:mutant_core/mutant_core.dart';

import 'game_assets.dart';

/// Reads the card, name and collection tables that `mutant_core` bundles as
/// package assets.
Future<MutantEngine> loadEngineFromBundle() async {
  final cards = await rootBundle.loadString(
    'packages/mutant_core/assets/cards.json',
  );
  final names = await rootBundle.loadString(
    'packages/mutant_core/assets/names.json',
  );
  final collection = await rootBundle.loadString(
    'packages/mutant_core/assets/collection.json',
  );
  return MutantEngine(
    CardCatalog.fromJsonString(cards),
    NameTables.fromJsonString(names),
    MutantCollection.fromJsonString(collection),
  );
}

Future<MoveTable> loadMoveTableFromBundle() async => MoveTable.fromJsonString(
  await rootBundle.loadString('packages/mutant_core/assets/moves.json'),
);

Future<GameAssets> loadGameAssets() async => GameAssets(
  moves: await loadMoveTableFromBundle(),
  art: await ArtIndex.load(rootBundle),
);
