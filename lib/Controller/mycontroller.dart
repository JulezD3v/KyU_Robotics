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
  bool isConnected = false;
  


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
                  children: [
                    const Icon(Icons.arrow_back_ios_new),
                    const Text(
                      "KyU Robotics Team",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Image.asset(
                "assets/schoolLogo.png",
                height: 40, // small
                fit: BoxFit.contain,
              ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                      "BLUETOOTH CONNECTED",
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
              
              const SizedBox(height: 35),

              // Controller
             DirectionalControl(), // the circle
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
        highlight: true,
        onTap: () {
    if (isConnected) {
      increaseSpeed();
    } else {
      // optional: show snackbar or update status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not connected")),
      );
    }
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
