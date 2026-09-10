import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('incubator', () {
    test('drains at drainPerSec', () {
      final h = Harness(frozen: false);
      expect(h.incubator, 60);
      h.apply(const Tick(5000));
      expect(h.incubator, closeTo(40, 1e-9));
    });

    test('caps at 100', () {
      final h = Harness();
      h.setIncubator(95);
      h.place(0, 'head_trex', 100);
      expect(h.incubator, 100);
    });

    test('empty incubator = premature hatch with stumps, reset, faster drain', () {
      final h = Harness(frozen: false);
      h.apply(const Tick(15000));
      expect(h.state.hatchedCount, 0);

      final events = h.apply(const Tick(15001));
      final hatched = one<CreatureHatched>(events);
      expect(hatched.ts, 15000);
      final record = hatched.record;
      expect(record.premature, isTrue);
      expect(record.stumps, Slot.values);
      expect(record.element, isNull);
      expect(record.name, 'Šedo-Bezhlavo-bezbřichák');
      expect(record.rarity, Rarity.common);
      expect(h.state.hatchedCount, 1);
      expect(h.state.drainPerSec, 4.5);
      expect(h.incubator, closeTo(60, 0.01));
    });

    test('premature creature keeps what was placed', () {
      final h = Harness(frozen: false);
      h.place(0, 'head_trex', 100);
      h.place(1, 'torso_dragon', 200);
      // 79.2 left at 200 ms → empty at 20 000 ms; the next one would be at 33 334.
      final record = one<CreatureHatched>(h.apply(const Tick(25000))).record;

      expect(record.parts.keys, unorderedEquals([Slot.head, Slot.torso]));
      expect(record.name, 'Pyro-Rexo-dračák');
      expect(
        record.rarityReasons,
        containsAll(const [RarityReason('premature', -1), RarityReason('stumps', -2)]),
      );
    });
  });

  group('hatching', () {
    test('all 6 slots filled hatches a full record', () {
      final h = Harness();
      final events = h.placeAll(fireCreature);
      final record = one<CreatureHatched>(events).record;

      expect(record.premature, isFalse);
      expect(record.stumps, isEmpty);
      expect(record.parts[Slot.head], ['head_trex']);
      expect(record.element, ElementType.fire);
      expect(record.name, 'Pyro-Rexo-dračák');
      expect(record.ability, 'Chrlí jiskřičky');
      expect(record.stats, const Stats(strength: 12, speed: 9, defense: 6));
      expect(record.rarityReasons, [const RarityReason('harmony', 2)]);
      expect(record.rarity, Rarity.rare);
      expect(record.creators.map((c) => c.name), ['Hráč 0', 'Hráč 1']);
      expect(record.createdAt, DateTime.fromMillisecondsSinceEpoch(epoch + 6000, isUtc: true));
      expect(record.durationMs, 6000);

      expect(h.silhouette.slots, isEmpty);
      expect(h.silhouette.startedAt, 6000);
      expect(h.incubator, 60);
      expect(h.state.drainPerSec, 4.5);
      expect(h.state.pot, hasLength(80), reason: 'creature cards return to the pot');
    });

    test('hatch now (debug) hatches a partial creature as not premature', () {
      final h = Harness();
      h.place(0, 'head_trex', 100);
      final record = one<CreatureHatched>(h.apply(const DebugHatchNow(200))).record;
      expect(record.premature, isFalse);
      expect(record.stumps, hasLength(5));
    });
  });
}
