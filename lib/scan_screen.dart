import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static final snackBarKeyB = GlobalKey<ScaffoldMessengerState>();
  List<BluetoothDevice> systemDevices = [];
  List<ScanResult> scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FlutterBluePlus.onScanResults.listen((event) {
        if (event.isNotEmpty) {
          print("result of on Scan Results ${event.last.device.advName}");
        }
      });
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (results.isNotEmpty) {
          print("results of the scan devices ${results.last.device.advName}");
        }
        scanResults = results;
        if (mounted) {
          setState(() {});
        }
      }, onError: (e, s) {
        debugPrint("Error In Scanning $e");
        debugPrintStack(stackTrace: s);
      });

      _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
        print('Scanning State $state');
        _isScanning = state;
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(minutes: 1));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Future onScanPressed() async {
    try {
      systemDevices = await FlutterBluePlus.systemDevices;
      print("System Devices ${systemDevices}");
    } catch (e, s) {
      debugPrint("System Devices Error $e");
      debugPrintStack(stackTrace: s);
    }
    try {
      // android is slow when asking for all advertisments,
      // so instead we only ask for 1/8 of them
      await FlutterBluePlus.startScan(
        timeout: const Duration(minutes: 1),
        continuousUpdates: true,
      );
    } catch (e, s) {
      debugPrint("Start Scan Error $e");
      debugPrintStack(stackTrace: s);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e, s) {
      debugPrint("Stop Scan Error $e");
      debugPrintStack(stackTrace: s);
    }
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
          onPressed: onScanPressed, child: const Text("SCAN"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
        key: snackBarKeyB,
        child: Scaffold(
          floatingActionButton: buildScanButton(context),
          appBar: AppBar(
            title: const Text('Find Devices'),
          ),
          body: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                children: <Widget>[],
              )),
        ));
  }
}
