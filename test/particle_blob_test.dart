import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:particle_blob/particle_blob.dart';
import 'package:particle_blob/src/blob_painter.dart';
import 'package:particle_blob/src/blob_input_listener.dart';

void main() {
  group('ParticleBlob Widget Tests', () {
    testWidgets('renders CustomPaint with default settings and asserts on invalid parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Check if ParticleBlob widget is built
      expect(find.byType(ParticleBlob), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Verify assertion for invalid particleCount
      expect(
        () => ParticleBlob(particleCount: 0),
        throwsAssertionError,
      );

      // Verify assertion for invalid tapScaleFactor
      expect(
        () => ParticleBlob(tapScaleFactor: -0.1),
        throwsAssertionError,
      );
      expect(
        () => ParticleBlob(tapScaleFactor: 5.1),
        throwsAssertionError,
      );
    });

    testWidgets('handles dynamic tapScaleFactor updates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(
                particleCount: 500,
                tapScaleFactor: 1.0,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      var inputListener = tester.widget<BlobInputListener>(find.byType(BlobInputListener));
      expect(inputListener.controller.tapScaleFactor, 1.0);

      // Rebuild with a different tapScaleFactor
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(
                particleCount: 500,
                tapScaleFactor: 2.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      inputListener = tester.widget<BlobInputListener>(find.byType(BlobInputListener));
      expect(inputListener.controller.tapScaleFactor, 2.0);
    });

    testWidgets('handles dynamic controller swapping', (tester) async {
      final controller1 = ParticleBlobController(tapScaleFactor: 1.5);
      final controller2 = ParticleBlobController(tapScaleFactor: 3.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(
                particleCount: 500,
                controller: controller1,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      var inputListener = tester.widget<BlobInputListener>(find.byType(BlobInputListener));
      expect(inputListener.controller, controller1);
      expect(inputListener.controller.tapScaleFactor, 1.5);

      // Rebuild with controller2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(
                particleCount: 500,
                controller: controller2,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      inputListener = tester.widget<BlobInputListener>(find.byType(BlobInputListener));
      expect(inputListener.controller, controller2);
      expect(inputListener.controller.tapScaleFactor, 3.0);
    });

    testWidgets('ticker increments frame generation index on frame pumps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleBlob(
                particleCount: 500,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      var customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final firstGen = (customPaint.painter as BlobPainter).generation;

      // Pump a few frames with time elapsed
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final secondGen = (customPaint.painter as BlobPainter).generation;

      expect(secondGen, greaterThan(firstGen));
    });
  });

  group('ParticleBlobController Tests', () {
    test('initial values and custom constructor parameters', () {
      final controller = ParticleBlobController(
        dampingFactor: 0.9,
        tapScaleFactor: 2.0,
      );
      expect(controller.dampingFactor, 0.9);
      expect(controller.tapScaleFactor, 2.0);
      expect(controller.blobiness, 1.0);
      expect(controller.speed, 1.0);
      expect(controller.dispersion, 0.0);
      expect(controller.autoRotationSpeed, 0.5);
      expect(controller.noiseFrequency, 1.0);
      expect(controller.viewDistance, 2.0);
    });

    test('constructor asserts on invalid parameters', () {
      expect(() => ParticleBlobController(dampingFactor: -0.1), throwsAssertionError);
      expect(() => ParticleBlobController(dampingFactor: 1.1), throwsAssertionError);
      expect(() => ParticleBlobController(tapScaleFactor: -0.5), throwsAssertionError);
      expect(() => ParticleBlobController(tapScaleFactor: 5.5), throwsAssertionError);
    });

    test('property setters clamp inputs correctly', () {
      final controller = ParticleBlobController();

      controller.setBlobiness(6.0); // clamped to 5.0
      expect(controller.blobiness, 5.0);
      controller.setBlobiness(-1.0); // clamped to 0.0
      expect(controller.blobiness, 0.0);

      controller.setSpeed(12.0); // clamped to 10.0
      expect(controller.speed, 10.0);
      controller.setSpeed(-2.0); // clamped to 0.0
      expect(controller.speed, 0.0);

      controller.setDispersion(4.0); // clamped to 3.0
      expect(controller.dispersion, 3.0);
      controller.setDispersion(-0.5); // clamped to 0.0
      expect(controller.dispersion, 0.0);

      controller.setDampingFactor(1.5); // clamped to 1.0
      expect(controller.dampingFactor, 1.0);
      controller.setDampingFactor(-0.2); // clamped to 0.0
      expect(controller.dampingFactor, 0.0);

      controller.setTapScaleFactor(6.0); // clamped to 5.0
      expect(controller.tapScaleFactor, 5.0);
      controller.setTapScaleFactor(-1.0); // clamped to 0.0
      expect(controller.tapScaleFactor, 0.0);

      controller.setAutoRotationSpeed(4.0); // clamped to 3.0
      expect(controller.autoRotationSpeed, 3.0);
      controller.setAutoRotationSpeed(-4.0); // clamped to -3.0
      expect(controller.autoRotationSpeed, -3.0);

      controller.setNoiseFrequency(6.0); // clamped to 5.0
      expect(controller.noiseFrequency, 5.0);
      controller.setNoiseFrequency(0.05); // clamped to 0.1
      expect(controller.noiseFrequency, 0.1);

      controller.setViewDistance(6.0); // clamped to 5.0
      expect(controller.viewDistance, 5.0);
      controller.setViewDistance(0.5); // clamped to 0.8
      expect(controller.viewDistance, 0.8);
    });

    test('notifies listeners when properties are updated', () {
      final controller = ParticleBlobController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setBlobiness(2.0);
      expect(notifyCount, 1);

      // Updating with same value should NOT notify
      controller.setBlobiness(2.0);
      expect(notifyCount, 1);

      controller.setSpeed(2.0);
      expect(notifyCount, 2);

      controller.setDispersion(1.0);
      expect(notifyCount, 3);

      controller.setDampingFactor(0.85);
      expect(notifyCount, 4);

      controller.setTapScaleFactor(3.0);
      expect(notifyCount, 5);

      controller.setAutoRotationSpeed(1.0);
      expect(notifyCount, 6);

      controller.setNoiseFrequency(2.0);
      expect(notifyCount, 7);

      controller.setViewDistance(3.0);
      expect(notifyCount, 8);

      controller.addRotationImpulse(const Offset(10, 10));
      expect(notifyCount, 9);

      controller.resetRotation();
      expect(notifyCount, 10);
    });

    test('addRotationImpulse, applyDamping, and snapping rotation logic', () {
      final controller = ParticleBlobController(dampingFactor: 0.9);
      expect(controller.rotationX, 0.0);
      expect(controller.rotationY, 0.0);

      // applyDamping returns false when there is no rotation
      expect(controller.applyDamping(), false);

      controller.addRotationImpulse(const Offset(10.0, 20.0));
      expect(controller.rotationX, 20.0 * 0.005);
      expect(controller.rotationY, 10.0 * 0.005);

      // applyDamping returns true when rotation is active
      expect(controller.applyDamping(), true);
      expect(controller.rotationX, closeTo((20.0 * 0.005) * 0.9, 0.0001));

      // Test snapping of small values to 0.0
      controller.addRotationImpulse(const Offset(0.01, 0.01)); // tiny impulse
      controller.setDampingFactor(0.1); // high decay
      controller.applyDamping();
      expect(controller.rotationX, 0.0);
      expect(controller.rotationY, 0.0);

      // Test no decay when dampingFactor is 1.0
      final controllerNoDecay = ParticleBlobController(dampingFactor: 1.0);
      controllerNoDecay.addRotationImpulse(const Offset(10.0, 20.0));
      controllerNoDecay.applyDamping();
      expect(controllerNoDecay.rotationX, 20.0 * 0.005);
      expect(controllerNoDecay.rotationY, 10.0 * 0.005);

      // Test instant decay when dampingFactor is 0.0
      final controllerInstantDecay = ParticleBlobController(dampingFactor: 0.0);
      controllerInstantDecay.addRotationImpulse(const Offset(10.0, 20.0));
      controllerInstantDecay.applyDamping();
      expect(controllerInstantDecay.rotationX, 0.0);
      expect(controllerInstantDecay.rotationY, 0.0);
    });
  });

  group('BlobInputListener Widget Tests', () {
    testWidgets('detects pointer gestures and updates controller values', (tester) async {
      final controller = ParticleBlobController();
      List<Offset> touches = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlobInputListener(
              controller: controller,
              onTouchesChanged: (t) {
                touches = t;
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // Perform a pan/drag gesture
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(20, 30));
      await tester.pump();

      // Rotation impulse applied
      expect(controller.rotationX, isNot(0.0));
      expect(controller.rotationY, isNot(0.0));

      // Touch position tracked
      expect(touches.length, 1);
      expect(touches.first, const Offset(120, 130));

      await gesture.up();
      await tester.pump();

      expect(touches.isEmpty, true);
    });

    testWidgets('applies tapScaleFactor to dispersion output', (tester) async {
      final controller = ParticleBlobController(tapScaleFactor: 0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlobInputListener(
              controller: controller,
              onTouchesChanged: (_) {},
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await tester.pump();

      // 1 finger touch -> base dispersion is 0.4 + 0.2 * 1 = 0.6
      // Multiplying by tapScaleFactor (0.5) should yield 0.3
      expect(controller.dispersion, closeTo(0.3, 0.0001));

      await gesture.up();
      await tester.pump();
      expect(controller.dispersion, 0.0);
    });
  });
}
