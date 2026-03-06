import'package:flutter/material.dart';
import 'drivebutton.dart';

enum DriveType {
  twoWheel,
  threeWheel,
}
class DriveSelector extends StatefulWidget {
  const DriveSelector({super.key});

  @override
  State<DriveSelector> createState() => _DriveSelectorState();
}

class _DriveSelectorState extends State<DriveSelector> {
  DriveType selected = DriveType.twoWheel;

  void selectDrive(DriveType type) {
    setState(() {
      selected = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DriveButton(
          label: "2-Wheel",
          icon: Icons.directions_car,
          isActive: selected == DriveType.twoWheel,
          onTap: () => selectDrive(DriveType.twoWheel),
        ),
        const SizedBox(width: 12),
        DriveButton(
          label: "3-Wheel",
          icon: Icons.electric_rickshaw,
          isActive: selected == DriveType.threeWheel,
          onTap: () => selectDrive(DriveType.threeWheel),
        ),
      ],
    );
  }
}