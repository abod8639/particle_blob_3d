import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'particle_blob_controller.dart';
import 'blob_math.dart';
import 'blob_painter.dart';
import 'blob_input_listener.dart';

/// A high-performance Flutter widget that renders an animated 3D particle blob.
///
/// Particles are distributed uniformly on a 3D sphere via the Fibonacci lattice
/// algorithm and deformed over time using fast sine-wave noise. The result is
/// projected to 2D via perspective division and rendered in a single GPU draw
/// call using [Canvas.drawRawPoints].
///
/// All rendering data is managed in flat [Float32List] buffers to eliminate
/// Garbage Collection pressure. A [ui.FragmentShader] handles per-pixel
/// coloring on the GPU.
///
/// ## Interaction
/// - **Drag**: Rotates the blob. Rotation decays naturally with inertia.
/// - **Tap & Hold**: Disperses the particles radially outward.
/// - **Mouse Hover** (desktop/web): Applies a subtle rotation following the cursor.
///
/// ## Performance Notes
/// - Uses [ValueNotifier] + [ValueListenableBuilder] so only [CustomPaint]
///   rebuilds per frame, not the entire widget subtree. (BUG-05 fix)
/// - Uses actual ticker delta time for device-rate-independent animation. (ARCH-02 fix)
class ParticleBlob extends StatefulWidget {
  /// Total number of particles. Default: 5000.
  final int particleCount;

  /// Base radius of the blob sphere in logical pixels. Default: 150.0.
  final double radius;

  /// Rendered size of each particle point. Default: 2.0.
  final double pointSize;

  /// Optional external controller. If null, an internal one is created.
  final ParticleBlobController? controller;

  /// Primary gradient color injected into the fragment shader.
  final Color color1;

  /// Secondary gradient color injected into the fragment shader.
  final Color color2;

  const ParticleBlob({
    super.key,
    this.particleCount = 5000,
    this.radius = 150.0,
    this.pointSize = 2.0,
    this.controller,
    this.color1 = Colors.pinkAccent,
    this.color2 = Colors.purpleAccent,
  }) : assert(particleCount > 0, 'particleCount must be greater than 0');

  @override
  State<ParticleBlob> createState() => _ParticleBlobState();
}

