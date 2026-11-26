import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart' show RawMagnifier;
import 'package:material_ui/material_ui.dart';

/// Samples the scrolling feed behind the controls. Paint the controls last so
/// text, semantics and touch targets stay in their original coordinate space.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({super.key, required this.child, this.capsule = false});

  final Widget child;
  final bool capsule;
  static final _soften = ImageFilter.blur(sigmaX: 3.2, sigmaY: 3.2);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.of(context);
    final dark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(capsule ? 32 : 0);
    final tint = dark ? const Color(0xff151519) : Colors.white;
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(builder: (context, constraints) {
                return RawMagnifier(
                  size: constraints.biggest,
                  magnificationScale: capsule ? 1.095 : 1.035,
                  focalPointOffset: Offset(0, capsule ? -1.4 : 1.7),
                  child: BackdropFilter(
                    filter: _soften,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tint.withValues(alpha: dark ? .58 : .56),
                            tint.withValues(alpha: dark ? .40 : .35),
                            tint.withValues(alpha: dark ? .52 : .47),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GlassHighlight(capsule, dark)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassHighlight extends CustomPainter {
  const _GlassHighlight(this.capsule, this.dark);
  final bool capsule;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: dark ? .55 : .82),
          Colors.white.withValues(alpha: .06),
          Colors.white.withValues(alpha: dark ? .34 : .66),
        ],
      ).createShader(rect);
    if (capsule) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32)), paint);
    } else {
      canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
    }
  }

  @override
  bool shouldRepaint(_GlassHighlight old) => old.capsule != capsule || old.dark != dark;
}
