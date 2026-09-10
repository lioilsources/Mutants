import 'package:mutant_core/mutant_core.dart';

import '../host/local_host.dart';
import '../host/seat.dart';

class Scenario {
  const Scenario({
    required this.name,
    required this.description,
    required this.apply,
  });

  final String name;
  final String description;
  final void Function(GameHost host) apply;
}

/// Preset situations from PLAN §6.2, loaded with one tap. Each restarts the
/// game with empty hands; the pot keeps dealing as usual.
final scenarios = <Scenario>[
  Scenario(
    name: 'Chybí jen ocas',
    description:
        'Pět míst je obsazených, inkubátor je na 5. Ocas drží ${seatAvatars[1].name}.',
    apply: (host) {
      _fresh(host, minSeats: 2);
      for (final id in const [
        'head_trex',
        'torso_dragon',
        'front_trex',
        'back_dragon',
        'extra_dragon',
      ]) {
        final card = host.giveCard(0, id);
        if (card != null) host.throwCard(0, card);
      }
      host.giveCard(1, 'tail_fox');
      host.debug((ts) => DebugSetIncubator(ts, level: 5));
    },
  ),
  Scenario(
    name: 'Bouře, křídla má jen ${seatAvatars[2].name}',
    description: 'Nikdo jiný křídla nemá. Hodí je sama, nebo je pošle dál?',
    apply: (host) {
      _fresh(host, minSeats: 3);
      host
        ..giveCard(0, 'head_trex')
        ..giveCard(0, 'tail_fox')
        ..giveCard(1, 'back_crab')
        ..giveCard(1, 'front_mantis')
        ..giveCard(2, 'extra_dragonfly')
        ..giveCard(2, 'torso_beetle')
        ..debug((ts) => DebugForceHazard(ts, 'hazard_storm'));
    },
  ),
  Scenario(
    name: 'Dvě hlavy, fúze',
    description:
        '${seatAvatars[0].name} a ${seatAvatars[1].name} drží hlavu. Hoďte je naráz, nebo použijte Vynutit fúzi.',
    apply: (host) {
      _fresh(host, minSeats: 2);
      host
        ..giveCard(0, 'head_trex')
        ..giveCard(1, 'head_shark');
    },
  ),
];

void _fresh(GameHost host, {required int minSeats}) {
  host.restart(
    rules: host.rules.copyWith(handSize: 0),
    seats: [
      ...host.seats,
      for (var i = host.seats.length; i < minSeats; i++) SeatMode.careful,
    ],
  );
}
