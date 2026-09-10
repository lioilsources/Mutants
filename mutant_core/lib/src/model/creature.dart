import 'card.dart';
import 'config.dart';
import 'enums.dart';

/// One line of the rarity explanation, e.g. `fusion +1`.
class RarityReason {
  const RarityReason(this.code, this.delta);

  /// `chaos`, `harmony`, `fusion`, `mutation`, `hazard`, `synchro`,
  /// `premature`, `stumps`.
  final String code;
  final int delta;

  Map<String, dynamic> toJson() => {'code': code, 'delta': delta};

  factory RarityReason.fromJson(Map<String, dynamic> json) =>
      RarityReason(json['code'] as String, json['delta'] as int);

  @override
  bool operator ==(Object other) =>
      other is RarityReason && other.code == code && other.delta == delta;

  @override
  int get hashCode => Object.hash(code, delta);

  @override
  String toString() => '$code ${delta >= 0 ? '+' : ''}$delta';
}

/// Bestiář záznam. The visual is rendered from [parts] (phase 2), no image
/// is stored, so records stay small and portable.
class CreatureRecord {
  const CreatureRecord({
    required this.id,
    required this.seed,
    required this.parts,
    required this.seal,
    required this.element,
    required this.rarity,
    required this.rarityReasons,
    required this.stats,
    required this.ability,
    required this.name,
    required this.creators,
    required this.createdAt,
    required this.premature,
    required this.durationMs,
    this.expedition,
  });

  final String id;
  final int seed;

  /// Card definition ids per occupied slot (two when fused).
  final Map<Slot, List<String>> parts;
  final String? seal;

  /// Null only for a creature hatched with no parts at all.
  final ElementType? element;
  final Rarity rarity;
  final List<RarityReason> rarityReasons;
  final Stats stats;
  final String ability;
  final String name;
  final List<PlayerInfo> creators;
  final DateTime createdAt;
  final String? expedition;
  final bool premature;
  final int durationMs;

  /// Pahýly.
  List<Slot> get stumps =>
      Slot.values.where((s) => !parts.containsKey(s)).toList();

  CreatureRecord copyWith({String? name, String? expedition}) => CreatureRecord(
    id: id,
    seed: seed,
    parts: parts,
    seal: seal,
    element: element,
    rarity: rarity,
    rarityReasons: rarityReasons,
    stats: stats,
    ability: ability,
    name: name ?? this.name,
    creators: creators,
    createdAt: createdAt,
    premature: premature,
    durationMs: durationMs,
    expedition: expedition ?? this.expedition,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'seed': seed,
    'parts': {for (final e in parts.entries) e.key.name: e.value},
    'seal': seal,
    'element': element?.name,
    'rarity': rarity.index,
    'rarityReasons': [for (final r in rarityReasons) r.toJson()],
    'stats': stats.toJson(),
    'ability': ability,
    'name': name,
    'creators': [for (final c in creators) c.toJson()],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'expedition': expedition,
    'premature': premature,
    'durationMs': durationMs,
  };

  factory CreatureRecord.fromJson(Map<String, dynamic> json) => CreatureRecord(
    id: json['id'] as String,
    seed: json['seed'] as int,
    parts: {
      for (final e in (json['parts'] as Map<String, dynamic>).entries)
        enumByName(Slot.values, e.key): (e.value as List).cast<String>(),
    },
    seal: json['seal'] as String?,
    element: json['element'] == null
        ? null
        : enumByName(ElementType.values, json['element'] as String),
    rarity: Rarity.values[json['rarity'] as int],
    rarityReasons: [
      for (final r in json['rarityReasons'] as List)
        RarityReason.fromJson(r as Map<String, dynamic>),
    ],
    stats: Stats.fromJson(json['stats'] as Map<String, dynamic>),
    ability: json['ability'] as String,
    name: json['name'] as String,
    creators: [
      for (final c in json['creators'] as List)
        PlayerInfo.fromJson(c as Map<String, dynamic>),
    ],
    createdAt: DateTime.parse(json['createdAt'] as String),
    expedition: json['expedition'] as String?,
    premature: json['premature'] as bool,
    durationMs: json['durationMs'] as int,
  );
}
