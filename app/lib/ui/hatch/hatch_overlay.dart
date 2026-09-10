import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../../services/bestiary_store.dart';
import '../../theme.dart';
import 'creature_card.dart';
import 'rename_dialog.dart';

/// Líhnutí: the game clock is stopped while everyone looks at the new
/// creature. The record is already in the bestiary.
class HatchOverlay extends StatelessWidget {
  const HatchOverlay({
    super.key,
    required this.record,
    required this.host,
    required this.store,
  });

  final CreatureRecord record;
  final GameHost host;
  final BestiaryStore store;

  Future<void> _rename(BuildContext context) async {
    final name = await showRenameDialog(context, record.name);
    if (name == null) return;
    store.rename(record.id, name);
    host.renamePendingHatch(name);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MutantColors.night.withValues(alpha: 0.9),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    record.premature ? 'Vylíhl se dřív!' : 'Vylíhl se!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1),
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: CreatureCard(
                      record: record,
                      catalog: host.catalog,
                      names: host.engine.names,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rename(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Přejmenovat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: host.acknowledgeHatch,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Další mutant'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
