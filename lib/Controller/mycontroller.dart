import 'package:flutter/material.dart';
import 'package:kyu_robotics/Core/widgets/dropdown_widget.dart';
import '/Core/colors/colors.dart';
import '/Controller/blecontroller_widget.dart';
import '/Controller/control_circle.dart';
import '/Core/widgets/softbutton.dart';
import '/Core/widgets/togglecard.dart';
import '/Core/widgets/actioncard.dart';
import'/Core/widgets/drivebutton.dart';
enum DriveType {
  twoWheel,
  threeWheel,
}
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
  int selectedDrive = 2;
  final MyBleController _controller = MyBleController();
 
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return SingleChildScrollView(
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
                          "KyU Robotics Club",
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
                      if (!_controller.isConnected) {
                        _controller.connect();
                      }
                    },
                    child: Column(
                      children: [
                        Text(
                          _controller.isConnected
                              ? "BLUETOOTH CONNECTED"
                              : _controller.isScanning
                              ? "SCANNING..."
                              : "CONNECT TO ROBOT",
                          style: TextStyle(
                            color: _controller.isConnected
                                ? AppColors.primaryGreen
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2,
                          ),
                        ),

                        SizedBox(height: 3),
                        Text(
                          _controller.isConnected
                              ? _controller.status
                              : _controller.isScanning
                              ? _controller
                                    .status // "Scanning…" / "Connecting…" / "Discovering…"
                              : _controller.status == "Not Connected"
                              ? "Tap to connect"
                              : _controller.status,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

        Padding(
          padding: EdgeInsets.only(left: 40.0),
          child: Row(
            children: [
          
              DriveButton(
                label: "2-Wheel",
                icon: Icons.directions_bike,
                isActive: selectedDrive == 2,
                onTap: () {
                  setState(() {
                    selectedDrive = 2;
                  });
                },
              ),
          
              const SizedBox(width: 12),
          
              DriveButton(
                label: "3-Wheel",
                icon: Icons.electric_rickshaw,
                isActive: selectedDrive == 3,
                onTap: () {
                  setState(() {
                    selectedDrive = 3;
                  });
                },
              ),
          
            ],
          ),
        ),

        const SizedBox(height: 30),
                  // Controller
                  DirectionalControl(controller: _controller),

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

                              if (stopActive) {
                                // Turn ON → switch to Camera mode (index 3)
                                _controller.sendCommand('3'); // direct jump
                                // OR: controller.switchMode(3);       // if you exposed switchMode in controller
                              } else {
                                // Turn OFF → go back to BLE Manual (mode 0)
                                _controller.sendCommand('0');
                                // OR remember previous mode if you want more advanced logic
                              }
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

                                // If camera is turned off, stop should also turn off
                                if (!startActive) {
                                  stopActive = false;
                                }
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
                    child: Row(
                      children: [
                        // Increase
                        Expanded(
                          child: ActionCard(
                            title: "Increase",
                            icon: Icons.electric_bolt_rounded,
                            highlight: _controller.isConnected,
                            onTap: _controller.isConnected
                                ? () => _controller.increaseSpeed()
                                : () {},
                          ),
                        ),

                        // Decrease
                        Expanded(
                          child: ActionCard(
                            title: "Decrease ",
                            icon: Icons.slow_motion_video_rounded,
                            highlight: _controller.isConnected,
                            onTap: _controller.isConnected
                                ? () => _controller.decreaseSpeed()
                                : () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200, // give dropdown a fixed width
                    child: ModeSelectorDropdown(controller: _controller),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    "assets/schoolLogo.png",
                    height: 40, // small
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
