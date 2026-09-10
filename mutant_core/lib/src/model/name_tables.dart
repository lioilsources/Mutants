import 'dart:convert';

import 'enums.dart';

/// Name + ability tables from `assets/names.json`.
class NameTables {
  const NameTables({
    required this.prefix,
    required this.root,
    required this.suffix,
    required this.stumpPrefix,
    required this.stumpRoot,
    required this.stumpSuffix,
    required this.abilities,
    required this.stumpAbility,
    required this.rarityLabels,
  });

  /// By dominant element.
  final Map<ElementType, String> prefix;

  /// By head origin.
  final Map<Origin, String> root;

  /// By torso origin.
  final Map<Origin, String> suffix;
  final String stumpPrefix;
  final String stumpRoot;
  final String stumpSuffix;
  final Map<ElementType, String> abilities;
  final String stumpAbility;
  final List<String> rarityLabels;

  factory NameTables.fromJsonString(String source) =>
      NameTables.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory NameTables.fromJson(Map<String, dynamic> json) {
    Map<K, String> table<K extends Enum>(List<K> values, String key) {
      final raw = (json[key] as Map<String, dynamic>).cast<String, String>();
      final result = {for (final e in raw.entries) enumByName(values, e.key): e.value};
      final missing = values.where((v) => !result.containsKey(v));
      if (missing.isNotEmpty) {
        throw FormatException('names.json "$key" is missing $missing');
      }
      return result;
    }

    final stump = (json['stump'] as Map<String, dynamic>).cast<String, String>();
    final rarity = (json['rarity'] as List).cast<String>();
    if (rarity.length != Rarity.values.length) {
      throw FormatException(
        'names.json "rarity" needs ${Rarity.values.length} labels',
      );
    }
    return NameTables(
      prefix: table(ElementType.values, 'prefix'),
      root: table(Origin.values, 'root'),
      suffix: table(Origin.values, 'suffix'),
      stumpPrefix: stump['prefix']!,
      stumpRoot: stump['root']!,
      stumpSuffix: stump['suffix']!,
      abilities: table(ElementType.values, 'abilities'),
      stumpAbility: json['stumpAbility'] as String,
      rarityLabels: List.unmodifiable(rarity),
    );
  }

  String rarityLabel(Rarity rarity) => rarityLabels[rarity.index];
}
