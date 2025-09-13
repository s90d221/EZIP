import 'package:flutter/material.dart';
import 'package:ezip/core/constants.dart';

class EzipLogoLarge extends StatelessWidget {
  const EzipLogoLarge();
  @override
  Widget build(BuildContext context) {
    return Text(
      'EZIP',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: kBrandBlue,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }
}
