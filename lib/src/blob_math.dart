import 'dart:math';
import 'dart:typed_data';

/// Utility class for all 3D particle mathematics.
///
/// Uses a flat [Float32List] for the base sphere (BUG-07 fix):
/// Points are packed as [x0,y0,z0, x1,y1,z1, ...].
/// Access via index `i*3`, `i*3+1`, `i*3+2`.
class BlobMath {
  /// Constant: 2π, used for time wrapping.
  static const double twoPi = pi * 2.0;

  /// Constant: golden angle in radians for Fibonacci lattice.
  static const double _goldenAngle = pi * (3.0 - 2.2360679774997896);

  /// Generates points evenly distributed on a unit sphere using the Fibonacci
  /// lattice algorithm, stored in a flat [Float32List] of length [samples * 3].
  ///
  /// Layout: [x0, y0, z0, x1, y1, z1, ...]
  ///
  /// BUG-01 fix: Guards against [samples] <= 1 to prevent division by zero.
  static Float32List generateFibonacciSphere(int samples) {
    assert(samples > 0, 'samples must be greater than 0');
    final buffer = Float32List(samples * 3);

    for (int i = 0; i < samples; i++) {
      // BUG-01: safe division — when samples == 1, y = 0.0
      final double y =
          samples > 1 ? 1.0 - (i / (samples - 1)) * 2.0 : 0.0;

      final double radiusAtY = sqrt((1.0 - y * y).clamp(0.0, 1.0));
      final double theta = _goldenAngle * i;

      buffer[i * 3] = cos(theta) * radiusAtY; // x
      buffer[i * 3 + 1] = y; // y
      buffer[i * 3 + 2] = sin(theta) * radiusAtY; // z
    }
    return buffer;
  }

  /// Wraps [time] to stay within [0, 2π * 100] to prevent floating-point
  /// precision degradation over long runtimes (LOGIC-01 fix).
  static double wrapTime(double time) {
    const double limit = twoPi * 100.0;
    return time % limit;
  }
}
