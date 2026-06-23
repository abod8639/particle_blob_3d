import 'package:flutter/material.dart';

/// A controller for the ParticleBlob widget to programmatically interact
/// with the blob's shape, rotation, and dispersion.
class ParticleBlobController extends ChangeNotifier {
  double _blobiness = 1.0;
  double _speed = 1.0;
  double _dispersion = 0.0;
  Offset _rotation = Offset.zero;

  /// Get the current amplitude of the noise (blobiness).
  double get blobiness => _blobiness;

  /// Get the current animation speed multiplier.
  double get speed => _speed;

  /// Get the current dispersion level (0.0 = solid blob, 1.0 = scattered).
  double get dispersion => _dispersion;

  /// Get the current manual rotation applied to the blob.
  Offset get rotation => _rotation;

  /// Change the noise amplitude (how "bumpy" the blob is).
  void setBlobiness(double value) {
    if (_blobiness != value) {
      _blobiness = value;
      notifyListeners();
    }
  }

  /// Change the animation speed.
  void setSpeed(double value) {
    if (_speed != value) {
      _speed = value;
      notifyListeners();
    }
  }

  /// Scatter or disperse the particles.
  /// 0.0 means normal shape. > 0.0 pushes particles outward.
  void setDispersion(double value) {
    if (_dispersion != value) {
      _dispersion = value;
      notifyListeners();
    }
  }

  /// Add rotation to the blob. Typically updated via drag gestures.
  void addRotation(Offset delta) {
    _rotation += delta;
    notifyListeners();
  }

  /// Set exact rotation.
  void setRotation(Offset value) {
    if (_rotation != value) {
      _rotation = value;
      notifyListeners();
    }
  }
}
