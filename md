import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
 
class BleScreen extends StatefulWidget {
  const BleScreen({super.key});
 
  @override
  State<BleScreen> createState() => _BleScreenState();
}
 
class _BleScreenState extends State<BleScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String status = "Not Connected";
  bool isScanning = false;
  bool isConnected = false;
 
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic; // HM-10 uses same char for TX/RX
 
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
 
  // HM-10 UUIDs (standard firmware defaults)
  static const String _hm10ServiceUUID    = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String _hm10CharUUID       = "0000ffe1-0000-1000-8000-00805f9b34fb";
  static const String _targetDeviceName   = "HMSoft"; // Change if your module differs
 
  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }
 
  // ── Permissions ────────────────────────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
 
    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted,
    );
 
    if (!allGranted) {
      _setStatus("Permissions denied – cannot scan");
    }
    return allGranted;
  }
 
  // ── BLE helpers ────────────────────────────────────────────────────────────
  void _setStatus(String msg) {
    if (mounted) setState(() => status = msg);
  }
 
  Future<void> scanAndConnect() async {
    // 1. Permissions first
    if (!await _requestPermissions()) return;
 
    // 2. Make sure adapter is on (adapterState behaves like BehaviorSubject, so .first is fine)
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _setStatus("Bluetooth is OFF – please enable it");
      return;
    }
 
    // 3. Cleanup previous scans and subscriptions
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
 
    setState(() {
      isScanning = true;
      status = "Scanning…";
    });
    
    // Flag to prevent multiple connection attempts
    bool deviceFound = false;
 
    // 4. Listen BEFORE starting scan to avoid missing early results
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        for (final result in results) {
          final name = result.device.platformName;
          
          if (name == _targetDeviceName) {
            // FIX 1: Immediately flag and cancel subscription. 
            // This prevents the listener from triggering multiple times and firing off multiple 
            // _connectToDevice requests, which causes device.connect() to crash.
            if (deviceFound) return;
            deviceFound = true;
            
            debugPrint("Found: $name  RSSI: ${result.rssi}");
            
            _scanSubscription?.cancel();
            _scanSubscription = null;
            
            FlutterBluePlus.stopScan();
            _connectToDevice(result.device);
            return;
          }
        }
      },
      onError: (e) => _setStatus("Scan error: $e"),
    );
 
    // 5. Start scan
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
    );
 
    // 6. After timeout, check if we found anything
    await Future.delayed(const Duration(seconds: 9));
    if (!deviceFound && mounted && isScanning && !isConnected) {
      setState(() {
        status = "Device '$_targetDeviceName' not found";
        isScanning = false;
      });
    }
  }
 
  Future<void> _connectToDevice(BluetoothDevice device) async {
    _setStatus("Connecting…");
    
    // FIX 3: Cancel any lingering stream subscriptions for old connection attempts
    await _connectionSubscription?.cancel();

    try {
      // FIX 2: Defensive Disconnect. Android very frequently holds onto zombie GATT 
      // connections from previous testing sessions. 
      await device.disconnect();
      
      // Delay slightly so the OS Bluetooth stack can register the disconnect
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Attempt connection. 
      // NOTE: On some HM-10 modules, flutter requests an MTU of 512 which the module rejects.
      // If the error persists, try passing `mtu: null` instead to skip MTU negotiation.
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10),);
    } catch (e) {
      _setStatus("Connection failed: $e");
      if (mounted) setState(() => isScanning = false);
      return;
    }
 
    connectedDevice = device;
 
    // Listen for disconnection
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted) {
          setState(() {
            isConnected = false;
            isScanning = false;
            status = "Disconnected";
            txCharacteristic = null;
          });
        }
      }
    });
 
    // Discover services to find the HM-10 characteristic
    await _discoverServices(device);
  }
 
  Future<void> _discoverServices(BluetoothDevice device) async {
    _setStatus("Discovering services…");
 
    try {
      final services = await device.discoverServices();
 
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _hm10ServiceUUID) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _hm10CharUUID) {
              txCharacteristic = char;
 
              // Enable notifications so we can receive data from the car
              if (char.properties.notify) {
                await char.setNotifyValue(true);
                char.onValueReceived.listen((value) {
                  final received = utf8.decode(value);
                  debugPrint("Received from HM-10: $received");
                });
              }
 
              setState(() {
                isConnected = true;
                isScanning = false;
                status = "Connected to ${device.platformName}";
              });
              return;
            }
          }
        }
      }
 
      _setStatus("HM-10 service not found on device");
      await device.disconnect();
    } catch (e) {
      _setStatus("Service discovery failed: $e");
    }
  }
 
  /// Send a single-character command to the robotic car (e.g. 'F', 'B', 'L', 'R', 'S')
  Future<void> sendCommand(String command) async {
    if (txCharacteristic == null || !isConnected) {
      _setStatus("Not connected");
      return;
    }
    try {
      await txCharacteristic!.write(
        utf8.encode(command),
        withoutResponse: txCharacteristic!.properties.writeWithoutResponse,
      );
      debugPrint("Sent: $command");
    } catch (e) {
      _setStatus("Send failed: $e");
    }
  }
 
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    setState(() {
      isConnected = false;
      status = "Disconnected";
      txCharacteristic = null;
    });
  }
 
  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Robot Control"),
        backgroundColor: Colors.green,
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: "Disconnect",
              onPressed: disconnect,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      color: isConnected ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 16,
                          color: isConnected ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isScanning) const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
              ),
            ),
 
            const SizedBox(height: 24),
 
            if (!isConnected)
              ElevatedButton.icon(
                onPressed: isScanning ? null : scanAndConnect,
                icon: const Icon(Icons.search),
                label: Text(isScanning ? "Scanning…" : "Scan & Connect"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
 
            const SizedBox(height: 32),
 
            if (isConnected) ...[
              const Text(
                "Controls",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDpad(),
            ],
          ],
        ),
      ),
    );
  }
 
  Widget _buildDpad() {
    return Column(
      children: [
        _directionButton("▲ Forward", "F"),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _directionButton("◀ Left", "L"),
            const SizedBox(width: 8),
            _directionButton("■ Stop", "S", color: Colors.red),
            const SizedBox(width: 8),
            _directionButton("Right ▶", "R"),
          ],
        ),
        const SizedBox(height: 8),
        _directionButton("▼ Backward", "B"),
      ],
    );
  }
 
  Widget _directionButton(String label, String command, {Color? color}) {
    return ElevatedButton(
      onPressed: () => sendCommand(command),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(110, 50),
      ),
      child: Text(label),
    );
  }
}
 