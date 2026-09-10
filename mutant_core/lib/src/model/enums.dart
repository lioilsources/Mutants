/// Card axes from PLAN §3. JSON uses the enum `name` (e.g. `"head"`).
library;

/// Slot na siluetě.
enum Slot { head, torso, front, back, tail, extra }

/// Element (named `ElementType` to avoid clashing with Flutter's `Element`).
enum ElementType { fire, water, ice, lightning, plant, stone, shadow }

/// Původ.
enum Origin { dino, insect, marine, bird, mammal, dragon, robot }

/// Vlastnosti – tags used by hazards and bonuses.
enum Tag { fangs, claws, wings, fins, shell, horns, extraEyes }

enum CardKind {
  /// Část – goes into its slot.
  part,

  /// Mutace – may overwrite an occupied slot.
  mutation,

  /// Elementární pečeť – stamped on the torso, overrides creature element.
  seal,

  /// Událost – never in hand, surfaces from the pot.
  hazard,
}

/// Rarita 0–5.
enum Rarity { common, uncommon, rare, epic, legendary, mythic }

T enumByName<T extends Enum>(List<T> values, String name) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('Unknown ${T.toString()} "$name"');
}
