import 'enums.dart';

class Stats {
  const Stats({this.strength = 0, this.speed = 0, this.defense = 0});

  final int strength;
  final int speed;
  final int defense;

  static const zero = Stats();

  Stats operator +(Stats other) => Stats(
    strength: strength + other.strength,
    speed: speed + other.speed,
    defense: defense + other.defense,
  );

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
    strength: json['strength'] as int? ?? 0,
    speed: json['speed'] as int? ?? 0,
    defense: json['defense'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'strength': strength,
    'speed': speed,
    'defense': defense,
  };

  @override
  bool operator ==(Object other) =>
      other is Stats &&
      other.strength == strength &&
      other.speed == speed &&
      other.defense == defense;

  @override
  int get hashCode => Object.hash(strength, speed, defense);

  @override
  String toString() => 'Stats($strength/$speed/$defense)';
}

/// What a hazard needs from the creature. All non-null fields must match
/// on a single placed card; [element] alone is also satisfied by a seal.
class HazardRequirement {
  const HazardRequirement({this.slot, this.tag, this.element});

  final Slot? slot;
  final Tag? tag;
  final ElementType? element;

  factory HazardRequirement.fromJson(Map<String, dynamic> json) =>
      HazardRequirement(
        slot: json['slot'] == null
            ? null
            : enumByName(Slot.values, json['slot'] as String),
        tag: json['tag'] == null
            ? null
            : enumByName(Tag.values, json['tag'] as String),
        element: json['element'] == null
            ? null
            : enumByName(ElementType.values, json['element'] as String),
      );
}

/// A card definition from `assets/cards.json`. Physical copies in the deck
/// are identified by an int instance id and point back to a [CardDef].
class CardDef {
  const CardDef({
    required this.id,
    required this.kind,
    required this.name,
    this.slot,
    this.element,
    this.origin,
    this.tags = const {},
    this.stats = Stats.zero,
    this.quirk,
    this.requires,
    this.copies = 1,
  });

  final String id;
  final CardKind kind;
  final String name;
  final Slot? slot;
  final ElementType? element;
  final Origin? origin;
  final Set<Tag> tags;
  final Stats stats;

  /// Zvláštnost added by a mutation.
  final String? quirk;

  /// Only for hazards.
  final HazardRequirement? requires;
  final int copies;

  bool get isPlaceable => kind != CardKind.hazard;

  factory CardDef.fromJson(Map<String, dynamic> json) {
    final kind = enumByName(CardKind.values, json['kind'] as String);
    final def = CardDef(
      id: json['id'] as String,
      kind: kind,
      name: json['name'] as String,
      slot: json['slot'] == null
          ? null
          : enumByName(Slot.values, json['slot'] as String),
      element: json['element'] == null
          ? null
          : enumByName(ElementType.values, json['element'] as String),
      origin: json['origin'] == null
          ? null
          : enumByName(Origin.values, json['origin'] as String),
      tags: {
        for (final t in (json['tags'] as List? ?? const []))
          enumByName(Tag.values, t as String),
      },
      stats: json['stats'] == null
          ? Stats.zero
          : Stats.fromJson(json['stats'] as Map<String, dynamic>),
      quirk: json['quirk'] as String?,
      requires: json['requires'] == null
          ? null
          : HazardRequirement.fromJson(
              json['requires'] as Map<String, dynamic>,
            ),
      copies: json['copies'] as int? ?? 1,
    );
    def._validate();
    return def;
  }

  void _validate() {
    String? problem;
    switch (kind) {
      case CardKind.part:
      case CardKind.mutation:
        if (slot == null || element == null || origin == null) {
          problem = 'needs slot, element and origin';
        }
      case CardKind.seal:
        if (slot != Slot.torso || element == null) {
          problem = 'needs slot "torso" and element';
        }
      case CardKind.hazard:
        if (requires == null) problem = 'needs "requires"';
    }
    if (kind == CardKind.mutation && quirk == null) problem = 'needs quirk';
    if (problem != null) {
      throw FormatException('Card "$id" (${kind.name}) $problem');
    }
  }

  @override
  String toString() => 'CardDef($id)';
}
