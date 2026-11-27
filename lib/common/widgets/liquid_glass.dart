import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart' show RawMagnifier;
import 'package:material_ui/material_ui.dart';

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({super.key, required this.child, this.capsule = false});

  final Widget child;
  final bool capsule;

  @override
  Widget build(BuildContext context) {
    final dark = ColorScheme.of(context).brightness == Brightness.dark;
    final tint = dark ? const Color(0xff151519) : Colors.white;
    if (!capsule) {
      return Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: -_HeaderFrost.bleed,
            child: IgnorePointer(child: _HeaderFrost(tint: tint, dark: dark)),
          ),
          child,
        ],
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(builder: (context, bounds) {
                final width = math.min(bounds.maxHeight / 2, bounds.maxWidth / 2);
                final size = Size(width, bounds.maxHeight);
                // Anchor the horizontal sample at the inner end of each cap.
                // The long central section samples the feed at its original scale.
                const zoom = 1.18;
                final anchor = width / 2 * (1 - 1 / zoom);
                return Stack(children: [
                  for (final left in [true, false])
                    Positioned(
                      top: 0,
                      left: left ? 0 : null,
                      right: left ? null : 0,
                      child: RawMagnifier(
                        size: size,
                        magnificationScale: zoom,
                        focalPointOffset: Offset(left ? anchor : -anchor, 0),
                      ),
                    ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: _capsuleBlur,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tint.withValues(alpha: dark ? .56 : .54),
                              tint.withValues(alpha: dark ? .39 : .34),
                              tint.withValues(alpha: dark ? .51 : .45),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
          ),
          child,
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _CapsuleHighlight(dark))),
          ),
        ],
      ),
    );
  }

  static final _capsuleBlur = ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2);
}

class _HeaderFrost extends StatelessWidget {
  const _HeaderFrost({required this.tint, required this.dark});
  final Color tint;
  final bool dark;

  static const bleed = 9.0;
  // Sample the height-dependent blur in narrow, disjoint strips. The final
  // three strips lie below the toolbar; only the background extends there.
  static const _bodyCount = 10;
  static final _filters = [
    14.0, 12.7, 11.4, 10.1, 8.8, 7.5, 6.2, 5.0, 3.9, 2.8, 1.9, 1.1, .45,
  ].map((s) => ImageFilter.blur(sigmaX: s, sigmaY: s)).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final density = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, bounds) {
      final height = bounds.maxHeight;
      if (height <= bleed) return const SizedBox.shrink();
      final body = height - bleed;
      final edge = body / height;
      double boundary(int i) {
        if (i == _filters.length) return height;
        final y = i <= _bodyCount
            ? body * i / _bodyCount
            : body + bleed * (i - _bodyCount) / (_filters.length - _bodyCount);
        return (y * density).round() / density;
      }
      return Stack(children: [
        for (var i = 0; i < _filters.length; i++)
          Positioned(
            left: 0,
            right: 0,
            top: boundary(i),
            height: boundary(i + 1) - boundary(i),
            child: ClipRect(
              child: BackdropFilter(
                filter: _filters[i],
                child: const SizedBox.expand(),
              ),
            ),
          ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, edge * .55, edge, 1],
                colors: [
                  tint.withValues(alpha: dark ? .77 : .79),
                  tint.withValues(alpha: dark ? .63 : .65),
                  tint.withValues(alpha: dark ? .35 : .34),
                  tint.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _CapsuleHighlight extends CustomPainter {
  const _CapsuleHighlight(this.dark);
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
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(32)), paint);
  }

  @override
  bool shouldRepaint(_CapsuleHighlight old) => old.dark != dark;
}
