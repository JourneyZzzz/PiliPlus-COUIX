import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

class FloatingNavigationDestination {
  const FloatingNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class FloatingNavigationBar extends StatefulWidget {
  const FloatingNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : assert(destinations.length >= 2),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<FloatingNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<FloatingNavigationBar> createState() => _FloatingNavigationBarState();
}

class _FloatingNavigationBarState extends State<FloatingNavigationBar> {
  double? _drag;
  int? _pressed;

  void _clearTouch() {
    if (_drag == null && _pressed == null) return;
    setState(() {
      _drag = null;
      _pressed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.of(context);
    final dark = scheme.brightness == Brightness.dark;
    final safe = MediaQuery.viewPaddingOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final count = widget.destinations.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const radius = BorderRadius.all(Radius.circular(32));
    return Padding(
      padding: EdgeInsets.fromLTRB(safe.left + 12, 0, safe.right + 12, safe.bottom + 8),
      child: Align(
        heightFactor: 1,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 68.0 * count + 16,
          height: 60,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: dark ? .28 : .12),
              blurRadius: 14, spreadRadius: -3, offset: const Offset(0, 3)),
          ]),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 17, sigmaY: 17),
              child: Material(
                color: (dark ? scheme.surfaceContainer : scheme.surface)
                    .withValues(alpha: dark ? .62 : .56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: LayoutBuilder(builder: (context, bounds) {
                    if (bounds.maxWidth <= 0) return const SizedBox.shrink();
                    final cell = bounds.maxWidth / count;
                    double position(double x) {
                      final local = rtl ? bounds.maxWidth - x : x;
                      return (local / cell - .5).clamp(0.0, count - 1.0).toDouble();
                    }
                    final index = (_drag ?? widget.selectedIndex.toDouble())
                        .clamp(0.0, count - 1.0).toDouble();
                    final active = index.round();
                    return GestureDetector(
                      excludeFromSemantics: true,
                      onHorizontalDragStart: (d) => setState(() {
                        _drag = position(d.localPosition.dx);
                        _pressed = null;
                      }),
                      onHorizontalDragUpdate: (d) => setState(() {
                        _drag = position(d.localPosition.dx);
                      }),
                      onHorizontalDragCancel: _clearTouch,
                      onHorizontalDragEnd: (_) {
                        final target = _drag?.round();
                        _clearTouch();
                        if (target != null && target != widget.selectedIndex) {
                          widget.onDestinationSelected(target);
                        }
                      },
                      child: Stack(fit: StackFit.expand, children: [
                        _FluidIndicator(index: index, cell: cell, count: count,
                          dragging: _drag != null, pressed: _pressed == active,
                          reduced: reduced),
                        Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          for (int i = 0; i < count; i++)
                            Expanded(child: _destination(context, i, i == active)),
                        ]),
                      ]),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int i, bool active) {
    final item = widget.destinations[i];
    final theme = Theme.of(context);
    final color = active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true, selected: widget.selectedIndex == i, label: item.label,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        onHighlightChanged: (pressed) {
          if (pressed || _pressed == i) setState(() => _pressed = pressed ? i : null);
        },
        onTap: () => widget.onDestinationSelected(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconTheme(data: IconThemeData(size: 24, color: color),
            child: active ? item.selectedIcon : item.icon),
          const SizedBox(height: 2),
          ExcludeSemantics(child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.35, child: Text(item.label, maxLines: 1,
              overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11, height: 1.15, color: color,
                fontWeight: active ? FontWeight.w600 : null)))),
        ]),
      ),
    );
  }
}

class _FluidIndicator extends StatelessWidget {
  const _FluidIndicator({required this.index, required this.cell, required this.count,
    required this.dragging, required this.pressed, required this.reduced});
  final double index;
  final double cell;
  final int count;
  final bool dragging;
  final bool pressed;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.of(context);
    final dark = colors.brightness == Brightness.dark;
    // The leading edge follows touch. The trailing edge catches up independently.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: index),
      duration: dragging || reduced ? Duration.zero : const Duration(milliseconds: 290),
      curve: Curves.easeOutBack,
      builder: (context, lead, _) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: index),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (context, tail, _) {
          final lag = reduced ? 0.0 : (tail - lead).clamp(-.42, .42);
          final stretch = lag.abs();
          final width = cell * (1 + stretch);
          final start = ((lead + (lag < 0 ? lag : 0)) * cell)
              .clamp(-4.0, count * cell - width + 4);
          final inset = 2.0 + stretch * 8;
          return Stack(children: [
            Positioned.directional(
              textDirection: Directionality.of(context),
              start: start.toDouble(), width: width, top: inset, bottom: inset,
              child: AnimatedScale(
                duration: reduced ? Duration.zero : const Duration(milliseconds: 110),
                scale: pressed && !reduced ? .96 : 1,
                child: DecoratedBox(decoration: BoxDecoration(
                  color: (dark ? Colors.white : colors.surface).withValues(alpha: dark ? .15 : .45),
                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                )),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
