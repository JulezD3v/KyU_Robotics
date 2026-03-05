import 'package:flutter/material.dart';
import 'package:kyu_robotics/Core/widgets/softbox.dart';

class SoftBoxButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final double? width;

  const SoftBoxButton({
    super.key,
    required this.child,
    this.onPressed,
    this.margin,
    this.padding,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        padding: padding,
        decoration: softBox(), // same design
        child: child,
      ),
    );
  }
}