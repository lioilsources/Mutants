import 'package:mutant_core/mutant_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = engine.catalog;
  final parts = catalog.ofKind(CardKind.part).toList();

  group('deck v1 (PLAN §3)', () {
    test('80 physical cards', () => expect(catalog.deckSize, 80));

    test('60 parts, 10 per slot', () {
      expect(parts, hasLength(60));
      for (final slot in Slot.values) {
        expect(parts.where((p) => p.slot == slot), hasLength(10), reason: '$slot');
      }
    });

    test('every element and origin has ≥ 8 parts', () {
      for (final element in ElementType.values) {
        expect(
          parts.where((p) => p.element == element).length,
          greaterThanOrEqualTo(8),
          reason: '$element',
        );
      }
      for (final origin in Origin.values) {
        expect(
          parts.where((p) => p.origin == origin).length,
          greaterThanOrEqualTo(8),
          reason: '$origin',
        );
      }
    });

    test('8 mutations with quirks, 6 torso seals, 6 hazard cards', () {
      expect(catalog.ofKind(CardKind.mutation), hasLength(8));
      expect(catalog.ofKind(CardKind.mutation).every((m) => m.quirk != null), isTrue);
      final seals = catalog.ofKind(CardKind.seal).toList();
      expect(seals, hasLength(6));
      expect(seals.every((s) => s.slot == Slot.torso), isTrue);
      expect(seals.map((s) => s.element).toSet(), hasLength(6));
      expect(
        catalog.ofKind(CardKind.hazard).fold(0, (n, h) => n + h.copies),
        6,
      );
    });

    test('hazard requirements match PLAN §2', () {
      HazardRequirement req(String id) => catalog[id].requires!;
      expect(req('hazard_storm').slot, Slot.extra);
      expect(req('hazard_storm').tag, Tag.wings);
      expect(req('hazard_earthquake').slot, Slot.back);
      expect(req('hazard_hunger').slot, Slot.head);
      expect(req('hazard_hunger').tag, Tag.fangs);
      expect(req('hazard_flood').element, ElementType.water);
      expect(req('hazard_darkness').element, ElementType.shadow);
    });

    test('every hazard can be met by at least 3 parts', () {
      for (final hazard in catalog.ofKind(CardKind.hazard)) {
        expect(
          parts.where((p) => cardMeetsRequirement(p, hazard.requires!)).length,
          greaterThanOrEqualTo(3),
          reason: hazard.id,
        );
      }
    });

    test('labels cover every axis value', () {
      for (final (axis, values) in [
        ('slot', Slot.values),
        ('element', ElementType.values),
        ('origin', Origin.values),
        ('tag', Tag.values),
        ('kind', CardKind.values),
      ]) {
        for (final v in values) {
          expect(catalog.labels[axis]?[v.name], isNotNull, reason: '$axis.${v.name}');
        }
      }
    });
  });

  group('parsing', () {
    test('rejects a part without origin', () {
      expect(
        () => CardDef.fromJson({
          'id': 'x',
          'kind': 'part',
          'name': 'X',
          'slot': 'head',
          'element': 'fire',
        }),
        throwsFormatException,
      );
    });

    test('rejects duplicate ids', () {
      const def = CardDef(id: 'a', kind: CardKind.hazard, name: 'A', requires: HazardRequirement());
      expect(() => CardCatalog([def, def]), throwsFormatException);
    });
  });
}
