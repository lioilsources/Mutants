import 'dart:convert';

import '../model/creature.dart';
import '../model/enums.dart';

/// Local bestiary (v1 = one JSON file). Persistence is the app's job; this
/// class only holds records and (de)serializes them.
class Bestiary {
  Bestiary([Iterable<CreatureRecord> records = const []]) {
    records.forEach(add);
  }

  static const schemaVersion = 1;

  final List<CreatureRecord> _records = [];
  final Map<String, int> _indexById = {};

  List<CreatureRecord> get records => List.unmodifiable(_records);

  int get length => _records.length;

  Set<String> get names => {for (final r in _records) r.name};

  CreatureRecord? byId(String id) {
    final index = _indexById[id];
    return index == null ? null : _records[index];
  }

  /// Idempotent by id – a client that reconnects may receive a record twice.
  bool add(CreatureRecord record) {
    if (_indexById.containsKey(record.id)) return false;
    _indexById[record.id] = _records.length;
    _records.add(record);
    return true;
  }

  /// Kids may rename creatures freely.
  bool rename(String id, String name) {
    final index = _indexById[id];
    final trimmed = name.trim();
    if (index == null || trimmed.isEmpty) return false;
    _records[index] = _records[index].copyWith(name: trimmed);
    return true;
  }

  Iterable<CreatureRecord> filter({ElementType? element, Rarity? minRarity}) =>
      _records.where(
        (r) =>
            (element == null || r.element == element) &&
            (minRarity == null || r.rarity.index >= minRarity.index),
      );

  Map<String, dynamic> toJson() => {
    'schema': schemaVersion,
    'creatures': [for (final r in _records) r.toJson()],
  };

  factory Bestiary.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'] as int?;
    if (schema != schemaVersion) {
      throw FormatException('Unsupported bestiary schema $schema');
    }
    return Bestiary([
      for (final c in json['creatures'] as List)
        CreatureRecord.fromJson(c as Map<String, dynamic>),
    ]);
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory Bestiary.fromJsonString(String source) =>
      Bestiary.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
