import 'dart:math';
import 'package:flutter/material.dart';

class WaveformWidget extends StatefulWidget {
  final Color? color;
  final double height;
  final int barCount;

  const WaveformWidget({
    super.key,
    this.color,
    this.height = 100,
    this.barCount = 50,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<double> _barHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _generateInitialBars();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animationController.addListener(() {
      _updateBars();
    });

    _animationController.repeat();
  }

  void _generateInitialBars() {
    _barHeights = List.generate(
      widget.barCount,
      (index) => _random.nextDouble() * 0.5 + 0.1,
    );
  }

  void _updateBars() {
    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        // Rastgele değişim ama yumuşak geçişler için
        final change = (_random.nextDouble() - 0.5) * 0.3;
        _barHeights[i] = (_barHeights[i] + change).clamp(0.1, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      height: widget.height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: _barHeights[index] * widget.height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7 + (_barHeights[index] * 0.3)),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class StaticWaveformWidget extends StatelessWidget {
  final List<double> waveData;
  final Color? color;
  final double height;

  const StaticWaveformWidget({
    super.key,
    required this.waveData,
    this.color,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: waveData.map((amplitude) {
          return Container(
            width: 2,
            height: amplitude * height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class CircularWaveformWidget extends StatefulWidget {
  final Color? color;
  final double size;

  const CircularWaveformWidget({
    super.key,
    this.color,
    this.size = 200,
  });

  @override
  State<CircularWaveformWidget> createState() => _CircularWaveformWidgetState();
}

class _CircularWaveformWidgetState extends State<CircularWaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  List<double> _amplitudes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateAmplitudes();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rotationController.repeat();
    _pulseController.addListener(_updateAmplitudes);
    _pulseController.repeat();
  }

  void _generateAmplitudes() {
    _amplitudes = List.generate(60, (index) => _random.nextDouble());
  }

  void _updateAmplitudes() {
    setState(() {
      for (int i = 0; i < _amplitudes.length; i++) {
        final change = (_random.nextDouble() - 0.5) * 0.4;
        _amplitudes[i] = (_amplitudes[i] + change).clamp(0.2, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CircularWaveformPainter(
              amplitudes: _amplitudes,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class CircularWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  CircularWaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final angleStep = 2 * pi / amplitudes.length;

    for (int i = 0; i < amplitudes.length; i++) {
      final angle = i * angleStep;
      final amplitude = amplitudes[i];
      
      final startRadius = radius;
      final endRadius = radius + (amplitude * radius * 0.5);
      
      final startX = center.dx + startRadius * cos(angle);
      final startY = center.dy + startRadius * sin(angle);
      final endX = center.dx + endRadius * cos(angle);
      final endY = center.dy + endRadius * sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..color = color.withOpacity(0.7 + amplitude * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(CircularWaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
} 