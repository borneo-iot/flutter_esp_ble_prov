import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterEspBleProvPlugin = FlutterEspBleProv();

  final defaultPadding = 12.0;
  final defaultDevicePrefix = 'PROV';

  List<String> devices = [];
  List<Map<String, dynamic>> networks = [];

  String selectedDeviceName = '';
  String selectedSsid = '';
  String feedbackMessage = '';

  final prefixController = TextEditingController(text: 'PROV_');
  final proofOfPossessionController = TextEditingController(text: 'abcd1234');
  final passphraseController = TextEditingController();

  Future scanBleDevices() async {
    final prefix = prefixController.text;
    final stream = _flutterEspBleProvPlugin.scanBleDevices(prefix);
    setState(() {
      devices = [];
    });
    await for (final deviceName in stream) {
      setState(() {
        if (!devices.contains(deviceName)) {
          devices.add(deviceName);
        }
      });
    }
    pushFeedback('Success: scanned BLE devices');
  }

  Future scanWifiNetworks() async {
    final proofOfPossession = proofOfPossessionController.text;
    final stream = _flutterEspBleProvPlugin.scanWifiNetworks(
      selectedDeviceName,
      proofOfPossession,
    );
    setState(() {
      networks = [];
    });
    await for (final network in stream) {
      setState(() {
        networks.add(network);
      });
    }
    pushFeedback('Success: scanned WiFi on $selectedDeviceName');
  }

  Future provisionWifi() async {
    final proofOfPossession = proofOfPossessionController.text;
    final passphrase = passphraseController.text;
    await _flutterEspBleProvPlugin.provisionWifi(
      selectedDeviceName,
      proofOfPossession,
      selectedSsid,
      passphrase,
    );
    pushFeedback(
      'Success: provisioned WiFi $selectedDeviceName on $selectedSsid',
    );
  }

  pushFeedback(String msg) {
    setState(() {
      feedbackMessage = '$feedbackMessage\n$msg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ESP BLE Provisioning Example'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bluetooth_searching),
              onPressed: () async {
                await scanBleDevices();
              },
              tooltip: 'Scan BLE Devices',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Device Prefix Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Device Prefix',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: prefixController,
                          decoration: const InputDecoration(
                            hintText: 'Enter device prefix',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // BLE Devices Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BLE Devices',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: devices.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                title: Text(
                                  devices[i],
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () async {
                                  selectedDeviceName = devices[i];
                                  await scanWifiNetworks();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Proof of Possession Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proof of Possession',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: proofOfPossessionController,
                          decoration: const InputDecoration(
                            hintText: 'Enter proof of possession string',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // WiFi Networks Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WiFi Networks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: networks.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                title: Text(
                                  '${networks[i]['ssid']} (RSSI: ${networks[i]['rssi']})',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () async {
                                  selectedSsid = networks[i]['ssid'];
                                  await provisionWifi();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // WiFi Passphrase Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WiFi Passphrase',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passphraseController,
                          decoration: const InputDecoration(
                            hintText: 'Enter passphrase',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80), // Space for bottom sheet
              ],
            ),
          ),
        ),
        bottomSheet: SafeArea(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 150),
            color: Colors.black87,
            padding: EdgeInsets.all(defaultPadding),
            child: SingleChildScrollView(
              child: Text(
                feedbackMessage,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
