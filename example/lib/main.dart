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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
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
  final ParticleBlobController _controller = ParticleBlobController();
  final int _particleCount = 5000;
  double _blobiness = 1.0;
  double _speed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Particle Blob 3D'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background blob
          Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: ParticleBlob(
                particleCount: _particleCount,
                controller: _controller,
                radius: 120,
                color1: Colors.pinkAccent,
                color2: Colors.deepPurpleAccent,
              ),
            ),
          ),
          // Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Blobiness'),
                        Expanded(
                          child: Slider(
                            value: _blobiness,
                            min: 0.0,
                            max: 3.0,
                            onChanged: (val) {
                              setState(() => _blobiness = val);
                              _controller.setBlobiness(val);
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Speed'),
                        Expanded(
                          child: Slider(
                            value: _speed,
                            min: 0.1,
                            max: 5.0,
                            onChanged: (val) {
                              setState(() => _speed = val);
                              _controller.setSpeed(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
