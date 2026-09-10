import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

CardDef part(ElementType element, Origin origin) => CardDef(
  id: '${element.name}_${origin.name}',
  kind: CardKind.part,
  name: 'test',
  slot: Slot.head,
  element: element,
  origin: origin,
);

List<CardDef> mixed(int distinctOrigins, {int count = 6}) => [
  for (var i = 0; i < count; i++)
    part(ElementType.values[i % 2], Origin.values[i % distinctOrigins]),
];

RarityResult rate({
  List<CardDef>? parts,
  int stumps = 0,
  int fusions = 0,
  int mutations = 0,
  int hazardsMet = 0,
  int synchroThrows = 0,
  bool premature = false,
}) => evaluateRarity(
  RarityInput(
    parts: parts ?? mixed(1),
    stumps: stumps,
    fusions: fusions,
    mutations: mutations,
    hazardsMet: hazardsMet,
    synchroThrows: synchroThrows,
    premature: premature,
  ),
);

void main() {
  test('chaos: +1 per 3 distinct origins', () {
    expect(rate(parts: mixed(2)).raw, 0);
    expect(rate(parts: mixed(3)).raw, 1);
    expect(rate(parts: mixed(5)).raw, 1);
    expect(rate(parts: mixed(6)).raw, 2);
    expect(rate(parts: mixed(6)).reasons, [const RarityReason('chaos', 2)]);
  });

  test('chaos step is configurable', () {
    RarityResult withStep(int distinctOrigins) => evaluateRarity(
      RarityInput(parts: mixed(distinctOrigins), stumps: 0, chaosOriginsPerPoint: 5),
    );
    expect(withStep(4).raw, 0);
    expect(withStep(5).raw, 1);
  });

  test('harmony: +2 when all parts share one element', () {
    final parts = [for (var i = 0; i < 6; i++) part(ElementType.ice, Origin.bird)];
    expect(rate(parts: parts).reasons, [const RarityReason('harmony', 2)]);
  });

  test('harmony needs a complete creature', () {
    final parts = [for (var i = 0; i < 4; i++) part(ElementType.ice, Origin.bird)];
    expect(rate(parts: parts, stumps: 2).reasons.map((r) => r.code), isNot(contains('harmony')));
  });

  test('chaos or harmony, never both', () {
    final parts = [for (var i = 0; i < 6; i++) part(ElementType.ice, Origin.values[i])];
    final result = rate(parts: parts);
    expect(result.raw, 2);
    expect(result.reasons, hasLength(1));
  });

  test('fusion and mutation +1 each regardless of count', () {
    expect(rate(parts: mixed(2), fusions: 2).raw, 1);
    expect(rate(parts: mixed(2), mutations: 3).raw, 1);
  });

  test('+1 per met hazard', () {
    expect(rate(parts: mixed(2), hazardsMet: 2).raw, 2);
  });

  test('+1 for at least 3 synchro throws', () {
    expect(rate(parts: mixed(2), synchroThrows: 2).raw, 0);
    expect(rate(parts: mixed(2), synchroThrows: 3).raw, 1);
  });

  test('−1 premature, −1 per 2 stumps', () {
    final four = mixed(2, count: 4);
    expect(rate(parts: four, stumps: 2, fusions: 1, mutations: 1, hazardsMet: 1).raw, 2);
    expect(rate(parts: four, stumps: 2, premature: true, hazardsMet: 3).raw, 1);
    expect(rate(parts: mixed(2, count: 3), stumps: 3, hazardsMet: 3).raw, 2);
  });

  test('clamped to 0–5', () {
    expect(rate(parts: const [], stumps: 6, premature: true).rarity, Rarity.common);
    final best = rate(parts: mixed(6), fusions: 1, mutations: 1, hazardsMet: 3, synchroThrows: 5);
    expect(best.raw, 8);
    expect(best.rarity, Rarity.mythic);
  });
}
