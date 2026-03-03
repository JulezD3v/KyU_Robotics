import 'package:flutter/material.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0), // Light grey background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            /// ===== TOP SECTION =====
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  /// Circular Container with Shadow
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.precision_manufacturing, // Robot-like icon
                        color: Colors.green,
                        size: 80,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Title Text
                  const Text(
                    "KyU Robotics Team",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Small Indicator Lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _line(isActive: false),
                      const SizedBox(width: 8),
                      _line(isActive: true),
                      const SizedBox(width: 8),
                      _line(isActive: false),
                    ],
                  ),
                ],
              ),
            ),

            /// ===== BOTTOM SECTION =====
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [

                  /// University Logo Circle
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Image.asset(
                        "assets/kyu_logo.png", // Add logo to assets
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "IN PARTNERSHIP WITH",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1.5,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Kirinyaga University",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Indicator Line Widget
  static Widget _line({required bool isActive}) {
    return Container(
      height: 6,
      width: 40,
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.green.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}