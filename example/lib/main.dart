import 'package:flutter/material.dart';
import 'package:particle_blob/particle_blob.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Blob Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.pinkAccent,
          thumbColor: Colors.pinkAccent,
          inactiveTrackColor: Colors.white24,
        ),
      ),
      home: const BlobDemoPage(),
    );
  }
}

class BlobDemoPage extends StatefulWidget {
  const BlobDemoPage({super.key});

  @override
  State<BlobDemoPage> createState() => _BlobDemoPageState();
}

class _BlobDemoPageState extends State<BlobDemoPage> {
  final ParticleBlobController _controller = ParticleBlobController(
    dampingFactor: 0.93,
  );

  double _blobiness = 1.0;
  double _speed = 1.0;
  double _pointSize = 2.0;
  double _tapScaleFactor = 1.0;
  Color _color1 = Colors.pinkAccent;
  Color _color2 = Colors.deepPurpleAccent;

  final List<_ColorPreset> _presets = [
    const _ColorPreset('Nebula', Colors.pinkAccent, Colors.deepPurpleAccent),
    const _ColorPreset('Ocean', Colors.cyanAccent, Colors.blueAccent),
    const _ColorPreset('Fire', Colors.orangeAccent, Colors.redAccent),
    const _ColorPreset('Forest', Colors.lightGreenAccent, Colors.teal),
    const _ColorPreset('Mono', Colors.white, Colors.white54),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Particle Blob 3D',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
            ),

            // Blob
            Expanded(
              child: Center(
                child: ParticleBlob(
                  particleCount: 5000,
                  controller: _controller,
                  radius: 130,
                  pointSize: _pointSize,
                  tapScaleFactor: _tapScaleFactor,
                  gradient: LinearGradient(
                    colors: [_color1, _color2],
                  ),
                ),
              ),
            ),

            // Color Presets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _presets.map((preset) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _color1 = preset.c1;
                        _color2 = preset.c2;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [preset.c1, preset.c2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white24, width: 1.5),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Controls
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _buildSlider(
                    label: 'Blobiness',
                    value: _blobiness,
                    min: 0.0,
                    max: 3.0,
                    onChanged: (v) {
                      setState(() => _blobiness = v);
                      _controller.setBlobiness(v);
                    },
                  ),
                  _buildSlider(
                    label: 'Speed',
                    value: _speed,
                    min: 0.0,
                    max: 4.0,
                    onChanged: (v) {
                      setState(() => _speed = v);
                      _controller.setSpeed(v);
                    },
                  ),
                  _buildSlider(
                    label: 'Point Size',
                    value: _pointSize,
                    min: 0.5,
                    max: 5.0,
                    onChanged: (v) {
                      setState(() => _pointSize = v);
                    },
                  ),
                  _buildSlider(
                    label: 'Tap Scale',
                    value: _tapScaleFactor,
                    min: 0.0,
                    max: 3.0,
                    onChanged: (v) {
                      setState(() => _tapScaleFactor = v);
                      _controller.setTapScaleFactor(v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _ColorPreset {
  final String name;
  final Color c1;
  final Color c2;
  const _ColorPreset(this.name, this.c1, this.c2);
}
