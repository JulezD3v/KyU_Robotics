import'package:flutter/material.dart';
import 'actioncard.dart';
import '/Controller/blecontroller_widget.dart';
import 'softbox.dart';
class ModeSelectorDropdown extends StatefulWidget {
  final MyBleController controller;

  const ModeSelectorDropdown({super.key, required this.controller});

  @override
  State<ModeSelectorDropdown> createState() => _ModeSelectorDropdownState();
}

class _ModeSelectorDropdownState extends State<ModeSelectorDropdown> {
  bool _isOpen = false;

  static const List<Map<String, dynamic>> _modes = [
    {"label": "BLE Manual",      "index": 0, "icon": Icons.bluetooth},
    {"label": "Card Detection",  "index": 1, "icon": Icons.style_rounded},
    {"label": "Line Following",  "index": 2, "icon": Icons.linear_scale_rounded},
    {"label": "Face Tracking",   "index": 3, "icon": Icons.face_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final activeMode = _modes.firstWhere(
      (m) => m["index"] == widget.controller.currentMode,
    );

    return Column(
      children: [
        // ── Header — always visible ──
        GestureDetector(
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: softBox(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  activeMode["icon"] as IconData,
                  color: const Color(0xFF117A65),
                ),
                const SizedBox(width: 8),
                Text(
                  activeMode["label"] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF117A65),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF117A65),
                ),
              ],
            ),
          ),
        ),

        // ── Dropdown items ──
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: softBox(),
            child: Column(
              children: _modes.map((mode) {
                final isActive = widget.controller.currentMode == mode["index"];
                return ActionCard(
                  title: mode["label"] as String,
                  icon: mode["icon"] as IconData,
                  highlight: isActive,
                  onTap: () {
                    widget.controller.switchMode(mode["index"] as int);
                    setState(() => _isOpen = false); // close after selection
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}