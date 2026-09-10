/// `--dart-define` switches for demos and screenshots, e.g.
/// `flutter run --dart-define=MUTANT_DEMO=true --dart-define=MUTANT_SPEED=2`.
abstract final class LaunchOptions {
  /// Skip setup: three bot seats with auto-follow; hatch cards close themselves.
  static const demo = bool.fromEnvironment('MUTANT_DEMO');

  /// Start screen: `setup` (default), `table`, `debug` or `bestiary`.
  static const screen = String.fromEnvironment('MUTANT_SCREEN');

  /// Game clock multiplier.
  static final double speed =
      double.tryParse(const String.fromEnvironment('MUTANT_SPEED')) ?? 1;
}
