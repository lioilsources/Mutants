import 'package:flutter/services.dart';
import 'package:mutant_core/mutant_core.dart';

/// Reads the card and name tables that `mutant_core` bundles as package assets.
Future<MutantEngine> loadEngineFromBundle() async {
  final cards = await rootBundle.loadString(
    'packages/mutant_core/assets/cards.json',
  );
  final names = await rootBundle.loadString(
    'packages/mutant_core/assets/names.json',
  );
  return MutantEngine(
    CardCatalog.fromJsonString(cards),
    NameTables.fromJsonString(names),
  );
}
