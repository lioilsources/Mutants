import 'package:mutant_core/mutant_core.dart';

import '../host/local_host.dart';
import '../host/seat.dart';

class Scenario {
  const Scenario({
    required this.name,
    required this.description,
    required this.apply,
    this.collection,
  });

  final String name;
  final String description;
  final void Function(GameHost host) apply;

  /// Only for collection rules (true), only for free rules (false), or both.
  final bool? collection;
}

/// Preset situations from PLAN §6.2, loaded with one tap. Each restarts the
/// game with empty hands; the pot keeps dealing as usual.
final scenarios = <Scenario>[
  Scenario(
    name: 'Chybí jen ocas',
    description:
        'Žralomedvěd bez ocasu, inkubátor je na 5. Liščí ohon drží ${seatAvatars[1].name}.',
    collection: true,
    apply: (host) {
      _fresh(host, minSeats: 2);
      _placeAll(host, const [
        'head_shark',
        'torso_polar_bear',
        'front_walrus',
        'back_hare',
        'extra_shark_fin',
      ]);
      host.giveCard(1, 'tail_fox');
      host.debug((ts) => DebugSetIncubator(ts, level: 5));
    },
  ),
  Scenario(
    name: 'Kdo to bude? Čtyři žraloci',
    description:
        'Na stole je jen žraločí hlava. Každý drží zadní nohy jiného žraločího mutanta – a jedny cizí.',
    collection: true,
    apply: (host) {
      _fresh(host, minSeats: 2);
      _placeAll(host, const ['head_shark']);
      host
        ..giveCard(0, 'back_crab')
        ..giveCard(0, 'back_heron')
        ..giveCard(0, 'back_grasshopper')
        ..giveCard(1, 'back_hare')
        ..giveCard(1, 'back_tracks');
    },
  ),
  Scenario(
    name: 'Bouře, křídla má jen ${seatAvatars[2].name}',
    description:
        'Drakobot čeká na dračí křídla a přišla Bouře. Hodí je sama, nebo je pošle dál?',
    collection: true,
    apply: (host) {
      _fresh(host, minSeats: 3);
      _placeAll(host, const ['head_dragon', 'torso_robot']);
      host
        ..giveCard(0, 'front_dragon')
        ..giveCard(0, 'tail_metal')
        ..giveCard(1, 'back_tracks')
        ..giveCard(1, 'extra_antenna')
        ..giveCard(2, 'extra_dragon')
        ..debug((ts) => DebugForceHazard(ts, 'hazard_storm'));
    },
  ),
  Scenario(
    name: 'Žolíci',
    description: 'Dva Mutageny v ruce. Třetí už se na tvora nevejde.',
    collection: true,
    apply: (host) {
      _fresh(host, minSeats: 1);
      _placeAll(host, const ['head_owl', 'back_hare']);
      host
        ..giveCard(0, 'mut_eyes_everywhere')
        ..giveCard(0, 'mut_six_arms')
        ..giveCard(0, 'mut_forked_tail');
    },
  ),
  Scenario(
    name: 'Chybí jen ocas (volně)',
    description:
        'Pět míst je obsazených, inkubátor je na 5. Ocas drží ${seatAvatars[1].name}.',
    collection: false,
    apply: (host) {
      _fresh(host, minSeats: 2);
      _placeAll(host, const [
        'head_trex',
        'torso_dragon',
        'front_trex',
        'back_dragon',
        'extra_dragon',
      ]);
      host.giveCard(1, 'tail_fox');
      host.debug((ts) => DebugSetIncubator(ts, level: 5));
    },
  ),
  Scenario(
    name: 'Dvě hlavy, fúze',
    collection: false,
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

/// Seat 0 throws [ids] one after another.
void _placeAll(GameHost host, List<String> ids) {
  for (final id in ids) {
    final card = host.giveCard(0, id);
    if (card != null) host.throwCard(0, card);
  }
}

void _fresh(GameHost host, {required int minSeats}) {
  host.restart(
    rules: host.rules.copyWith(handSize: 0),
    seats: [
      ...host.seats,
      for (var i = host.seats.length; i < minSeats; i++) SeatMode.careful,
    ],
  );
}
