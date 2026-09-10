import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('throw into slot', () {
    test('part lands in its own empty slot, +10', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      final placed = one<CardPlaced>(h.throwCard(0, card, 100));

      expect(placed.slot, Slot.head);
      expect(placed.kind, PlacementKind.place);
      expect(h.player(0).hand, isNot(contains(card)));
      expect(h.silhouette.slots[Slot.head]!.cards, [card]);
      expect(h.incubator, 10);
    });

    test('occupied slot bounces back to hand without penalty', () {
      final h = Harness();
      h.place(0, 'head_trex', 100);
      final card = h.give(1, 'head_shark', ts: 1000);
      final events = h.throwCard(1, card, 1000);

      expect(one<CardBounced>(events).reason, BounceReason.slotOccupied);
      expect(has<CardPlaced>(events), isFalse);
      expect(h.player(1).hand, contains(card));
      expect(h.incubator, 10);
    });

    test('card not in hand is rejected', () {
      final h = Harness();
      final card = h.give(0, 'head_trex');
      final events = h.throwCard(1, card, 100);
      expect(one<CommandRejected>(events).reason, RejectReason.cardNotInHand);
    });
  });

  group('fusion (Konflikt o slot)', () {
    test('two players on the same slot within 80 ms fuse', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      final events = h.place(1, 'head_shark', 1080);

      final placed = one<CardPlaced>(events);
      expect(placed.kind, PlacementKind.fusion);
      expect(placed.synchro, isTrue);
      expect(has<SynchroUpgraded>(events), isTrue);
      final fill = h.silhouette.slots[Slot.head]!;
      expect(fill.cards, hasLength(2));
      expect(fill.fused, isTrue);
      expect(h.silhouette.fusions, 1);
      expect(h.silhouette.synchroThrows, 2);
      expect(h.incubator, 10 + 25 + 15);
    });

    test('81 ms apart: host timestamp wins, second bounces', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      expect(has<CardBounced>(h.place(1, 'head_shark', 1081)), isTrue);
    });

    test('same player cannot fuse with themselves', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      expect(has<CardBounced>(h.place(0, 'head_shark', 1010)), isTrue);
    });

    test('a fused slot takes no third part', () {
      final h = Harness(players: 3);
      h.place(0, 'head_trex', 1000);
      h.place(1, 'head_shark', 1020);
      expect(has<CardBounced>(h.place(2, 'head_wolf', 1040)), isTrue);
    });

    test('no fusion onto a mutation', () {
      final h = Harness();
      h.place(0, 'mut_two_heads', 1000);
      expect(has<CardBounced>(h.place(1, 'head_trex', 1010)), isTrue);
    });
  });

  group('mutation', () {
    test('overwrites an occupied slot and sends the old part to the pot', () {
      final h = Harness();
      final trex = h.give(0, 'head_trex');
      h.throwCard(0, trex, 100);
      final placed = one<CardPlaced>(h.place(1, 'mut_two_heads', 5000));

      expect(placed.kind, PlacementKind.overwrite);
      expect(placed.replaced, [trex]);
      expect(h.silhouette.slots[Slot.head]!.mutated, isTrue);
      expect(h.silhouette.mutations, 1);
      expect(h.state.pot, contains(trex));
      expect(h.incubator, 20);
    });

    test('overwrites both halves of a fusion', () {
      final h = Harness();
      h.place(0, 'head_trex', 1000);
      h.place(1, 'head_shark', 1010);
      final placed = one<CardPlaced>(h.place(0, 'mut_two_heads', 3000));
      expect(placed.replaced, hasLength(2));
      expect(h.silhouette.slots[Slot.head]!.cards, hasLength(1));
    });

    test('can also fill an empty slot', () {
      final h = Harness();
      final placed = one<CardPlaced>(h.place(0, 'mut_forked_tail', 100));
      expect(placed.kind, PlacementKind.place);
      expect(h.silhouette.slots[Slot.tail]!.mutated, isTrue);
      expect(h.silhouette.mutations, 1);
    });
  });

  group('elemental seal', () {
    test('stamps the torso without occupying the slot; a second one bounces', () {
      final h = Harness();
      final placed = one<CardPlaced>(h.place(0, 'seal_water', 100));
      expect(placed.kind, PlacementKind.seal);
      expect(h.silhouette.seal, isNotNull);
      expect(h.silhouette.slots.containsKey(Slot.torso), isFalse);

      expect(one<CardBounced>(h.place(1, 'seal_fire', 2000)).reason, BounceReason.sealTaken);
    });

    test('overrides the creature element regardless of parts', () {
      final h = Harness();
      h.place(1, 'seal_water', 100);
      final record = one<CreatureHatched>(h.placeAll(fireCreature)).record;
      expect(record.element, ElementType.water);
      expect(record.seal, 'seal_water');
      expect(record.name, startsWith('Aqua-'));
    });
  });
}
