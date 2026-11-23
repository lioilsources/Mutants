import '../model/collection.dart';
import '../model/config.dart';
import '../model/creature.dart';
import '../model/enums.dart';
import 'bestiary.dart';

enum ShelfState {
  /// Never hatched – black shadow with a question mark.
  unknown,

  /// Only hatched half-baked – grey figure.
  seen,

  /// Built completely at least once – painted figure.
  owned,
}

/// One shelf of the collection screen (PLAN-KOLEKCE §4.2, §5.4).
class MutantShelf {
  const MutantShelf({
    required this.mutant,
    required this.state,
    required this.records,
    this.bestRarity,
    this.elements = const {},
    this.firstAt,
    this.creators = const [],
  });

  final MutantDef mutant;
  final ShelfState state;

  /// Every record of this mutant, premature ones included, oldest first.
  final List<CreatureRecord> records;

  /// Best rarity among owned pieces; null unless owned.
  final Rarity? bestRarity;

  /// Elements of owned pieces (a seal changes it).
  final Set<ElementType> elements;

  /// First owned piece.
  final DateTime? firstAt;
  final List<PlayerInfo> creators;

  /// Owned pieces.
  int get count => records.where((r) => r.isOwned).length;
}

/// The bestiary seen through the closed collection.
class CollectionProgress {
  CollectionProgress(MutantCollection collection, Bestiary bestiary)
    : shelves = [
        for (final m in collection.mutants) _shelf(m, bestiary.records),
      ],
      oldAttempts = [
        for (final r in bestiary.records)
          if (r.mutantId == null || !collection.contains(r.mutantId!)) r,
      ];

  final List<MutantShelf> shelves;

  /// Records without a known mutant ("Staré pokusy").
  final List<CreatureRecord> oldAttempts;

  int get owned => shelves.where((s) => s.state == ShelfState.owned).length;

  int get total => shelves.length;

  MutantShelf? shelfOf(String mutantId) {
    for (final s in shelves) {
      if (s.mutant.id == mutantId) return s;
    }
    return null;
  }

  static MutantShelf _shelf(MutantDef mutant, List<CreatureRecord> all) {
    final records = [
      for (final r in all)
        if (r.mutantId == mutant.id) r,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final owned = records.where((r) => r.isOwned).toList();
    if (owned.isEmpty) {
      return MutantShelf(
        mutant: mutant,
        state: records.isEmpty ? ShelfState.unknown : ShelfState.seen,
        records: records,
      );
    }
    final best = owned
        .map((r) => r.rarity)
        .reduce((a, b) => a.index >= b.index ? a : b);
    return MutantShelf(
      mutant: mutant,
      state: ShelfState.owned,
      records: records,
      bestRarity: best,
      elements: {
        for (final r in owned)
          if (r.element != null) r.element!,
      },
      firstAt: owned.first.createdAt,
      creators: owned.first.creators,
    );
  }
}
