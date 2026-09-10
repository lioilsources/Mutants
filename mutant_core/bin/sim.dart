// CLI balance simulation (PLAN §6.1).
//
//   dart run mutant_core:sim --players 3 --creatures 200 --seed 1
//   dart run mutant_core:sim --players 3 --sweep 1,1.5,2,3,4
import 'dart:io';

import 'package:mutant_core/io.dart';
import 'package:mutant_core/mutant_core.dart';

const _usage = '''
Usage: dart run mutant_core:sim [options]

  --players N          seats, all bots (1–5, default 3)
  --creatures N        creatures to hatch in total (default 200)
  --seed N             (default 1)
  --profiles a,b,c     bot profiles cycled over seats: hasty, careful, passer
                       (default hasty,careful,passer)
  --drain X            starting drainPerSec (default 4)
  --drain-per-hatch X  drain growth per hatched creature (default 0.5)
  --session N          creatures per play session, 0 = one session (default 5)
  --sweep a,b,c        run once per drainPerSec value and print a table
  --reaction-scale X   multiply every bot's reaction time (default 1)
''';

void main(List<String> arguments) {
  final Map<String, String> args;
  try {
    args = _parseArgs(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n$_usage');
    exitCode = 64;
    return;
  }
  if (args.containsKey('help')) {
    stdout.write(_usage);
    return;
  }

  final players = int.parse(args['players'] ?? '3');
  final creatures = int.parse(args['creatures'] ?? '200');
  final seed = int.parse(args['seed'] ?? '1');
  final session = int.parse(args['session'] ?? '5');
  final reactionScale = double.parse(args['reaction-scale'] ?? '1');
  final profiles = [
    for (final id in (args['profiles'] ?? 'hasty,careful,passer').split(','))
      switch (KidBotProfile.all[id.trim()]) {
        final profile? => profile.copyWith(
          reactionMs: (profile.reactionMs * reactionScale).round(),
        ),
        null => throw FormatException('Unknown profile "$id"'),
      },
  ];
  const defaults = RulesConfig();
  final rules = defaults.copyWith(
    drainPerSec: double.parse(args['drain'] ?? '${defaults.drainPerSec}'),
    drainPerHatch: double.parse(
      args['drain-per-hatch'] ?? '${defaults.drainPerHatch}',
    ),
  );

  final engine = loadEngine();
  SimOptions optionsFor(RulesConfig r) => SimOptions(
    players: players,
    creatures: creatures,
    seed: seed,
    profiles: profiles,
    rules: r,
    sessionLength: session,
  );

  stdout.writeln(
    'Mutant sim · players $players (${[for (var i = 0; i < players; i++) profiles[i % profiles.length].name].join(', ')})'
    ' · creatures $creatures · seed $seed · session $session'
    ' · drain +${rules.drainPerHatch}/hatch'
    '${reactionScale == 1 ? '' : ' · reaction ×$reactionScale'}',
  );

  final sweep = args['sweep'];
  if (sweep != null) {
    _printSweep(engine, [
      for (final v in sweep.split(',')) double.parse(v.trim()),
    ], optionsFor, rules);
    return;
  }

  final watch = Stopwatch()..start();
  final report = runSimulation(engine, optionsFor(rules));
  _printReport(report, engine.names, rules, session);
  stdout.writeln('\n(${report.sessions} sessions, '
      '${(report.simulatedMs / 60000).toStringAsFixed(1)} min simulated '
      'in ${watch.elapsedMilliseconds} ms)');
}

Map<String, String> _parseArgs(List<String> arguments) {
  final result = <String, String>{};
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '-h' || arg == '--help') {
      result['help'] = '';
      continue;
    }
    if (!arg.startsWith('--')) throw FormatException('Unexpected "$arg"');
    final eq = arg.indexOf('=');
    if (eq > 0) {
      result[arg.substring(2, eq)] = arg.substring(eq + 1);
    } else if (i + 1 < arguments.length) {
      result[arg.substring(2)] = arguments[++i];
    } else {
      throw FormatException('Missing value for $arg');
    }
  }
  return result;
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)} %';

String _sec(num ms) => '${(ms / 1000).toStringAsFixed(1)} s';

