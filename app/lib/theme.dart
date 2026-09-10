import 'package:flutter/material.dart';
import 'package:mutant_core/mutant_core.dart';

/// Phase-1 placeholder look: a night lab where element colours are the only
/// colour language for cards and the incubator tube is the loudest thing.
abstract final class MutantColors {
  static const night = Color(0xFF231A3D);
  static const board = Color(0xFF30264F);
  static const boardEdge = Color(0xFF514379);
  static const chalk = Color(0xFFF4EEFF);
  static const mist = Color(0xFFB9ACD9);
  static const ink = Color(0xFF1B1430);
  static const healthy = Color(0xFF6EE7B7);
  static const warning = Color(0xFFFFB547);
  static const danger = Color(0xFFFF5D5D);
  static const hint = Color(0xFFFFE08A);

  static Color element(ElementType? element) => switch (element) {
    ElementType.fire => const Color(0xFFFF7043),
    ElementType.water => const Color(0xFF42A5F5),
    ElementType.ice => const Color(0xFFB3E5FC),
    ElementType.lightning => const Color(0xFFFFD54F),
    ElementType.plant => const Color(0xFF66BB6A),
    ElementType.stone => const Color(0xFFBCAAA4),
    ElementType.shadow => const Color(0xFF7E57C2),
    null => const Color(0xFF6D6485),
  };

  /// Text colour with enough contrast on [element].
  static Color onElement(ElementType? element) => switch (element) {
    ElementType.shadow || null => chalk,
    _ => ink,
  };

  static Color incubator(double level) => level >= 40
      ? healthy
      : level >= 20
      ? warning
      : danger;
}

/// Fredoka is a variable font, so the weight goes in as a variation too.
TextStyle fredoka(
  double size,
  int weight, {
  Color color = MutantColors.chalk,
  double height = 1.2,
}) => TextStyle(
  fontFamily: 'Fredoka',
  fontSize: size,
  height: height,
  color: color,
  fontWeight: switch (weight) {
    <= 400 => FontWeight.w400,
    <= 500 => FontWeight.w500,
    <= 600 => FontWeight.w600,
    _ => FontWeight.w700,
  },
  fontVariations: [FontVariation('wght', weight.toDouble())],
);

ThemeData buildMutantTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: MutantColors.boardEdge,
        brightness: Brightness.dark,
      ).copyWith(
        surface: MutantColors.night,
        onSurface: MutantColors.chalk,
        primary: MutantColors.healthy,
        onPrimary: MutantColors.ink,
        secondary: MutantColors.hint,
        onSecondary: MutantColors.ink,
      );
  final text = TextTheme(
    displaySmall: fredoka(40, 700, height: 1.05),
    headlineSmall: fredoka(26, 600),
    titleLarge: fredoka(22, 600),
    titleMedium: fredoka(18, 600),
    titleSmall: fredoka(15, 600),
    bodyLarge: fredoka(17, 400, height: 1.35),
    bodyMedium: fredoka(15, 400, height: 1.35),
    bodySmall: fredoka(13, 400, color: MutantColors.mist, height: 1.3),
    labelLarge: fredoka(15, 600),
    labelMedium: fredoka(13, 500),
    labelSmall: fredoka(11, 500, color: MutantColors.mist),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MutantColors.night,
    fontFamily: 'Fredoka',
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: MutantColors.night,
      foregroundColor: MutantColors.chalk,
      titleTextStyle: text.titleLarge,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: MutantColors.board),
    dialogTheme: const DialogThemeData(backgroundColor: MutantColors.board),
  );
}

/// Placeholder seat avatar: initials on a coloured disc. Emoji rendered as
/// .notdef boxes in the iOS simulator – inside Fredoka styles, with a fallback
/// family and with an explicit emoji font – so the prototype avoids them.
class SeatMark extends StatelessWidget {
  const SeatMark({
    super.key,
    required this.initial,
    required this.color,
    this.size = 24,
  });

  final String initial;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: fredoka(size * 0.4, 700, color: MutantColors.ink, height: 1),
      ),
    );
  }
}
