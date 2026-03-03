import 'package:flutter/material.dart';
import 'package:kyu_robotics/Controller/controller.dart'; // assuming this is where BleScreen lives

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    // Just forward it — no need to re-assign _controller
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BleScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 253, 251),
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
                      shape: BoxShape.circle,
                      // Light source from top-left
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white, // strong highlight
                          Color(0xFFE0E0E0), // mid tone
                          Color(0xFFBDBDBD), // darker edge
                        ],
                      ),
                      boxShadow: [
                        // Bottom-right shadow (depth)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(12, 12),
                          blurRadius: 20,
                        ),
                        // Top-left highlight shadow (subtle lift)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.9),
                          offset: const Offset(-8, -8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.precision_manufacturing,
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

                  const SizedBox(height: 10),

                  /// Small Indicator Lines
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "INNOVATION IN MOTION",
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  /// Loading Bar
                  SizedBox(
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.green,
                          // Optional: make it actually animate with value
                          // value: _controller.value,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Small Logo (no container)
                  Image.asset(
                    "assets/schoolLogo.png",
                    height: 40, // small
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Important: always dispose controllers!
    super.dispose();
  }
}