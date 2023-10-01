


import 'package:flutter/material.dart';

class BottomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(1, 9);
    path.lineTo(9, size.height);
    path.quadraticBezierTo(
      size.width / 4,
      size.height + 20,
      size.width / 2,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height + 20,
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
