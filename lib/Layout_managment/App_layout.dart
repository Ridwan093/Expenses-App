import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget webScreen;
  final Widget mobileScreen;

  const Responsive(
      {super.key, required this.webScreen, required this.mobileScreen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrowScreen = constraints.maxWidth < 600;

      return isNarrowScreen ? mobileScreen : webScreen;
    });
  }
}
