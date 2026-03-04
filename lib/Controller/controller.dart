import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  //FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  String connectionStatus = 'Not Connected';

  // HM-10 UUIDs
  final Guid serviceUUID = Guid('0000FFE0-0000-1000-8000-00805F9B34FB');
  final Guid characteristicUUID = Guid('0000FFE1-0000-1000-8000-00805F9B34FB');

  void _connect() async {
    setState(() => connectionStatus = 'Scanning...');

    // Start scan
   // await flutterBlue.startScan(timeout: const Duration(seconds: 5));
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    // Listen for scan results and find HMSoft
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.advertisementData.localName.contains('HMSoft')) {
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          return;
        }
      }
    });

    // Stop scanning after timeout
    await Future.delayed(const Duration(seconds: 5));
    FlutterBluePlus.stopScan();
    subscription.cancel();

    if (connectedDevice == null) {
      setState(() => connectionStatus = 'No HMSoft found');
    }
  }

 void _connectToDevice(BluetoothDevice device) {
  setState(() => connectionStatus = 'Waiting for device to connect...');

  // Listen for connection state changes
  device.connectionState.listen((state) async {
    if (state == BluetoothConnectionState.connected) {
      // Device is now connected automatically
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid == serviceUUID) {
          for (var char in service.characteristics) {
            if (char.uuid == characteristicUUID) {
              targetCharacteristic = char;

              setState(() {
                connectedDevice = device;
                connectionStatus = 'Connected!';
              });
              return;
            }
          }
        }
      }

      setState(() => connectionStatus = 'Characteristic not found');
    }
  });

  // Optional: update status while scanning/auto-connecting
  setState(() => connectionStatus = 'Scanning & auto-connecting...');
}
  void _moveForward() async {
    if (targetCharacteristic != null) {
      await targetCharacteristic!.write([0x46]); // 'F' in ASCII
      print('Sent Forward command');
    } else {
      print('Not connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLE Robot Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(connectionStatus),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connect,
              child: const Text('Connect to HMSoft'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: connectedDevice != null ? _moveForward : null,
              child: const Text('Move Forward'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }
}