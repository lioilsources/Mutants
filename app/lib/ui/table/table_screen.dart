import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

import '../../debug/debug_panel.dart';
import '../../host/local_host.dart';
import '../../host/seat.dart';
import '../../launch_options.dart';
import '../../services/bestiary_store.dart';
import '../bestiary/bestiary_screen.dart';
import '../hand/hand_area.dart';
import '../hand/incoming_passes.dart';
import '../hatch/hatch_overlay.dart';
import 'event_messages.dart';
import 'event_toast.dart';
import 'hazard_banner.dart';
import 'incubator_tube.dart';
import 'player_avatar.dart';
import 'pot_widget.dart';
import 'silhouette_board.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({
    super.key,
    required this.engine,
    required this.store,
    required this.seats,
    this.rules = const RulesConfig(),
    this.demo = false,
    this.openDebug = false,
  });

  final MutantEngine engine;
  final BestiaryStore store;
  final List<SeatMode> seats;
  final RulesConfig rules;

  /// Bots only, auto-follow, hatch cards close themselves.
  final bool demo;
  final bool openDebug;

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late final GameHost host;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final StreamSubscription<GameEvent> _events;
  final List<Timer> _timers = [];
  String? _toast;
  int _toastId = 0;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    host = GameHost(
      engine: widget.engine,
      seats: widget.seats,
      rules: widget.rules,
      takenNames: widget.store.bestiary.names,
      onHatched: widget.store.add,
      speed: LaunchOptions.speed,
    )..autoFollow = widget.demo;
    _events = host.events.listen(_onEvent);
    host.start();
    if (widget.openDebug) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scaffoldKey.currentState?.openEndDrawer(),
      );
    }
  }

  void _onEvent(GameEvent event) {
    if (!mounted) return;
    if (event is CreatureHatched && widget.demo) {
      _timers.add(Timer(const Duration(seconds: 5), host.acknowledgeHatch));
    }
    final message = messageFor(event, host);
    if (message == null) return;
    setState(() {
      _toast = message;
      _toastId++;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _openBestiary() async {
    final wasPaused = host.paused;
    host.setPaused(true);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BestiaryScreen(store: widget.store, engine: widget.engine),
      ),
    );
    host.setPaused(wasPaused);
  }

  @override
  void dispose() {
    _events.cancel();
    _toastTimer?.cancel();
    for (final timer in _timers) {
      timer.cancel();
    }
    host.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: DebugPanel(host: host),
      body: ListenableBuilder(
        listenable: host,
        builder: (context, _) => Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    host: host,
                    onBestiary: _openBestiary,
                    onDebug: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IncubatorTube(
                      level: host.state.incubator,
                      max: host.rules.incubatorMax,
                      frozen: host.state.incubatorFrozen,
                    ),
                  ),
                  EventToast(message: _toast, id: _toastId),
                  Expanded(child: _TableArea(host: host)),
                  HandArea(host: host),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: HandArea.height + 16,
              child: SafeArea(
                top: false,
                left: false,
                child: IncomingPasses(host: host),
              ),
            ),
            if (host.pendingHatch case final record?)
              Positioned.fill(
                child: HatchOverlay(
                  key: ValueKey(record.id),
                  record: record,
                  host: host,
                  store: widget.store,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.host,
    required this.onBestiary,
    required this.onDebug,
  });

  final GameHost host;
  final VoidCallback onBestiary;
  final VoidCallback onDebug;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Zpět',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              'Mutant č. ${host.state.hatchedCount + 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: host.autoFollow
                ? 'Přestat sledovat'
                : 'Sledovat hráče, který má co hodit',
            onPressed: () => host.setAutoFollow(!host.autoFollow),
            icon: Icon(
              host.autoFollow
                  ? Icons.visibility_rounded
                  : Icons.visibility_outlined,
            ),
          ),
          IconButton(
            tooltip: host.paused ? 'Pokračovat' : 'Pozastavit',
            onPressed: () => host.setPaused(!host.paused),
            icon: Icon(
              host.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Bestiář',
            onPressed: onBestiary,
            icon: const Icon(Icons.menu_book_rounded),
          ),
          IconButton(
            tooltip: 'Ladění',
            onPressed: onDebug,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
    );
  }
}

class _TableArea extends StatelessWidget {
  const _TableArea({required this.host});

  final GameHost host;

  @override
  Widget build(BuildContext context) {
    final state = host.state;
    final calling = playersToCall(state, host.catalog);
    final incoming = {for (final pass in state.passes) pass.to};

    Widget avatar(int seat) => DragTarget<HeldCard>(
      onWillAcceptWithDetails: (details) => seat != details.data.seat,
      onAcceptWithDetails: (details) =>
          host.passCard(details.data.seat, seat, details.data.card),
      builder: (context, candidates, _) => PlayerAvatar(
        initial: seatAvatars[seat].initial,
        color: seatAvatars[seat].color,
        name: seatAvatars[seat].name,
        mode: host.seats[seat],
        cards: state.players[seat].hand.length,
        viewed: seat == host.viewedSeat,
        calling: calling.contains(seat),
        incoming: incoming.contains(seat),
        dropHover: candidates.isNotEmpty,
        onTap: () => host.view(seat),
      ),
    );

    Widget column(Iterable<int> seats) => SizedBox(
      width: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final seat in seats) avatar(seat)],
      ),
    );

    final count = host.seats.length;
    return Row(
      children: [
        column([for (var s = 0; s < count; s += 2) s]),
        Expanded(
          child: Column(
            children: [
              HazardBanner(host: host),
              Expanded(
                child: DragTarget<HeldCard>(
                  onAcceptWithDetails: (details) =>
                      host.throwCard(details.data.seat, details.data.card),
                  builder: (context, candidates, _) => SilhouetteBoard(
                    host: host,
                    highlight: candidates.isNotEmpty,
                  ),
                ),
              ),
              PotWidget(host: host),
            ],
          ),
        ),
        column([for (var s = 1; s < count; s += 2) s]),
      ],
    );
  }
}
