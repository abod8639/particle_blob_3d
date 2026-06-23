import 'package:flutter/material.dart';

/// A controller for the [ParticleBlob] widget that provides programmatic
/// control over blob geometry, animation speed, and particle physics.
///
/// Follows the [ChangeNotifier] contract — call [dispose] when no longer needed
/// if the controller is created externally.
///
/// Example:
/// ```dart
/// final controller = ParticleBlobController();
/// // ...
/// controller.setSpeed(2.0);
/// controller.setBlobiness(1.5);
/// // ...
/// controller.dispose();
/// ```
class ParticleBlobController extends ChangeNotifier {
  double _blobiness = 1.0;
  double _speed = 1.0;
  double _dispersion = 0.0;

  /// Accumulated manual rotation from drag gestures.
  /// LOGIC-02: Managed with damping — decays in the animation ticker rather
  /// than growing infinitely.
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  /// Damping factor applied each frame: 1.0 = no decay, 0.0 = instant stop.
  /// Range: [0.0, 1.0].
  final double dampingFactor;

  ParticleBlobController({
    this.dampingFactor = 0.92,
  }) : assert(dampingFactor >= 0.0 && dampingFactor <= 1.0,
            'dampingFactor must be between 0.0 and 1.0');

  /// Noise amplitude: how much the sphere surface is displaced.
  /// 0.0 = perfect sphere, higher = more distorted.
  double get blobiness => _blobiness;

  /// Animation speed multiplier. 1.0 = normal, 2.0 = double, 0.5 = half.
  double get speed => _speed;

  /// Radial dispersion. 0.0 = default shape, 1.0 = particles pushed far out.
  double get dispersion => _dispersion;

  /// Current accumulated X-axis rotation (from drag, with damping applied).
  double get rotationX => _rotationX;

  /// Current accumulated Y-axis rotation (from drag, with damping applied).
  double get rotationY => _rotationY;

  /// Sets the noise amplitude. Clamped to [0.0, 5.0].
  void setBlobiness(double value) {
    final clamped = value.clamp(0.0, 5.0);
    if (_blobiness != clamped) {
      _blobiness = clamped;
      notifyListeners();
    }
  }

  /// Sets the animation speed multiplier. Clamped to [0.0, 10.0].
  void setSpeed(double value) {
    final clamped = value.clamp(0.0, 10.0);
    if (_speed != clamped) {
      _speed = clamped;
      notifyListeners();
    }
  }

  /// Sets the dispersion level. Clamped to [0.0, 3.0].
  void setDispersion(double value) {
    final clamped = value.clamp(0.0, 3.0);
    if (_dispersion != clamped) {
      _dispersion = clamped;
      notifyListeners();
    }
  }

  /// Adds an angular velocity impulse from a drag gesture.
  /// Delta is in screen pixels — sensitivity is applied internally.
  void addRotationImpulse(Offset delta) {
    _rotationX += delta.dy * 0.005;
    _rotationY += delta.dx * 0.005;
    notifyListeners();
  }

  /// LOGIC-02: Called every tick from the widget's animation loop.
  /// Applies exponential decay to the rotation so it naturally comes to rest.
  /// Returns true if the rotation is still non-negligible (needs repaint).
  bool applyDamping() {
    _rotationX *= dampingFactor;
    _rotationY *= dampingFactor;

    // Snap to zero below threshold to prevent infinite tiny values
    if (_rotationX.abs() < 0.0001) _rotationX = 0.0;
    if (_rotationY.abs() < 0.0001) _rotationY = 0.0;

    return _rotationX != 0.0 || _rotationY != 0.0;
  }

  /// Resets accumulated rotation to zero immediately.
  void resetRotation() {
    if (_rotationX != 0.0 || _rotationY != 0.0) {
      _rotationX = 0.0;
      _rotationY = 0.0;
      notifyListeners();
    }
  }
}
