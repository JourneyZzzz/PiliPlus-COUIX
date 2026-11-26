import 'package:flutter/widgets.dart';

/// Space a scrolling page reserves at its start for the overlaid home header.
class ScrollHeaderInset extends InheritedWidget {
  const ScrollHeaderInset({super.key, required this.height, required super.child});

  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ScrollHeaderInset>()?.height ?? 0;

  @override
  bool updateShouldNotify(ScrollHeaderInset oldWidget) => height != oldWidget.height;
}
