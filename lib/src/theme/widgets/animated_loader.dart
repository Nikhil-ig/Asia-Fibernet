// Not using anywhere and (first use in full screen)

import 'package:flutter/material.dart';

class MovingBorder extends StatefulWidget {
  const MovingBorder({
    super.key,
    this.duration = const Duration(seconds: 2),
    this.borderColor,
    this.highlightColor,
    this.borderRadius,
    this.child,
  });

  final Duration duration;
  final Color? borderColor;
  final Color? highlightColor;
  final BorderRadiusGeometry? borderRadius;
  final Widget? child;

  @override
  State<MovingBorder> createState() => _MovingBorderState();
}

class _MovingBorderState extends State<MovingBorder>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MovingBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _animation.duration = widget.duration;
      _animation.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = widget.borderColor ?? theme.colorScheme.onSurface;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.primary;
    final borderRadius =
        widget.borderRadius?.resolve(Directionality.of(context)) ??
        BorderRadius.zero;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _MovingBorderPainter(
            borderColor,
            highlightColor,
            borderRadius,
            _animation.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _MovingBorderPainter extends CustomPainter {
  _MovingBorderPainter(
    Color borderColor,
    Color highlightColor,
    this.borderRadius,
    this.value,
  ) : _paint1 =
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round,
      _paint2 =
          Paint()
            ..color = highlightColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

  final Paint _paint1;
  final Paint _paint2;
  final BorderRadius borderRadius;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()..addRRect(
          RRect.fromLTRBAndCorners(
            0,
            0,
            size.width,
            size.height,
            topLeft: borderRadius.topLeft,
            topRight: borderRadius.topRight,
            bottomLeft: borderRadius.bottomLeft,
            bottomRight: borderRadius.bottomRight,
          ).deflate(_paint1.strokeWidth / 2),
        );
    canvas.drawPath(path, _paint1);
    final metric = path.computeMetrics().first;
    final length = metric.length;
    const segment = 0.2;
    if (value < segment) {
      canvas.drawPath(
        metric.extractPath((1 - segment + value) * length, length),
        _paint2,
      );
      canvas.drawPath(metric.extractPath(0, value * length), _paint2);
    } else {
      canvas.drawPath(
        metric.extractPath((value - segment) * length, value * length),
        _paint2,
      );
    }
  }

  @override
  bool shouldRepaint(_MovingBorderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate._paint1.color != _paint1.color ||
        oldDelegate._paint2.color != _paint2.color;
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MovingBorder(
            borderRadius: BorderRadius.circular(24),
            child: const SizedBox(width: 128, height: 64),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const App());
}
