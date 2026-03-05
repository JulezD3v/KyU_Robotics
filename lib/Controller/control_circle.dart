import 'package:flutter/material.dart';
import '/Core/colors/colors.dart';
import 'blecontroller_widget.dart';

class DirectionalControl extends StatelessWidget {
  final MyBleController controller;

  const DirectionalControl({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.blueGrey.withOpacity(0.15),
                width: 14,
              ),
            ),
          ),

          // 2. Main neumorphic circle
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor,
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
            child: _buildArrowButton(Icons.arrow_upward_rounded),
          ),
          Positioned(
            bottom: 20,
            child: _buildArrowButton(Icons.arrow_downward_rounded),
          ),
          Positioned(
            left: 20,
            child: _buildArrowButton(Icons.arrow_back_rounded),
          ),
          Positioned(
            right: 20,
            child: _buildArrowButton(Icons.arrow_forward_rounded),
          ),
          // 4. Center icon (not a button)
          Icon(
            Icons.open_with_rounded,
            size: 48,
            color: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon) {
    return GestureDetector(
      onTap: () {
        if (controller.isConnected) {
          String cmd = '';
          if (icon == Icons.arrow_upward_rounded)    cmd = 'F';
          if (icon == Icons.arrow_downward_rounded)  cmd = 'B';
          if (icon == Icons.arrow_back_rounded)      cmd = 'L';
          if (icon == Icons.arrow_forward_rounded)   cmd = 'R';
          controller.sendCommand(cmd);
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