import 'package:flutter/material.dart';
import '/Core/colors/colors.dart';
import '/Core/widgets/softbox.dart';

class Controller extends StatefulWidget {
  const Controller({super.key});

  @override
  State<Controller> createState() => _ControllerState();
}

class _ControllerState extends State<Controller> {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: softBox(),
                child: Column(
                  children: const [
                    Text(
                      "CONNECTED",
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
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white,
                        offset: Offset(-6, -6),
                        blurRadius: 12),
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(6, 6),
                        blurRadius: 12),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.open_with,
                    size: 40,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          
              const SizedBox(height: 40),
          
              // Power & Lights Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    Expanded(child: _ToggleCard(title: "Power", icon: Icons.power_settings_new, active: true)),
                    SizedBox(width: 20),
                    Expanded(child: _ToggleCard(title: "Lights", icon: Icons.lightbulb, active: false)),
                  ],
                ),
              ),
          
              const SizedBox(height: 30),
          
              // Reset & Boost Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    Expanded(child: _ActionCard(title: "Reset", icon: Icons.restart_alt)),
                    SizedBox(width: 20),
                    Expanded(child: _ActionCard(title: "Boost", icon: Icons.flash_on, highlight: true)),
                  ],
                ),
              ),
          
              const SizedBox(height: 30,),
          
              // Bottom Navigation
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: AppColors.bgColor,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, -4),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _NavItem(icon: Icons.grid_view, label: "CONTROL", active: true),
                    _NavItem(icon: Icons.bar_chart, label: "STATS"),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryGreen,
                      child: Icon(Icons.sports_esports, color: Colors.white),
                    ),
                    _NavItem(icon: Icons.history, label: "LOGS"),
                    _NavItem(icon: Icons.settings, label: "CONFIG"),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;

  const _ToggleCard({
    required this.title,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: CircleAvatar(
              backgroundColor: active ? const Color(0xFF117A65) : Colors.grey.shade300,
              radius: 18,
            ),
          )
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool highlight;

  const _ActionCard({
    required this.title,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: softBox(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: highlight ? const Color(0xFF117A65) : null),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: highlight ? const Color(0xFF117A65) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: active ?  Color(0xFF117A65) : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ?  Color(0xFF117A65) : Colors.grey,
          ),
        )
      ],
    );
  }
}