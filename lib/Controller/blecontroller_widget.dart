// lib/Controller/mycontroller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class MyBleController extends ChangeNotifier {
  // ── Public observable state ──
  String status = "Not Connected";
  bool isScanning = false;
  bool isConnected = false;
  int currentMode = 0; // ← ADD THIS: tracks 0=BLE, 1=CARD, 2=LINE, 3=FACE

  // ── Private BLE fields ──
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;

  StreamSubscription? _scanSub;
  StreamSubscription? _connSub;

  static const String serviceUUID = "ffe0";
  static const String charUUID   = "ffe1";
  static const String targetName = "HMSoft"; // ← change if different

  // ── Public API for UI to call ──

  Future<void> connect() => scanAndConnect();

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _updateState(false, "Disconnected");
  }

 Future<void> sendCommand(String cmd) async {
    if (_txCharacteristic == null || !isConnected) {
      _updateState(isConnected, "Not connected");
      return;
    }
    try {
      await _txCharacteristic!.write(
        utf8.encode(cmd),
        withoutResponse: _txCharacteristic!.properties.writeWithoutResponse,
      );
      // ── ADD: sync local mode tracking ──
      if (cmd == 'M') {
        currentMode = (currentMode + 1) % 4;
        notifyListeners();
      } else if (['0', '1', '2', '3'].contains(cmd)) {
        currentMode = int.parse(cmd);
        notifyListeners();
      }
      debugPrint("Sent → $cmd");
    } catch (e) {
      debugPrint("Send error: $e");
    }
  }

  Future<void> increaseSpeed() async {
  await sendCommand("a"); 
  _updateState(isConnected, "Speed ↑");
}

Future<void> decreaseSpeed() async {
  await sendCommand("d");  
  _updateState(isConnected, "Speed ↓");
}
  // ── Internal logic (same as before, just cleaned a bit) ──

  Future<bool> _requestPermissions() async {
    var statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  }

void updateState(bool connected, String msg) {
  isConnected = connected;
  isScanning = false;
  status = msg;
  notifyListeners();

  // If it's a failure message, reset status back to idle after 3 seconds
  if (!connected && msg != "Disconnected" && msg != "Not Connected") {
    Future.delayed(const Duration(seconds: 3), () {
      status = "Not Connected";
      notifyListeners();
    });
  }
}
  Future<void> scanAndConnect() async {
    if (!await _requestPermissions()) {
      _updateState(false, "Permissions denied");
      return;
    }

    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _updateState(false, "Bluetooth OFF");
      return;
    }

    await _scanSub?.cancel();
    _scanSub = null;
    await FlutterBluePlus.stopScan();

    isScanning = true;
    _updateState(false, "Scanning…");

    bool found = false;

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        if (r.device.platformName == targetName) {
          if (found) return;
          found = true;

          _scanSub?.cancel();
          _scanSub = null;
          FlutterBluePlus.stopScan();

          _connect(r.device);
          return;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    await Future.delayed(const Duration(seconds: 9));
    if (!found && !isConnected) {
      _updateState(false, "HMSoft not found");
    }
  }

/// Switching Camera Mode 

 Future<void> switchMode(int index) async {
    await sendCommand(index.toString()); // sends '0','1','2','3'
    currentMode = index;
    notifyListeners();
  }

  Future<void> nextMode() async {
    await sendCommand("M");
    currentMode = (currentMode + 1) % 4;
    notifyListeners();
  }

  // Mode name helper for UI labels
  String get currentModeName {
    const names = ["BLE Manual", "Card Detection", "Line Following", "Face Tracking"];
    return names[currentMode];
  }
  Future<void> _connect(BluetoothDevice dev) async {
    _updateState(false, "Connecting…");

    await _connSub?.cancel();

    try {
      await dev.disconnect(); // defensive
      await Future.delayed(const Duration(milliseconds: 400));

      await dev.connect(timeout: const Duration(seconds: 12), license: License.free);
    } catch (e) {
      _updateState(false, "Connect failed");
      return;
    }

    _connectedDevice = dev;

    _connSub = dev.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _updateState(false, "Disconnected");
      }
    });

    await _discover(dev);
  }

  Future<void> _discover(BluetoothDevice dev) async {
    _updateState(false, "Discovering…");

    try {
      var services = await dev.discoverServices();
      for (var svc in services) {
        if (svc.uuid.toString().toLowerCase() == serviceUUID) {
          for (var c in svc.characteristics) {
            if (c.uuid.toString().toLowerCase() == charUUID) {
              _txCharacteristic = c;

              if (c.properties.notify) {
                await c.setNotifyValue(true);
                c.onValueReceived.listen((bytes) {
                  debugPrint("← ${utf8.decode(bytes)}");
                });
              }

              _updateState(true, "Connected to ${dev.platformName}");
              return;
            }
          }
        }
      }
      _updateState(false, "Service not found");
      await dev.disconnect();
    } catch (e) {
      _updateState(false, "Discovery failed");
    }
  }

  void _updateState(bool connected, String msg) {
    isConnected = connected;
    isScanning = false;
    status = msg;
    notifyListeners(); // ← this is key – tells UI to rebuild
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _connectedDevice?.disconnect();
    super.dispose();
  }
}