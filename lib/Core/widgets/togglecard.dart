import 'package:flutter/material.dart';
import './softbox.dart';

  class ToggleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

 const ToggleCard({
  super.key,
  required this.active,
  required this.title,
  required this.icon,
  required this.onTap,
});

  @override
  Widget build(BuildContext context) {
    
    return GestureDetector( // detect tap
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: softBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 15),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 70,
                height: 34,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: active
                      ? const Color(0x22117A65)
                      : Colors.grey.shade300,
                ),

                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      active? Alignment.centerRight : Alignment.centerLeft,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: active
                        ? const Color(0xFF117A65)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}