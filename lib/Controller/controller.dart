import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  String status = "Not Connected";
  bool isScanning = false;

  Future<void> scanAndConnect() async {
    setState(() {
      isScanning = true;
      status = "Scanning...";
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.platformName == "HMSoft") {
          await FlutterBluePlus.stopScan();

            //await result.device.connect();
          setState(() {
            status = "Connected to ${result.device.platformName}";
            isScanning = false;
          });

          return;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 6));

    if (status == "Scanning...") {
      setState(() {
        status = "Device Not Found";
        isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Connect"),
        backgroundColor: Colors.green,
      ),
      
    );
  }
}