import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SnapCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool animate;
  final VoidCallback? onTap;

  const SnapCard({
    super.key,
    required this.child,
    this.elevation = 4.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.animate = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor ?? Theme.of(context).cardTheme.color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    if (animate) {
      return card.animate()
          .fade(duration: const Duration(milliseconds: 300))
          .scale(begin: const Offset(0.95, 0.95), duration: const Duration(milliseconds: 300));
    }

    return card;
  }
} 