import 'package:flutter/material.dart';

import '../../host/local_host.dart';
import '../../theme.dart';
import '../labels.dart';

/// Active Událost with what it needs and how long the fuse has left.
class HazardBanner extends StatelessWidget {
  const HazardBanner({super.key, required this.host});

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final hazard = state.hazard;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: hazard == null
          ? const SizedBox(width: double.infinity)
          : Builder(
              builder: (context) {
                final def = host.catalog[state.defIdOf(hazard.card)];
                final total = hazard.expiresAt - hazard.surfacedAt;
                final left = (hazard.expiresAt - state.now).clamp(0, total);
                final text = Theme.of(context).textTheme;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: MutantColors.danger.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MutantColors.danger, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(def.name, style: text.titleMedium),
                          ),
                          Text(
                            '${(left / 1000).ceil()} s',
                            style: text.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        requirementText(host.catalog, def.requires!),
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : left / total,
                          minHeight: 6,
                          color: MutantColors.danger,
                          backgroundColor: MutantColors.board,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
