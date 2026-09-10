import '../model/card.dart';
import '../model/catalog.dart';
import '../model/creature.dart';
import '../model/enums.dart';
import '../model/game_state.dart';
import '../model/name_tables.dart';
import '../rules/naming.dart';
import '../rules/rarity.dart';
import '../util/rng.dart';

/// Turns the current silhouette into a bestiary record (PLAN §4).
CreatureRecord buildCreatureRecord(
  GameState state,
  CardCatalog catalog,
  NameTables names, {
  required bool premature,
}) {
  final silhouette = state.silhouette;
  final config = state.config;
  CardDef defOf(int card) => catalog[state.defIdOf(card)];

  final partsInSlotOrder = <CardDef>[];
  final parts = <Slot, List<String>>{};
  for (final slot in Slot.values) {
    final fill = silhouette.slots[slot];
    if (fill == null) continue;
    final defs = [for (final card in fill.cards) defOf(card)];
    partsInSlotOrder.addAll(defs);
    parts[slot] = [for (final d in defs) d.id];
  }
  final seal = silhouette.seal == null ? null : defOf(silhouette.seal!);

  final element = dominantElement(
    partsInSlotOrder,
    sealElement: seal?.element,
  );
  final rarity = evaluateRarity(
    RarityInput(
      parts: partsInSlotOrder,
      stumps: Slot.values.length - silhouette.slots.length,
      fusions: silhouette.fusions,
      mutations: state.rules.mutationBonusNeedsOverwrite
          ? silhouette.mutationOverwrites
          : silhouette.mutations,
      hazardsMet: silhouette.hazardsMet,
      synchroThrows: silhouette.synchroThrows,
      premature: premature,
      chaosOriginsPerPoint: state.rules.chaosOriginsPerPoint,
    ),
  );

  Origin? firstOrigin(Slot slot) {
    final fill = silhouette.slots[slot];
    return fill == null ? null : defOf(fill.cards.first).origin;
  }

  final name = uniqueCreatureName(
    baseCreatureName(
      names,
      element: element,
      headOrigin: firstOrigin(Slot.head),
      torsoOrigin: firstOrigin(Slot.torso),
    ),
    state.takenNames,
  );

  final index = state.hatchedCount;
  return CreatureRecord(
    id:
        '${config.seed.toRadixString(36)}-'
        '${config.epochMs.toRadixString(36)}-$index',
    seed: Rng.mix(config.seed, index),
    parts: parts,
    seal: seal?.id,
    element: element,
    rarity: rarity.rarity,
    rarityReasons: rarity.reasons,
    stats: partsInSlotOrder.fold(Stats.zero, (sum, d) => sum + d.stats),
    ability: element == null ? names.stumpAbility : names.abilities[element]!,
    name: name,
    creators: config.players,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      config.epochMs + state.now,
      isUtc: true,
    ),
    expedition: config.expedition,
    premature: premature,
    durationMs: state.now - silhouette.startedAt,
  );
}
