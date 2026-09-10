import 'package:flutter/material.dart';

import '../../host/local_host.dart';
import '../../theme.dart';

/// Kotlík: cards left, with a ring filling up towards the next deal.
class PotWidget extends StatelessWidget {
  const PotWidget({super.key, required this.host});

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final interval = host.rules.dealIntervalMs;
    final next = state.nextDealAt;
    final progress = next == null || interval == 0
        ? null
        : 1 - ((next - state.now) / interval).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: progress ?? 0,
                    strokeWidth: 4,
                    color: MutantColors.healthy,
                    backgroundColor: MutantColors.boardEdge,
                  ),
                ),
                Text(
                  '${state.pot.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('kotlík', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
