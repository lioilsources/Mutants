import 'package:mutant_core/mutant_core.dart';

import '../../host/local_host.dart';
import '../labels.dart';

/// Short feedback line for the events a child should notice; null = silent.
String? messageFor(GameEvent event, GameHost host) {
  final catalog = host.catalog;
  final viewed = host.viewedSeat;
  String name(String defId) => catalog[defId].name;

  return switch (event) {
    CardPlaced(:final relay) when relay => 'Štafeta! +25',
    CardPlaced(kind: PlacementKind.fusion) => 'Fúze! Dvojitá část',
    CardPlaced(:final synchro) when synchro => 'Synchro! +25',
    CardPlaced(kind: PlacementKind.overwrite) => 'Mutace přepsala část',
    CardPlaced(:final card)
        when host.rules.closedCollection &&
            catalog[host.state.defIdOf(card)].kind == CardKind.mutation =>
      'Žolík zastoupil díl',
    CardPlaced(kind: PlacementKind.seal) => 'Pečeť změnila element tvora',
    CardBounced(:final player, :final reason) when player == viewed =>
      switch (reason) {
        BounceReason.sealTaken => 'Pečeť už na trupu je',
        BounceReason.slotOccupied => 'Tohle místo už je obsazené',
        BounceReason.noFit => 'Tenhle díl k němu nepasuje',
        BounceReason.wildLimit => 'Víc žolíků už se na něj nevejde',
      },
    EggEmpty() => 'Vejce bylo prázdné – zkusíme to znovu',
    CommandRejected(:final command, reason: RejectReason.onCooldown)
        when command is PassCard && command.from == viewed =>
      'Předávat jde jednou za ${host.rules.passCooldownMs ~/ 1000} sekundy',
    HazardSurfaced(:final defId) =>
      '${name(defId)}! ${requirementText(catalog, catalog[defId].requires!)}',
    HazardResolved(:final defId, :final met) =>
      met ? 'Zvládnuto: ${name(defId)} +15' : 'Nezvládnuto: ${name(defId)} −25',
    PassCaught() => 'Chyceno! +5',
    PassDropped() => 'Karta spadla do kotlíku',
    CardReturned(:final player) when player == viewed =>
      'Kotlík si vzal kartu, která nikam nepasovala',
    _ => null,
  };
}
