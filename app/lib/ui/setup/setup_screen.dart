import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../host/seat.dart';
import '../../services/bestiary_store.dart';
import '../../theme.dart';
import '../bestiary/bestiary_screen.dart';
import '../table/table_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.engine, required this.store});

  final MutantEngine engine;
  final BestiaryStore store;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _seats = [SeatMode.human, SeatMode.careful, SeatMode.passer];
  bool _planRules = false;

  void _play() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableScreen(
          engine: widget.engine,
          store: widget.store,
          seats: List.of(_seats),
          rules: _planRules ? RulesConfig.v1 : const RulesConfig(),
        ),
      ),
    );
  }

  void _openBestiary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BestiaryScreen(store: widget.store, engine: widget.engine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              children: [
                Text('Mutant', style: text.displaySmall),
                const SizedBox(height: 8),
                Text(
                  'Házejte spolu části zvířat do kotlíku a vylíhněte nového tvora.',
                  style: text.bodyLarge?.copyWith(color: MutantColors.mist),
                ),
                const SizedBox(height: 32),
                Text('Hráči', style: text.titleMedium),
                const SizedBox(height: 8),
                for (var i = 0; i < _seats.length; i++)
                  _SeatRow(
                    index: i,
                    mode: _seats[i],
                    onChanged: (mode) => setState(() => _seats[i] = mode),
                    onRemove: _seats.length > 1
                        ? () => setState(() => _seats.removeAt(i))
                        : null,
                  ),
                if (_seats.length < seatAvatars.length)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _seats.add(SeatMode.careful)),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Přidat hráče'),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Pravidla', style: text.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Doporučená')),
                    ButtonSegment(value: true, label: Text('Plán v1')),
                  ],
                  selected: {_planRules},
                  onSelectionChanged: (s) =>
                      setState(() => _planRules = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _planRules
                      ? 'Pět karet, po každém hodu se dobírá, inkubátor chladne rychle.'
                      : 'Kotlík rozdává kartu každých 6 sekund, jeden mutant trvá asi minutu.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: _play,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: text.titleMedium,
                  ),
                  child: const Text('Hrát'),
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: widget.store,
                  builder: (context, _) => OutlinedButton(
                    onPressed: _openBestiary,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text('Bestiář (${widget.store.bestiary.length})'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({
    required this.index,
    required this.mode,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final SeatMode mode;
  final ValueChanged<SeatMode> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final avatar = seatAvatars[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SeatMark(initial: avatar.initial, color: avatar.color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              avatar.name,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          DropdownButton<SeatMode>(
            value: mode,
            underline: const SizedBox.shrink(),
            items: [
              for (final m in SeatMode.values.where(
                (m) => m != SeatMode.paused,
              ))
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (m) => m == null ? null : onChanged(m),
          ),
          IconButton(
            tooltip: 'Odebrat hráče',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
