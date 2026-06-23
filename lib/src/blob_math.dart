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

  /// Fast 3D noise approximation via sine/cosine wave interference.
  ///
  /// Avoids Perlin/Simplex overhead while producing organic, time-varying
  /// displacement. Returns a value in approximately [-1.0, 1.0].
  static double fastNoise3D(double x, double y, double z, double time) {
    return sin(x * 3.0 + time) * cos(y * 2.0 - time) * sin(z * 4.0 + time * 1.5);
  }

  /// Wraps [time] to stay within [0, 2π * 100] to prevent floating-point
  /// precision degradation over long runtimes (LOGIC-01 fix).
  static double wrapTime(double time) {
    const double limit = twoPi * 100.0;
    return time % limit;
  }

  /// In-place X-axis rotation applied to a [point] buffer at offset [base].
  /// [base] must be a multiple of 3 (index of x in a flat xyz buffer).
  static void rotateX(List<double> point, double angle) {
    final double cosA = cos(angle);
    final double sinA = sin(angle);
    final double y = point[1];
    final double z = point[2];
    point[1] = y * cosA - z * sinA;
    point[2] = y * sinA + z * cosA;
  }

  /// In-place Y-axis rotation.
  static void rotateY(List<double> point, double angle) {
    final double cosA = cos(angle);
    final double sinA = sin(angle);
    final double x = point[0];
    final double z = point[2];
    point[0] = x * cosA + z * sinA;
    point[2] = -x * sinA + z * cosA;
  }

  /// Perspective projection: converts a 3D point to a 2D screen position.
  ///
  /// LOGIC-03 fix: clamps the Z denominator to [0.5, 4.0] to prevent
  /// Inf / NaN in the output when [pz] is extreme (e.g., after dispersion).
  static void project(
    List<double> point,
    double centerX,
    double centerY,
    double radius,
    Float32List out,
    int outIndex,
  ) {
    // Clamp to prevent division by zero or negative denominator
    final double safeZ = (2.0 + point[2]).clamp(0.5, 4.0);
    final double scale = radius / safeZ;
    out[outIndex] = centerX + point[0] * scale * 2.0;
    out[outIndex + 1] = centerY + point[1] * scale * 2.0;
  }
}
