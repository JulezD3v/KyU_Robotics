import 'package:flutter/material.dart';
import '/Core/colors/colors.dart';
import '/Controller/ble_tester.dart';
import '/Controller/control_circle.dart';
import '/Core/widgets/softbutton.dart';
import '/Core/widgets/togglecard.dart';
import '/Core/widgets/actioncard.dart';

class Controller extends StatefulWidget {
  const Controller({super.key});

  @override
  State<Controller> createState() => _ControllerState();
}

class _ControllerState extends State<Controller> {
  bool startActive = false;
  bool stopActive = false;
  bool startHighlight = false;
  bool stopHighlight = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.arrow_back_ios_new),
                    Text(
                      "KyU Robotics Team",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.more_horiz),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Connected Card
              SoftBoxButton(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () {
                  print("Connection widget tapped");
                },
                child: Column(
                  children: [
                    Text(
                      "CONNECT",
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text("Latency: 14ms"),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Circular Controller
             DirectionalControl(),
              const SizedBox(height: 40),

              // Stop and switch to camera
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ToggleCard(
                        title: "Stop",
                        icon: Icons.stop_screen_share_sharp,
                        active: stopActive,
                        onTap: () {
                          setState(() {
                            stopActive = !stopActive;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: ToggleCard(
                        title: "Camera",
                        icon: Icons.camera,
                        active: startActive,
                        onTap: () {
                          setState(() {
                            startActive = !startActive;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Reduce & Boost Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:Row(
  children: [
    Expanded(
      child: ActionCard(
        title: "Increase",
        icon: Icons.electric_bolt_rounded,
        highlight: startHighlight,
        onTap: () {
          setState(() {
            startHighlight = !startHighlight;
          });
        },
      ),
    ),

    const SizedBox(width: 20),

    Expanded(
      child: ActionCard(
        title: "Decrease",
        icon: Icons.slow_motion_video_rounded,
        highlight: stopHighlight,
        onTap: () {
          setState(() {
            stopHighlight = !stopHighlight;
          });
        },
      ),
    ),
  ],
)
),
              const SizedBox(height: 20),
              Image.asset(
                "assets/schoolLogo.png",
                height: 40, // small
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildArrowButton(IconData icon) {
    return GestureDetector(
      onTap: () {
        // Add your navigation/zoom logic here
        print("Arrow ${icon.toString()} pressed");
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

