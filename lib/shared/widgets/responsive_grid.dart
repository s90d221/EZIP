import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<Widget> children;
  const ResponsiveGrid({super.key, required this.columns, required this.gap, required this.children});

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: children.map((w) => Padding(padding: EdgeInsets.only(bottom: gap), child: w)).toList(),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final width = (c.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children.map((w) => SizedBox(width: width, child: w)).toList(),
        );
      },
    );
  }
}