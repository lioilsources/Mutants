import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../theme.dart';
import '../labels.dart';
import '../widgets/pill.dart';

/// Karta mutanta (text version). Shared by the hatch overlay and the bestiary.
class CreatureCard extends StatelessWidget {
  const CreatureCard({
    super.key,
    required this.record,
    required this.catalog,
    required this.names,
  });

  final CreatureRecord record;
  final CardCatalog catalog;
  final NameTables names;

  String _cardName(String id) => catalog.contains(id) ? catalog[id].name : id;

  @override
  Widget build(BuildContext context) {
    final color = MutantColors.element(record.element);
    final on = MutantColors.onElement(record.element);
    final text = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: MutantColors.board,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: fredoka(30, 700, color: on, height: 1.05),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RarityPips(rarity: record.rarity, color: on),
                    const SizedBox(width: 10),
                    Text(
                      names.rarityLabel(record.rarity),
                      style: fredoka(16, 600, color: on),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.ability, style: text.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(label: 'síla', value: record.stats.strength),
                    _Stat(label: 'rychlost', value: record.stats.speed),
                    _Stat(label: 'obrana', value: record.stats.defense),
                  ],
                ),
                const SizedBox(height: 16),
                for (final slot in Slot.values)
                  _PartLine(
                    label: catalog.label('slot', slot),
                    value:
                        record.parts[slot]?.map(_cardName).join(' + ') ??
                        'pahýl',
                    stump: !record.parts.containsKey(slot),
                  ),
                if (record.seal case final seal?)
                  _PartLine(label: 'pečeť', value: _cardName(seal)),
                if (record.rarityReasons.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final reason in record.rarityReasons)
                        Pill(
                          '${signed(reason.delta)} ${rarityReasonLabel(reason.code)}',
                          background: reason.delta >= 0
                              ? MutantColors.healthy.withValues(alpha: 0.2)
                              : MutantColors.danger.withValues(alpha: 0.2),
                          fontSize: 13,
                        ),
                    ],
                  ),
                ],
                if (record.premature) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Vylíhl se dřív, než byl hotový – inkubátor vychladl.',
                    style: text.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'Tvůrci: ${record.creators.map((c) => c.name).join(', ')}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Five dots, filled up to the rarity level.
class RarityPips extends StatelessWidget {
  const RarityPips({super.key, required this.rarity, required this.color});

  final Rarity rarity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i < Rarity.values.length; i++)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= rarity.index ? color : null,
              border: Border.all(color: color, width: 1.5),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: text.headlineSmall),
          Text(label, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _PartLine extends StatelessWidget {
  const _PartLine({
    required this.label,
    required this.value,
    this.stump = false,
  });

  final String label;
  final String value;
  final bool stump;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: text.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: stump
                  ? text.bodyMedium?.copyWith(color: MutantColors.mist)
                  : text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
