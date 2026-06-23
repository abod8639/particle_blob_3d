import 'dart:math';

/// Utility class for calculating 3D particle positions.
class BlobMath {
  /// Generates points evenly distributed on a sphere using the Fibonacci lattice.
  /// Returns a list of [x, y, z] arrays.
  static List<List<double>> generateFibonacciSphere(int samples) {
    List<List<double>> points = [];
    final double phi = pi * (3.0 - sqrt(5.0)); // golden angle in radians

    for (int i = 0; i < samples; i++) {
      double y = 1.0 - (i / (samples - 1)) * 2.0; // y goes from 1 to -1
      double radius = sqrt(1.0 - y * y); // radius at y

      double theta = phi * i; // golden angle increment

      double x = cos(theta) * radius;
      double z = sin(theta) * radius;

      points.add([x, y, z]);
    }
    return points;
  }

  /// Extremely simple fast 3D noise approximation based on sine waves.
  /// This avoids heavy procedural noise calculations to maintain 60fps for 5000+ points.
  static double fastNoise3D(double x, double y, double z, double time) {
    return sin(x * 3.0 + time) * cos(y * 2.0 - time) * sin(z * 4.0 + time * 1.5);
  }

  /// Rotate point around X axis
  static void rotateX(List<double> point, double angle) {
    double y = point[1];
    double z = point[2];
    double cosA = cos(angle);
    double sinA = sin(angle);
    point[1] = y * cosA - z * sinA;
    point[2] = y * sinA + z * cosA;
  }

  /// Rotate point around Y axis
  static void rotateY(List<double> point, double angle) {
    double x = point[0];
    double z = point[2];
    double cosA = cos(angle);
    double sinA = sin(angle);
    point[0] = x * cosA + z * sinA;
    point[2] = -x * sinA + z * cosA;
  }
}

