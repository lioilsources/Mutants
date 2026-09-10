/// Deterministic xorshift32 PRNG.
///
/// Own implementation instead of `dart:math` Random so that a seed + command
/// log replays identically regardless of SDK version. State is a single int,
/// so it can be copied into / out of [GameState] cheaply.
class Rng {
  Rng(int seed) : _state = _scramble(seed);

  Rng.fromState(this._state);

  int _state;

  int get state => _state;

  static int _scramble(int seed) {
    // splitmix-style mixing so that nearby seeds diverge immediately.
    var z = (seed + 0x9E3779B9) & 0xFFFFFFFF;
    z = ((z ^ (z >> 16)) * 0x85EBCA6B) & 0xFFFFFFFF;
    z = ((z ^ (z >> 13)) * 0xC2B2AE35) & 0xFFFFFFFF;
    z = (z ^ (z >> 16)) & 0xFFFFFFFF;
    return z == 0 ? 0x6D2B79F5 : z;
  }

  int _next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Uniform int in `[0, max)`.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be > 0');
    return _next() % max;
  }

  /// Uniform double in `[0, 1)`.
  double nextDouble() => _next() / 4294967296.0;

  bool chance(double probability) => nextDouble() < probability;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Stable 32-bit hash of two ints, used to derive per-creature seeds
  /// without consuming the gameplay RNG stream.
  static int mix(int a, int b) => _scramble((a * 31 + b) & 0xFFFFFFFF);
}
