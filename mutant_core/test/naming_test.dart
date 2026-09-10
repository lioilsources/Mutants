import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final names = engine.names;

  test('prefix[element] + root[head origin] + suffix[torso origin]', () {
    expect(
      baseCreatureName(
        names,
        element: ElementType.fire,
        headOrigin: Origin.dino,
        torsoOrigin: Origin.dragon,
      ),
      'Pyro-Rexo-dračák',
    );
  });

  test('stumps get their own name pieces', () {
    expect(
      baseCreatureName(names, element: null, headOrigin: null, torsoOrigin: Origin.robot),
      'Šedo-Bezhlavo-robík',
    );
  });

  test('no two combinations produce the same base name', () {
    final all = <String>{};
    for (final e in ElementType.values) {
      for (final h in Origin.values) {
        for (final t in Origin.values) {
          all.add(baseCreatureName(names, element: e, headOrigin: h, torsoOrigin: t));
        }
      }
    }
    expect(all, hasLength(7 * 7 * 7));
  });

  test('duplicates get Roman numerals', () {
    expect(uniqueCreatureName('Pyro-Rexo-dračák', {}), 'Pyro-Rexo-dračák');
    expect(uniqueCreatureName('X', {'X'}), 'X II');
    expect(uniqueCreatureName('X', {'X', 'X II', 'X III'}), 'X IV');
    expect([for (final n in [1, 4, 9, 14, 40, 1999]) romanNumeral(n)], [
      'I', 'IV', 'IX', 'XIV', 'XL', 'MCMXCIX',
    ]);
  });

  group('dominant element', () {
    CardDef p(ElementType e) => CardDef(
      id: e.name,
      kind: CardKind.part,
      name: e.name,
      slot: Slot.head,
      element: e,
      origin: Origin.bird,
    );

    test('seal wins', () {
      expect(
        dominantElement([p(ElementType.fire)], sealElement: ElementType.ice),
        ElementType.ice,
      );
    });

    test('majority, ties broken by the earlier slot', () {
      final fire = p(ElementType.fire);
      final ice = p(ElementType.ice);
      expect(dominantElement([fire, ice, ice]), ElementType.ice);
      expect(dominantElement([ice, fire, fire, ice]), ElementType.ice);
      expect(dominantElement(const []), isNull);
    });
  });

  test('engine keeps names unique within a session and against the bestiary', () {
    final h = Harness();
    expect(one<CreatureHatched>(h.placeAll(fireCreature)).record.name, 'Pyro-Rexo-dračák');
    expect(
      one<CreatureHatched>(h.placeAll(fireCreature, from: 10000)).record.name,
      'Pyro-Rexo-dračák II',
    );

    final fromBestiary = Harness(takenNames: {'Pyro-Rexo-dračák'});
    expect(
      one<CreatureHatched>(fromBestiary.placeAll(fireCreature)).record.name,
      'Pyro-Rexo-dračák II',
    );
  });
}