class _ParticleBlobState extends State<ParticleBlob>
    with SingleTickerProviderStateMixin {
  // ── Animation ──────────────────────────────────────────────────────────────

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  /// Continuous animation clock (seconds). Wraps to prevent float precision
  /// loss over long runtimes. (LOGIC-01 fix)
  double _time = 0.0;

  /// BUG-05 fix: drives repaint only on CustomPaint, not the full widget tree.
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);
  int _frameCount = 0;

  // ── Controller ─────────────────────────────────────────────────────────────

  late ParticleBlobController _controller;
  bool _ownsController = false;

  // ── Particle Data ──────────────────────────────────────────────────────────

  /// Flat base sphere: [x0,y0,z0, x1,y1,z1, ...]. Immutable after generation.
  /// BUG-07 fix: Float32List instead of List<List<double>>.
  Float32List _baseSphere = Float32List(0);

  /// Output buffer: [x0,y0, x1,y1, ...] in screen pixels. Mutated every frame.
  Float32List _projectedPoints = Float32List(0);

  // ── Shader ─────────────────────────────────────────────────────────────────

  ui.FragmentProgram? _program; // ARCH-03 fix: stored to prevent premature GC
  ui.FragmentShader? _shader;

  // ── Layout ─────────────────────────────────────────────────────────────────

  /// BUG-02 fix: size cached from LayoutBuilder, never read inside ticker.
  Size _cachedSize = Size.zero;

  // ── Touch State ────────────────────────────────────────────────────────────

  List<Offset> _activeTouches = const [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? ParticleBlobController();

    _generateBuffers(widget.particleCount);
    _loadShader();

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(ParticleBlob oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Regenerate particle buffers if count changed
    if (oldWidget.particleCount != widget.particleCount) {
      _generateBuffers(widget.particleCount);
    }

    // Swap controller ownership cleanly
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _controller.dispose();
      _ownsController = widget.controller == null;
      _controller = widget.controller ?? ParticleBlobController();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameNotifier.dispose();
    _shader?.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  void _generateBuffers(int count) {
    _baseSphere = BlobMath.generateFibonacciSphere(count); // BUG-01 guarded
    _projectedPoints = Float32List(count * 2);
  }

  Future<void> _loadShader() async {
    try {
      // ARCH-03: store program as field to prevent premature GC
      _program = await ui.FragmentProgram.fromAsset('shaders/blob.frag');
      if (mounted) {
        setState(() {
          _shader = _program!.fragmentShader();
        });
      }
    } catch (e) {
      debugPrint('[ParticleBlob] Shader load failed: $e');
      // Falls back to solid fallbackColor in BlobPainter
    }
  }

  // ── Ticker Callback ────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (!mounted || _cachedSize == Size.zero) return;

    // ARCH-02 fix: use actual frame delta, clamped to prevent spiral of death
    // (e.g., after app backgrounding, elapsed jumps massively)
    final double dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6)
        .clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    // Advance time with speed multiplier; wrap to prevent float precision loss
    // LOGIC-01 fix
    _time = BlobMath.wrapTime(_time + dt * _controller.speed);

    // LOGIC-02 fix: apply rotation damping every frame
    _controller.applyDamping();

    _updateProjectedPoints();

    // Update shader uniforms (only when shader is loaded)
    _updateShaderUniforms();

    // BUG-05 fix: increment counter to notify only the ValueListenableBuilder
    _frameCount++;
    _frameNotifier.value = _frameCount;
  }

  // ── Particle Update ────────────────────────────────────────────────────────

  void _updateProjectedPoints() {
    BlobMath.projectParticles(
      count: widget.particleCount,
      radius: widget.radius,
      blobiness: _controller.blobiness,
      dispersion: _controller.dispersion,
      rotationX: _controller.rotationX,
      rotationY: _controller.rotationY,
      time: _time,
      viewportWidth: _cachedSize.width,
      viewportHeight: _cachedSize.height,
      activeTouches: _activeTouches,
      baseSphere: _baseSphere,
      projectedPoints: _projectedPoints,
      autoRotationSpeed: _controller.autoRotationSpeed,
      noiseFrequency: _controller.noiseFrequency,
      viewDistance: _controller.viewDistance,
    );
  }

  // ── Shader Uniforms ────────────────────────────────────────────────────────

  void _updateShaderUniforms() {
    final s = _shader;
    if (s == null) return;

    // Index layout matches blob.frag uniform declaration:
    // 0-1: uResolution, 2: uTime, 3-6: uColor1, 7-10: uColor2
    s.setFloat(0, _cachedSize.width);
    s.setFloat(1, _cachedSize.height);
    s.setFloat(2, _time);

    // BUG-03 fix: use .r/.g/.b/.a (normalized 0.0–1.0, non-deprecated API)
    s.setFloat(3, widget.color1.r);
    s.setFloat(4, widget.color1.g);
    s.setFloat(5, widget.color1.b);
    s.setFloat(6, widget.color1.a);

    s.setFloat(7, widget.color2.r);
    s.setFloat(8, widget.color2.g);
    s.setFloat(9, widget.color2.b);
    s.setFloat(10, widget.color2.a);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // BUG-02 fix: LayoutBuilder captures the widget's actual render size and
    // caches it for use in the ticker, avoiding MediaQuery inside the ticker.
    return LayoutBuilder(
      builder: (context, constraints) {
        _cachedSize = constraints.biggest;

        return BlobInputListener(
          controller: _controller,
          onTouchesChanged: (touches) {
            _activeTouches = touches;
          },
          child: ValueListenableBuilder<int>(
            valueListenable: _frameNotifier,
            builder: (_, frame, __) {
              // RepaintBoundary isolates the blob from the rest of the tree
              return RepaintBoundary(
                child: CustomPaint(
                  painter: BlobPainter(
                    positions: _projectedPoints,
                    generation: frame,
                    shader: _shader,
                    pointSize: widget.pointSize,
                    fallbackColor: widget.color1,
                  ),
                  size: Size.infinite,
                  isComplex: true,
                  willChange: true,
                ),
              );
            },
          ),
        );
  
      },
    );
  }
}
