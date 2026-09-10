import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../host/local_host.dart';
import '../host/seat.dart';
import '../theme.dart';
import '../ui/labels.dart';
import 'scenarios.dart';

/// Puppet-mode DebugPanel (PLAN §6.2), opened from the table's tune button.
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key, required this.host});

  final GameHost host;

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  double _fuseSeconds = 5;
  int _giveSeat = 0;
  String? _giveDefId;
  int _passFrom = 1;
  int _passTo = 0;

  GameHost get host => widget.host;

  void _simulatePass(int from, int to) {
    if (from == to) return;
    final hand = host.state.players[from].hand;
    final card = hand.isNotEmpty
        ? hand.first
        : host.giveCard(from, host.catalog.ofKind(CardKind.part).first.id);
    if (card != null) host.passCard(from, to, card);
  }

  /// Two seats throw a part for the same empty slot at the same moment.
  void _forceFusion() {
    final empty = host.state.silhouette.emptySlots;
    if (empty.isEmpty || host.seats.length < 2) return;
    final parts = host.catalog
        .ofKind(CardKind.part)
        .where((d) => d.slot == empty.first)
        .toList();
    final a = host.viewedSeat;
    final b = (a + 1) % host.seats.length;
    final first = host.giveCard(a, parts[0].id);
    final second = host.giveCard(b, parts[1].id);
    if (first == null || second == null) return;
    host.throwCard(a, first);
    host.throwCard(b, second);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Drawer(
      width: 348,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: host,
          builder: (context, _) {
            final state = host.state;
            final seatCount = host.seats.length;
            final giveSeat = math.min(_giveSeat, seatCount - 1);
            final passFrom = math.min(_passFrom, seatCount - 1);
            final passTo = math.min(_passTo, seatCount - 1);
            DropdownButton<int> seatPicker(int value, ValueChanged<int> set) =>
                DropdownButton<int>(
                  value: value,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (var s = 0; s < seatCount; s++)
                      DropdownMenuItem(
                        value: s,
                        child: SeatMark(
                          initial: seatAvatars[s].initial,
                          color: seatAvatars[s].color,
                          size: 28,
                        ),
                      ),
                  ],
                  onChanged: (s) => setState(() => set(s!)),
                );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Ladění', style: text.headlineSmall)),
                    Text(formatClock(state.now), style: text.titleSmall),
                  ],
                ),
                const _Section('Hodiny'),
                Row(
                  children: [
                    IconButton(
                      tooltip: host.paused ? 'Pokračovat' : 'Pozastavit',
                      onPressed: () => host.setPaused(!host.paused),
                      icon: Icon(
                        host.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: host.speed,
                        min: 0.25,
                        max: 2,
                        divisions: 7,
                        label: '${host.speed}×',
                        onChanged: host.setSpeed,
                      ),
                    ),
                    Text('${host.speed.toStringAsFixed(2)}×'),
                  ],
                ),
                const _Section('Inkubátor'),
                _LabeledSlider(
                  label: 'Hladina ${state.incubator.round()}',
                  value: state.incubator,
                  max: host.rules.incubatorMax,
                  onChanged: (v) =>
                      host.debug((ts) => DebugSetIncubator(ts, level: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zmrazit'),
                  value: state.incubatorFrozen,
                  onChanged: (v) =>
                      host.debug((ts) => DebugSetIncubator(ts, frozen: v)),
                ),
                _LabeledSlider(
                  label: 'Drain ${state.drainPerSec.toStringAsFixed(2)} za sekundu',
                  value: state.drainPerSec,
                  max: 6,
                  divisions: 24,
                  onChanged: (v) => host.debug((ts) => DebugSetDrain(ts, v)),
                ),
                const _Section('Hráči'),
                for (var seat = 0; seat < seatCount; seat++)
                  Row(
                    children: [
                      SeatMark(
                        initial: seatAvatars[seat].initial,
                        color: seatAvatars[seat].color,
                      ),
                      const SizedBox(width: 8),
                      Text(seatAvatars[seat].name, style: text.bodyMedium),
                      const Spacer(),
                      DropdownButton<SeatMode>(
                        value: host.seats[seat],
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final mode in SeatMode.values)
                            DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                        ],
                        onChanged: (mode) => host.setSeat(seat, mode!),
                      ),
                    ],
                  ),
                const _Section('Událost'),
                _LabeledSlider(
                  label: 'Zápalka ${_fuseSeconds.round()} s',
                  value: _fuseSeconds,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (v) => setState(() => _fuseSeconds = v),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final def in host.catalog.ofKind(CardKind.hazard))
                      OutlinedButton(
                        onPressed: () => host.debug(
                          (ts) => DebugForceHazard(
                            ts,
                            def.id,
                            fuseMs: (_fuseSeconds * 1000).round(),
                          ),
                        ),
                        child: Text(def.name),
                      ),
                  ],
                ),
                const _Section('Vnutit kartu'),
                Row(
                  children: [
                    seatPicker(giveSeat, (s) => _giveSeat = s),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _giveDefId,
                        hint: const Text('vyber kartu'),
                        items: [
                          for (final def in host.catalog.cards.where(
                            (d) => d.isPlaceable,
                          ))
                            DropdownMenuItem(
                              value: def.id,
                              child: Text(
                                def.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (id) => setState(() => _giveDefId = id),
                      ),
                    ),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: _giveDefId == null
                      ? null
                      : () => host.giveCard(giveSeat, _giveDefId!),
                  child: const Text('Dát kartu'),
                ),
                const _Section('Předání a fúze'),
                Row(
                  children: [
                    const Text('Od'),
                    const SizedBox(width: 8),
                    seatPicker(passFrom, (s) => _passFrom = s),
                    const SizedBox(width: 16),
                    const Text('pro'),
                    const SizedBox(width: 8),
                    seatPicker(passTo, (s) => _passTo = s),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: seatCount < 2 || passFrom == passTo
                      ? null
                      : () => _simulatePass(passFrom, passTo),
                  child: const Text('Simulovat předání'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: seatCount < 2 ? null : _forceFusion,
                  child: const Text('Vynutit fúzi'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => host.debug((ts) => DebugHatchNow(ts)),
                  child: const Text('Vylíhnout teď'),
                ),
                const _Section('Scénáře'),
                for (final scenario in scenarios)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(scenario.name),
                    subtitle: Text(scenario.description),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () {
                      scenario.apply(host);
                      Navigator.of(context).pop();
                    },
                  ),
                const _Section('Poslední události'),
                for (final event in host.recentEvents.take(25))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '${formatClock(event.ts)}  $event',
                      style: text.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Text(
        title,
        style: fredoka(17, 600, color: MutantColors.hint),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
