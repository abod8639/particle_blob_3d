import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

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

  /// Projects 3D sphere particles onto a 2D viewport with organic noise displacement,
  /// multi-touch dispersion, and perspective rotation.
  static void projectParticles({
    required int count,
    required double radius,
    required double blobiness,
    required double dispersion,
    required double rotationX,
    required double rotationY,
    required double time,
    required double viewportWidth,
    required double viewportHeight,
    required List<Offset> activeTouches,
    required Float32List baseSphere,
    required Float32List projectedPoints,
    required double autoRotationSpeed,
    required double noiseFrequency,
    required double viewDistance,
  }) {
    final double centerX = viewportWidth / 2.0;
    final double centerY = viewportHeight / 2.0;

    // Auto-rotation angle derived from time and autoRotationSpeed
    final double autoRotY = time * autoRotationSpeed;

    // Precalculate trigonometric functions for the frame
    final double totalRotY = autoRotY + rotationY;
    final double cosRotY = cos(totalRotY);
    final double sinRotY = sin(totalRotY);

    final double cosRotX = cos(rotationX);
    final double sinRotX = sin(rotationX);

    // Precalculate time constant for noise function
    final double time1_5 = time * 1.5;

    // Cache variables for touch interaction
    final bool hasPointers = activeTouches.isNotEmpty;
    final int touchCount = activeTouches.length;
    final double doubleRadius = radius * 2.0;

    for (int i = 0; i < count; i++) {
      final int base = i * 3;

      // Extract coordinates to local variables
      double px = baseSphere[base];
      double py = baseSphere[base + 1];
      double pz = baseSphere[base + 2];

      // Apply organic noise displacement (blob morphing) with custom noiseFrequency
      final double f = noiseFrequency;
      final double noise = sin(px * 3.0 * f + time) *
                           cos(py * 2.0 * f - time) *
                           sin(pz * 4.0 * f + time1_5);

      final double displacement = 1.0 + noise * 0.3 * blobiness;
      px *= displacement;
      py *= displacement;
      pz *= displacement;

      // Direction-aware touch dispersion
      if (hasPointers) {
        final double screenX = centerX + px * radius;
        final double screenY = centerY + py * radius;
        double extraPush = 0.0;

        for (int t = 0; t < touchCount; t++) {
          final Offset touch = activeTouches[t];
          final double dx = screenX - touch.dx;
          final double dy = screenY - touch.dy;
          final double dist = sqrt(dx * dx + dy * dy);
          final double influence = (1.0 - (dist / doubleRadius).clamp(0.0, 1.0));
          extraPush += dispersion * influence * 2.0;
        }

        final double pushScale = 1.0 + extraPush;
        px *= pushScale;
        py *= pushScale;
        pz *= pushScale;
      } else if (dispersion > 0.0) {
        // Controller-driven uniform radial dispersion
        final double pushScale = 1.0 + dispersion;
        px *= pushScale;
        py *= pushScale;
        pz *= pushScale;
      }

      // Apply rotations (Y-axis first, then X-axis)
      final double xAfterY = px * cosRotY + pz * sinRotY;
      final double zAfterY = -px * sinRotY + pz * cosRotY;
      px = xAfterY;
      pz = zAfterY;

      final double yAfterX = py * cosRotX - pz * sinRotX;
      final double zAfterX = py * sinRotX + pz * cosRotX;
      py = yAfterX;
      pz = zAfterX;

      // Perspective projection with clamped Z denominator (using viewDistance)
      final double safeZ = (viewDistance + pz).clamp(0.1, 10.0);
      final double scale = radius / safeZ;

      final int outIndex = i * 2;
      projectedPoints[outIndex] = centerX + px * scale * 2.0;
      projectedPoints[outIndex + 1] = centerY + py * scale * 2.0;
    }
  }
}
