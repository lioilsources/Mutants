import 'dart:convert';

import '../rules/naming.dart';
import 'catalog.dart';
import 'enums.dart';

/// One mutant of the closed collection (PLAN-KOLEKCE §2): a fixed recipe of
/// six part cards.
class MutantDef {
  const MutantDef({
    required this.id,
    required this.name,
    required this.origins,
    required this.tier,
    required this.parts,
  });

  final String id;
  final String name;

  /// One origin for a pure ancestor, two for a hybrid (front half first).
  final List<Origin> origins;

  /// 2 = prapředek, 0 = kříženec; base rarity (calibrated in sim).
  final int tier;

  /// Card definition id per slot, all six slots.
  final Map<Slot, String> parts;

  bool get isAncestor => origins.length == 1;

  /// Number of slots in which the two recipes differ.
  int distanceTo(MutantDef other) =>
      Slot.values.where((s) => parts[s] != other.parts[s]).length;

  factory MutantDef.fromJson(Map<String, dynamic> json) => MutantDef(
    id: json['id'] as String,
    name: json['name'] as String,
    origins: [
      for (final o in json['origins'] as List)
        enumByName(Origin.values, o as String),
    ],
    tier: json['tier'] as int? ?? 0,
    parts: {
      for (final e in (json['parts'] as Map<String, dynamic>).entries)
        enumByName(Slot.values, e.key): e.value as String,
    },
  );

  @override
  String toString() => 'MutantDef($id)';
}

/// The closed collection from `assets/collection.json`. IO-free like
/// [CardCatalog]; [validate] checks it against the cards.
class MutantCollection {
  MutantCollection(List<MutantDef> mutants)
    : mutants = List.unmodifiable(mutants),
      _byId = {for (final m in mutants) m.id: m} {
    if (_byId.length != mutants.length) {
      final seen = <String>{};
      final dup = mutants.firstWhere((m) => !seen.add(m.id));
      throw FormatException('Duplicate mutant id "${dup.id}"');
    }
    for (final m in mutants) {
      for (final slot in Slot.values) {
        final card = m.parts[slot];
        if (card == null) {
          throw FormatException('Mutant "${m.id}" has no ${slot.name}');
        }
        (_bySlotCard[slot] ??= {}).putIfAbsent(card, () => []).add(m);
      }
    }
  }

  final List<MutantDef> mutants;
  final Map<String, MutantDef> _byId;
  final Map<Slot, Map<String, List<MutantDef>>> _bySlotCard = {};

  factory MutantCollection.fromJsonString(String source) =>
      MutantCollection.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory MutantCollection.fromJson(Map<String, dynamic> json) =>
      MutantCollection([
        for (final m in json['mutants'] as List)
          MutantDef.fromJson(m as Map<String, dynamic>),
      ]);

  int get length => mutants.length;

  MutantDef operator [](String id) {
    final def = _byId[id];
    if (def == null) throw ArgumentError.value(id, 'id', 'unknown mutant');
    return def;
  }

  MutantDef? tryGet(String id) => _byId[id];

  bool contains(String id) => _byId.containsKey(id);

  /// Mutants that use [cardId] in [slot].
  List<MutantDef> withPart(Slot slot, String cardId) =>
      _bySlotCard[slot]?[cardId] ?? const [];

  /// Every part card id used by some recipe.
  Set<String> get usedCards => {for (final m in mutants) ...m.parts.values};

  /// Element of the recipe: most common among its parts, ties to the
  /// earlier slot; a seal overrides it.
  ElementType? dominantElementOf(
    MutantDef mutant,
    CardCatalog catalog, {
    ElementType? sealElement,
  }) => dominantElement([
    for (final slot in Slot.values) catalog[mutant.parts[slot]!],
  ], sealElement: sealElement);

  /// Throws [FormatException] naming the broken mutant when the collection
  /// does not fit the cards or the rules (PLAN-KOLEKCE §4.1).
  void validate(CardCatalog catalog, {int maxWildPerCreature = 2}) {
    final recipes = <String, MutantDef>{};
    for (final m in mutants) {
      for (final slot in Slot.values) {
        final id = m.parts[slot]!;
        if (!catalog.contains(id)) {
          throw FormatException('Mutant "${m.id}": unknown card "$id"');
        }
        final def = catalog[id];
        if (def.kind != CardKind.part) {
          throw FormatException('Mutant "${m.id}": "$id" is not a part');
        }
        if (def.slot != slot) {
          throw FormatException(
            'Mutant "${m.id}": "$id" belongs to ${def.slot!.name}, not ${slot.name}',
          );
        }
      }
      final key = [for (final s in Slot.values) m.parts[s]].join('|');
      if (recipes[key] case final other?) {
        throw FormatException(
          'Mutant "${m.id}" has the same recipe as "${other.id}"',
        );
      }
      recipes[key] = m;

      final partOrigins = {
        for (final id in m.parts.values) catalog[id].origin!,
      };
      if (partOrigins.length != m.origins.toSet().length ||
          !partOrigins.containsAll(m.origins)) {
        throw FormatException(
          'Mutant "${m.id}": origins ${m.origins.map((o) => o.name)} '
          'do not match its parts ${partOrigins.map((o) => o.name)}',
        );
      }
    }
    for (var i = 0; i < mutants.length; i++) {
      for (var j = i + 1; j < mutants.length; j++) {
        final d = mutants[i].distanceTo(mutants[j]);
        if (d <= maxWildPerCreature) {
          throw FormatException(
            'Mutant "${mutants[j].id}" differs from "${mutants[i].id}" in only '
            '$d slots (needs > $maxWildPerCreature)',
          );
        }
      }
    }
  }
}

/// What a part "knows" (PLAN-KOLEKCE §6.2), from `assets/moves.json`.
/// The engine does not use it; the reveal and the Blender script do.
class PartMove {
  const PartMove(this.move, this.label);

  /// Shared motion id, e.g. `roar`.
  final String move;

  /// Czech caption, e.g. „Zařve“.
  final String label;
}

class MoveTable {
  MoveTable({required this.moveSlots, required this.parts});

  /// Motion id → slot it belongs to.
  final Map<String, Slot> moveSlots;
  final Map<String, PartMove> parts;

  factory MoveTable.fromJsonString(String source) =>
      MoveTable.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory MoveTable.fromJson(Map<String, dynamic> json) => MoveTable(
    moveSlots: {
      for (final e in (json['moves'] as Map<String, dynamic>).entries)
        e.key: enumByName(
          Slot.values,
          (e.value as Map<String, dynamic>)['slot'] as String,
        ),
    },
    parts: {
      for (final e in (json['parts'] as Map<String, dynamic>).entries)
        e.key: PartMove(
          (e.value as Map<String, dynamic>)['move'] as String,
          (e.value as Map<String, dynamic>)['label'] as String,
        ),
    },
  );

  PartMove? operator [](String cardId) => parts[cardId];

  /// Basic motion per slot, used when a part has no own motion (M4 set).
  static const basicMoves = {
    Slot.head: 'roar',
    Slot.torso: 'puff',
    Slot.front: 'slash',
    Slot.back: 'hop',
    Slot.tail: 'whip',
    Slot.extra: 'flap',
  };
}
