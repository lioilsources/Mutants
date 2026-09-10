import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  CreatureRecord hatch(List<String> parts, {int from = 1000, Harness? harness}) {
    final h = harness ?? Harness();
    return one<CreatureHatched>(h.placeAll(parts, from: from)).record;
  }

  test('JSON round trip keeps every field', () {
    final h = Harness();
    h.apply(const DebugForceHazard(0, 'hazard_storm'));
    h.place(1, 'seal_ice', 500);
    final record = hatch(fireCreature, harness: h);

    final restored = Bestiary.fromJsonString(Bestiary([record]).toJsonString());
    expect(restored.records.single.toJson(), record.toJson());
  });

  test('adding the same record twice is a no-op (reconnect)', () {
    final record = hatch(fireCreature);
    final bestiary = Bestiary();
    expect(bestiary.add(record), isTrue);
    expect(bestiary.add(record), isFalse);
    expect(bestiary.length, 1);
  });

  test('kids can rename; blank names are ignored', () {
    final record = hatch(fireCreature);
    final bestiary = Bestiary([record]);
    expect(bestiary.rename(record.id, '  Ohnivák  '), isTrue);
    expect(bestiary.byId(record.id)!.name, 'Ohnivák');
    expect(bestiary.rename(record.id, '   '), isFalse);
    expect(bestiary.rename('nope', 'X'), isFalse);
  });

  test('filter by element and minimum rarity', () {
    final h = Harness();
    final fire = hatch(fireCreature, harness: h);
    final mixed = hatch(
      ['head_shark', 'torso_beetle', 'front_mantis', 'back_hare', 'tail_metal', 'extra_bat'],
      from: 10000,
      harness: h,
    );
    final bestiary = Bestiary([fire, mixed]);

    expect(bestiary.filter(element: ElementType.fire).map((r) => r.id), [fire.id]);
    expect(bestiary.filter(minRarity: Rarity.rare).map((r) => r.id), [fire.id]);
    expect(bestiary.filter(), hasLength(2));
  });

  test('unknown schema is rejected', () {
    expect(
      () => Bestiary.fromJson({'schema': 99, 'creatures': []}),
      throwsFormatException,
    );
  });
}
