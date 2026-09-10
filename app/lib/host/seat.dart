import 'dart:ui' show Color;

import 'package:mutant_core/mutant_core.dart';

/// Who controls a seat on this device (puppet mode).
enum SeatMode {
  human('Člověk'),
  hasty('Zbrklý'),
  careful('Opatrný'),
  passer('Předávač'),
  paused('Pauza');

  const SeatMode(this.label);

  final String label;

  KidBotProfile? get botProfile => switch (this) {
    SeatMode.hasty => KidBotProfile.hasty,
    SeatMode.careful => KidBotProfile.careful,
    SeatMode.passer => KidBotProfile.passer,
    SeatMode.human || SeatMode.paused => null,
  };
}

/// Fixed seat identities for the prototype (max 5 players). [emoji] goes into
/// bestiary records; the UI draws [initial] on [color].
const seatAvatars = [
  (emoji: '🦊', name: 'Liška', initial: 'L', color: Color(0xFFFF9E6B)),
  (emoji: '🐸', name: 'Žabka', initial: 'Ža', color: Color(0xFF8BD88B)),
  (emoji: '🐙', name: 'Chobotnice', initial: 'Ch', color: Color(0xFFF5A3C7)),
  (emoji: '🦉', name: 'Sova', initial: 'S', color: Color(0xFFD9B77E)),
  (emoji: '🐢', name: 'Želva', initial: 'Že', color: Color(0xFF6CCFC2)),
];