String _check(bool ok) => ok ? '✅' : '⚠️ ';

void _printReport(
  SimReport r,
  NameTables names,
  RulesConfig rules,
  int session,
) {
  final durations = r.durationsMs();
  final median = percentile(durations, 0.5);
  final n = r.count == 0 ? 1 : r.count;

  stdout.writeln('drainPerSec ${rules.drainPerSec}\n');
  if (r.truncated) {
    stdout.writeln('⚠️  stopped early: a session hatched nothing within the time limit');
  }
  stdout.writeln(
    '${_check(median >= 60000 && median <= 90000)} time per creature   '
    'median ${_sec(median)}  (p10 ${_sec(percentile(durations, 0.1))}, '
    'p90 ${_sec(percentile(durations, 0.9))})   target 60–90 s',
  );
  stdout.writeln(
    '${_check(r.prematureRate < 0.25)} premature hatches   '
    '${_pct(r.prematureRate)}   target < 25 %',
  );
  stdout.writeln(
    '${_check((r.rarePlusRate - 0.30).abs() <= 0.05)} rare+ (vzácný+)     '
    '${_pct(r.rarePlusRate)}   target ~30 %',
  );

  stdout.writeln('\nRarity');
  final counts = r.rarityCounts;
  for (final rarity in Rarity.values) {
    final c = counts[rarity]!;
    final bar = '█' * (c * 40 ~/ n);
    stdout.writeln(
      '  ${names.rarityLabel(rarity).padRight(11)} ${c.toString().padLeft(4)}  '
      '${_pct(c / n).padLeft(7)}  $bar',
    );
  }

  stdout.writeln('\nHazards    surfaced ${r.hazardsSurfaced}, met ${r.hazardsMet}, '
      'failed ${r.hazardsFailed}, cancelled by hatch ${r.hazardsCancelled} '
      '→ met ${_pct(r.hazardMetRate)} of resolved');
  stdout.writeln('Passes     sent ${r.passesSent}, caught ${r.passesCaught}, '
      'dropped ${r.passesDropped} → caught ${_pct(r.passCatchRate)}; '
      'relays ${r.relays}');
  stdout.writeln('Throws     placed ${r.placements}, bounced ${r.bounces}; '
      'synchro ${(r.synchroPlacements / n).toStringAsFixed(2)}/creature, '
      'fusions ${r.fusions}, mutation overwrites ${r.mutations}');

  if (session > 1) {
    stdout.writeln('\nBy creature # in session (drain ramps +${rules.drainPerHatch}/hatch)');
    for (var i = 0; i < session; i++) {
      final d = r.durationsMs(indexInSession: i);
      if (d.isEmpty) continue;
      final premature = r.creatures
          .where((c) => c.indexInSession == i && c.record.premature)
          .length;
      stdout.writeln(
        '  #${i + 1}  drain ${(rules.drainPerSec + i * rules.drainPerHatch).toStringAsFixed(1)}/s  '
        'median ${_sec(percentile(d, 0.5)).padLeft(7)}  '
        'premature ${_pct(premature / d.length).padLeft(7)}',
      );
    }
  }
}

void _printSweep(
  MutantEngine engine,
  List<double> drains,
  SimOptions Function(RulesConfig) optionsFor,
  RulesConfig base,
) {
  stdout.writeln(
    '\n drain │ median │ premature │ rare+  │ hazards met │ synchro/creature',
  );
  stdout.writeln('───────┼────────┼───────────┼────────┼─────────────┼─────────────────');
  for (final drain in drains) {
    final r = runSimulation(engine, optionsFor(base.copyWith(drainPerSec: drain)));
    final median = percentile(r.durationsMs(), 0.5);
    final n = r.count == 0 ? 1 : r.count;
    stdout.writeln(
      ' ${drain.toStringAsFixed(2).padLeft(5)} │ ${_sec(median).padLeft(6)} │'
      ' ${_pct(r.prematureRate).padLeft(9)} │ ${_pct(r.rarePlusRate).padLeft(6)} │'
      ' ${_pct(r.hazardMetRate).padLeft(11)} │ ${(r.synchroPlacements / n).toStringAsFixed(2).padLeft(8)}',
    );
  }
}
