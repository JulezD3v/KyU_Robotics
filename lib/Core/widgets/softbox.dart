import 'package:flutter/material.dart';
import 'package:kyu_robotics/Core/colors/colors.dart';


BoxDecoration softBox() {
  return const BoxDecoration(
    color: AppColors.bgColor,
    borderRadius: BorderRadius.all(Radius.circular(20)),
    boxShadow: [
      BoxShadow(
        color: Colors.white,
        offset: Offset(-6, -6),
        blurRadius: 12,
      ),
      BoxShadow(
        color: Colors.black12,
        offset: Offset(6, 6),
        blurRadius: 12,
      ),
    ],
  );
}