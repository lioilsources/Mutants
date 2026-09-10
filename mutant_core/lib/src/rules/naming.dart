import '../model/card.dart';
import '../model/enums.dart';
import '../model/name_tables.dart';

/// Creature element: the seal wins; otherwise the most common element among
/// parts, ties broken by the earliest slot (head → extra).
/// [partsInSlotOrder] must list cards in [Slot] order.
ElementType? dominantElement(
  List<CardDef> partsInSlotOrder, {
  ElementType? sealElement,
}) {
  if (sealElement != null) return sealElement;
  final counts = <ElementType, int>{};
  final firstSeen = <ElementType, int>{};
  for (var i = 0; i < partsInSlotOrder.length; i++) {
    final element = partsInSlotOrder[i].element;
    if (element == null) continue;
    counts[element] = (counts[element] ?? 0) + 1;
    firstSeen.putIfAbsent(element, () => i);
  }
  ElementType? best;
  for (final element in counts.keys) {
    if (best == null ||
        counts[element]! > counts[best]! ||
        (counts[element] == counts[best] &&
            firstSeen[element]! < firstSeen[best]!)) {
      best = element;
    }
  }
  return best;
}

/// `prefix[element]-root[head origin]-suffix[torso origin]` → Pyro-Rexo-dračák.
/// Missing pieces use the stump entries (Šedo / Bezhlavo / bezbřichák).
String baseCreatureName(
  NameTables tables, {
  required ElementType? element,
  required Origin? headOrigin,
  required Origin? torsoOrigin,
}) {
  final prefix = element == null ? tables.stumpPrefix : tables.prefix[element]!;
  final root = headOrigin == null ? tables.stumpRoot : tables.root[headOrigin]!;
  final suffix = torsoOrigin == null
      ? tables.stumpSuffix
      : tables.suffix[torsoOrigin]!;
  return '$prefix-$root-$suffix';
}

/// Appends a Roman numeral (II, III, …) until the name is not in [taken].
String uniqueCreatureName(String base, Set<String> taken) {
  if (!taken.contains(base)) return base;
  for (var n = 2; ; n++) {
    final candidate = '$base ${romanNumeral(n)}';
    if (!taken.contains(candidate)) return candidate;
  }
}

String romanNumeral(int n) {
  if (n <= 0) throw ArgumentError.value(n, 'n', 'must be positive');
  const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
  const symbols = ['M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
  final buffer = StringBuffer();
  var rest = n;
  for (var i = 0; i < values.length; i++) {
    while (rest >= values[i]) {
      buffer.write(symbols[i]);
      rest -= values[i];
    }
  }
  return buffer.toString();
}
