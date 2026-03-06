import 'dart:async';
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
          // 1. Outer subtle ring (unchanged)
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

          // 2. Main neumorphic circle (unchanged)
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

          // 3. Four arrow buttons (now with tap + long-press)
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

          // 4. Center emergency STOP button (always active)
          GestureDetector(
            onTap: () {
              if (controller.isConnected) {
                controller.sendCommand('S');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Emergency STOP sent"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-5, -5),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: const Offset(5, 5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.stop_rounded,
                size: 48,
                color: controller.isConnected ? Colors.redAccent : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon) {
    String command = 'S'; // fallback

    if (icon == Icons.arrow_upward_rounded)    command = 'F';
    if (icon == Icons.arrow_downward_rounded)  command = 'B';
    if (icon == Icons.arrow_back_rounded)      command = 'L';
    if (icon == Icons.arrow_forward_rounded)   command = 'R';

    Timer? holdTimer;

    void startContinuous() {
      if (!controller.isConnected) return;

      // Send one command immediately on press
      controller.sendCommand(command);

      // Then repeat every ~180 ms for continuous movement
      holdTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
        if (controller.isConnected) {
          controller.sendCommand(command);
        } else {
          timer.cancel();
        }
      });
    }

    void stopContinuous() {
      holdTimer?.cancel();
      holdTimer = null;

      // Optional: send explicit stop when finger lifts
      // Uncomment if you want car to stop immediately on release
      // controller.sendCommand('S');
    }

    return GestureDetector(
      // Long press → continuous
      onTapDown: (_) => startContinuous(),
      onTapUp: (_) => stopContinuous(),
      onTapCancel: () => stopContinuous(),

      // Short tap → single command (brief movement)
      onTap: () {
        if (controller.isConnected) {
          controller.sendCommand(command);
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
          color: controller.isConnected
              ? AppColors.primaryGreen.withOpacity(0.9)
              : Colors.grey.withOpacity(0.6),
        ),
      ),
    );
  }
}