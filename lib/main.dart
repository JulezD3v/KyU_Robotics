import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

/// Root App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothTestPage(),
    );
  }
}

/// Bluetooth Test Page
class BluetoothTestPage extends StatefulWidget {
  const BluetoothTestPage({super.key});

  @override
  State<BluetoothTestPage> createState() => _BluetoothTestPageState();
}

class _BluetoothTestPageState extends State<BluetoothTestPage> {
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  bool isConnected = false;
  String status = "Not Connected";

  @override
  void initState() {
    super.initState();
    requestPermissions();
    getPairedDevices();
  }

  /// Request Bluetooth permissions
  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  /// Get paired devices
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      devices = bondedDevices;
    });
  }

  /// Connect to selected device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);

      setState(() {
        isConnected = true;
        status = "Connected to ${device.name}";
      });

      print("Connected to the device");

      connection!.input!.listen((data) {
        print("Received: ${String.fromCharCodes(data)}");
      }).onDone(() {
        setState(() {
          isConnected = false;
          status = "Disconnected";
        });
      });
    } catch (e) {
      print("Connection error: $e");
      setState(() {
        status = "Connection Failed";
      });
    }
  }

  /// Disconnect
  void disconnect() {
    if (connection != null) {
      connection!.close();
      setState(() {
        isConnected = false;
        status = "Disconnected";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Robot Car Bluetooth Test"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// Status Text
          Text(
            status,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          /// Device List
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = devices[index];

                return ListTile(
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed: isConnected
                        ? null
                        : () => connectToDevice(device),
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),

          /// Disconnect Button
          if (isConnected)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Disconnect"),
              ),
            ),
        ],
      ),
    );
  }
}