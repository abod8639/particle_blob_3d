import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'particle_blob_controller.dart';
import 'blob_math.dart';
import 'blob_painter.dart';

class ParticleBlob extends StatefulWidget {
  final int particleCount;
  final double radius;
  final double pointSize;
  final ParticleBlobController? controller;
  final Color color1;
  final Color color2;

  const ParticleBlob({
    super.key,
    this.particleCount = 5000,
    this.radius = 150.0,
    this.pointSize = 2.0,
    this.controller,
    this.color1 = Colors.pinkAccent,
    this.color2 = Colors.purpleAccent,
  });

  @override
  State<ParticleBlob> createState() => _ParticleBlobState();
}

class _ParticleBlobState extends State<ParticleBlob> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late ParticleBlobController _controller;
  
  List<List<double>> _baseSphere = [];
  Float32List _projectedPoints = Float32List(0);
  
  ui.FragmentShader? _shader;
  double _time = 0.0;
  
  // Touch interaction
  Offset _touchPoint = Offset.infinite;
  bool _isDispersing = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ParticleBlobController();
    _controller.addListener(_onControllerChanged);
    
    _generateBaseSphere();
    _loadShader();

    _ticker = createTicker((elapsed) {
      _time += 0.016 * _controller.speed; // approx 60fps delta time * speed
      _updateParticles();
    })..start();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/blob.frag');
      setState(() {
        _shader = program.fragmentShader();
      });
    } catch (e) {
      debugPrint("Error loading shader: $e");
    }
  }

  void _generateBaseSphere() {
    _baseSphere = BlobMath.generateFibonacciSphere(widget.particleCount);
    _projectedPoints = Float32List(widget.particleCount * 2);
  }

  void _onControllerChanged() {
    // If the controller demands instant redraw or affects physics heavily, it will be handled in the ticker.
  }

  void _updateParticles() {
    if (!mounted) return;
    
    final double blobiness = _controller.blobiness;
    final Offset rotation = _controller.rotation;
    final double dispersion = _controller.dispersion;

    final Size size = MediaQuery.of(context).size;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Auto rotation
    final double autoRotY = _time * 0.5;

    for (int i = 0; i < widget.particleCount; i++) {
      final basePoint = _baseSphere[i];
      
      // Copy point
      List<double> p = [basePoint[0], basePoint[1], basePoint[2]];
      
      // Apply noise displacement (blob shape)
      final double noise = BlobMath.fastNoise3D(p[0], p[1], p[2], _time);
      final double displacement = 1.0 + noise * 0.3 * blobiness;
      
      p[0] *= displacement;
      p[1] *= displacement;
      p[2] *= displacement;

      // Disperse slightly based on touch if requested
      if (_isDispersing && _touchPoint != Offset.infinite) {
        // Disperse logic
      }

      // If dispersion controller > 0
      if (dispersion > 0.0) {
        p[0] *= (1.0 + dispersion);
        p[1] *= (1.0 + dispersion);
        p[2] *= (1.0 + dispersion);
      }

      // Apply rotations
      BlobMath.rotateY(p, autoRotY + rotation.dx * 0.01);
      BlobMath.rotateX(p, rotation.dy * 0.01);

      // Project 3D to 2D
      final double scaleProjected = widget.radius / (2.0 + p[2]); 
      
      _projectedPoints[i * 2] = centerX + p[0] * scaleProjected * 2.0;
      _projectedPoints[i * 2 + 1] = centerY + p[1] * scaleProjected * 2.0;
    }

    // Update shader uniforms
    if (_shader != null) {
      _shader!.setFloat(0, size.width);
      _shader!.setFloat(1, size.height);
      _shader!.setFloat(2, _time);
      
      // Colors
      _shader!.setFloat(3, widget.color1.red / 255.0);
      _shader!.setFloat(4, widget.color1.green / 255.0);
      _shader!.setFloat(5, widget.color1.blue / 255.0);
      _shader!.setFloat(6, widget.color1.alpha / 255.0);
      
      _shader!.setFloat(7, widget.color2.red / 255.0);
      _shader!.setFloat(8, widget.color2.green / 255.0);
      _shader!.setFloat(9, widget.color2.blue / 255.0);
      _shader!.setFloat(10, widget.color2.alpha / 255.0);
    }

    setState(() {}); // trigger CustomPaint
  }

  @override
  void didUpdateWidget(ParticleBlob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleCount != widget.particleCount) {
      _generateBaseSphere();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onControllerChanged);
    }
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _controller.addRotation(Offset(details.delta.dx, details.delta.dy));
      },
      onTapDown: (details) {
        setState(() {
          _isDispersing = true;
          _touchPoint = details.localPosition;
          _controller.setDispersion(0.5); // Push particles out
        });
      },
      onTapUp: (_) {
        setState(() {
          _isDispersing = false;
          _touchPoint = Offset.infinite;
          _controller.setDispersion(0.0);
        });
      },
      child: CustomPaint(
        painter: BlobPainter(
          positions: _projectedPoints,
          shader: _shader,
          pointSize: widget.pointSize,
          fallbackColor: widget.color1,
        ),
        size: Size.infinite,
        isComplex: true,
        willChange: true,
      ),
    );
  }
}
