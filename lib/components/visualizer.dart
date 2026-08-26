import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

enum VisualizerType {
  spectrum, // Bouncing bars
  waveform, // Continuous curved lines
}

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final VisualizerType type;
  final double height;
  final double width;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.type = VisualizerType.waveform,
    this.height = 100.0,
    this.width = double.infinity,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _VisualizerPainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
            type: widget.type,
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final VisualizerType type;

  _VisualizerPainter({
    required this.animationValue,
    required this.isPlaying,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (type == VisualizerType.spectrum) {
      _paintSpectrum(canvas, size);
    } else {
      _paintWaveform(canvas, size);
    }
  }

  void _paintSpectrum(Canvas canvas, Size size) {
    final int barCount = 32;
    final double spacing = 4.0;
    final double totalSpacing = spacing * (barCount - 1);
    final double barWidth = (size.width - totalSpacing) / barCount;
    final double centerY = size.height;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(42); // Seeded for deterministic shapes but dynamic heights

    for (int i = 0; i < barCount; i++) {
      // Calculate animated height multiplier
      double waveFactor = math.sin((i / barCount) * math.pi * 3 + (animationValue * math.pi * 2));
      double heightFactor = isPlaying
          ? (0.2 + 0.8 * (waveFactor.abs() * (0.6 + 0.4 * math.sin(animationValue * 10 + i))))
          : 0.1;

      // Ensure some natural random variation
      double randomMultiplier = 0.5 + 0.5 * rand.nextDouble();
      double finalHeight = size.height * heightFactor * randomMultiplier;

      // Color gradient from Crimson at bottom to Bright Red at top
      final rect = Rect.fromLTWH(
        i * (barWidth + spacing),
        centerY - finalHeight,
        barWidth,
        finalHeight,
      );

      paint.shader = LinearGradient(
        colors: [RythemeTheme.crimson, RythemeTheme.brightRed],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

      // Draw the bar with a rounded top edge
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2));
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintWaveform(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final Path wavePath = Path();
    final Path wavePath2 = Path();

    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = RythemeTheme.brightRed
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = RythemeTheme.crimson.withOpacity(0.5)
      ..strokeCap = StrokeCap.round;

    wavePath.moveTo(0, midY);
    wavePath2.moveTo(0, midY);

    final double phase = animationValue * math.pi * 2;
    final int points = 100;
    final double step = size.width / points;

    for (int i = 0; i <= points; i++) {
      double x = i * step;

      // Amplitude envelope (taper off at edges)
      double envelope = math.sin((i / points) * math.pi);

      // Main wave calculation
      double y1 = midY;
      double y2 = midY;

      if (isPlaying) {
        y1 += math.sin((i / 10) - phase * 2) * 20 * envelope;
        y1 += math.cos((i / 5) + phase) * 8 * envelope;

        y2 += math.cos((i / 8) + phase * 1.5) * 15 * envelope;
        y2 += math.sin((i / 4) - phase) * 6 * envelope;
      } else {
        // Flatline vibration
        y1 += math.sin(i / 3) * 1.5 * envelope;
        y2 += math.cos(i / 2) * 1.0 * envelope;
      }

      wavePath.lineTo(x, y1);
      wavePath2.lineTo(x, y2);
    }

    // Add glowing shadow to the main waveform
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = RythemeTheme.primaryRed.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(wavePath, shadowPaint);
    canvas.drawPath(wavePath, paint1);
    canvas.drawPath(wavePath2, paint2);
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.type != type;
  }
}
