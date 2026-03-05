import 'package:flutter/material.dart';
import '/Core/colors/colors.dart';
import '/Controller/blecontroller_widget.dart';
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
          builder: (context, child){
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
                  if (!_controller.isConnected) {
                    _controller.connect();
                  }
                },
                child: Column(
                  children: [
                    Text(
                      _controller.isConnected
                          ? "BLUETOOTH CONNECTED"
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
                          : "Tap to connect",
                    ),
                  ],
                ),),
                const SizedBox(height: 35),
          
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

    // If Stop is pressed, Camera should remain ON
    if (stopActive) {
      startActive = true;
    }
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
                  child:Row(
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
          );
  }),
  ), );
  }
}
