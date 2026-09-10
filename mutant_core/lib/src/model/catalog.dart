import 'dart:convert';

import 'card.dart';
import 'enums.dart';

/// All card definitions plus Czech labels for the axes (názvosloví).
/// Parsed from `assets/cards.json`; IO-free so the Flutter app can feed it
/// from rootBundle and the CLI/tests from a file.
class CardCatalog {
  CardCatalog(List<CardDef> cards, {this.labels = const {}})
    : cards = List.unmodifiable(cards),
      _byId = {for (final c in cards) c.id: c} {
    if (_byId.length != cards.length) {
      final seen = <String>{};
      final dup = cards.firstWhere((c) => !seen.add(c.id));
      throw FormatException('Duplicate card id "${dup.id}"');
    }
  }

  final List<CardDef> cards;
  final Map<String, CardDef> _byId;

  /// `labels['slot']['head'] == 'hlava'` etc.
  final Map<String, Map<String, String>> labels;

  factory CardCatalog.fromJsonString(String source) =>
      CardCatalog.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory CardCatalog.fromJson(Map<String, dynamic> json) {
    final labels = <String, Map<String, String>>{
      for (final e in (json['labels'] as Map<String, dynamic>? ?? {}).entries)
        e.key: (e.value as Map<String, dynamic>).cast<String, String>(),
    };
    return CardCatalog([
      for (final c in json['cards'] as List)
        CardDef.fromJson(c as Map<String, dynamic>),
    ], labels: labels);
  }

  CardDef operator [](String id) {
    final def = _byId[id];
    if (def == null) throw ArgumentError.value(id, 'id', 'unknown card');
    return def;
  }

  bool contains(String id) => _byId.containsKey(id);

  Iterable<CardDef> ofKind(CardKind kind) => cards.where((c) => c.kind == kind);

  /// Total physical cards (copies included).
  int get deckSize => cards.fold(0, (sum, c) => sum + c.copies);

  String label(String axis, Enum value) => labels[axis]?[value.name] ?? value.name;
}
