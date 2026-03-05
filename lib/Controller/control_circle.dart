import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/Core/colors/colors.dart';
import 'blecontroller_widget.dart';

class DirectionalControl extends StatelessWidget {
  const DirectionalControl({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming these are defined in your AppColors
    // final bgColor = AppColors.bgColor;           // e.g. Color(0xFFE0E0E0) or off-white
    // final primaryGreen = AppColors.primaryGreen; // e.g. Colors.teal[700]

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Outer subtle ring (light blue-ish track)
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.15), // very light blue-grey
                width: 14,
              ),
            ),
          ),

          // 2. Main neumorphic circle
          Container(
            width: 220, // slightly smaller than outer ring
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor, // your background color
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  offset: const Offset(-8, -8),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  offset: const Offset(8, 8),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // 3. Four arrow buttons around the edge
         Positioned(
  top: 20,
  child: _buildArrowButton(context, Icons.arrow_upward_rounded),
),
Positioned(
  bottom: 20,
  child: _buildArrowButton(context, Icons.arrow_downward_rounded),
),
Positioned(
  left: 20,
  child: _buildArrowButton(context, Icons.arrow_back_rounded),
),
Positioned(
  right: 20,
  child: _buildArrowButton(context, Icons.arrow_forward_rounded),
),
          // 4. Center icon (not a button)
          const Icon(
            Icons.open_with_rounded, // or Icons.drag_indicator, etc.
            size: 48,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

 Widget _buildArrowButton(BuildContext context, IconData icon) {

  final ble = Provider.of<MyBleController>(context, listen: false);

  return GestureDetector(
    onTap: () {

      if (icon == Icons.arrow_upward_rounded) {
        ble.sendCommand("F"); // Forward
      }

      if (icon == Icons.arrow_downward_rounded) {
        ble.sendCommand("B"); // Backward
      }

      if (icon == Icons.arrow_back_rounded) {
        ble.sendCommand("L"); // Left
      }

      if (icon == Icons.arrow_forward_rounded) {
        ble.sendCommand("R"); // Right
      }

    },
    child: Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 32,
        color: AppColors.primaryGreen.withOpacity(0.9),
      ),
    ),
  );
}
}