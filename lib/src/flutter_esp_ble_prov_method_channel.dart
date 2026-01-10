import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_esp_ble_prov_platform_interface.dart';

/// An implementation of [FlutterEspBleProvPlatform] that uses method channels.
class MethodChannelFlutterEspBleProv extends FlutterEspBleProvPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_esp_ble_prov');

  /// The event channel for WiFi scan results.
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_esp_ble_prov_wifi_scan');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<List<String>> scanBleDevices(String prefix) async {
    final args = {'prefix': prefix};
    final raw = await methodChannel.invokeMethod<List<Object?>>(
      'scanBleDevices',
      args,
    );
    final List<String> devices = [];
    if (raw != null) {
      devices.addAll(raw.cast<String>());
    }
    return devices;
  }

  @override
  Stream<Map<String, dynamic>> scanWifiNetworks(
    String deviceName,
    String proofOfPossession,
  ) {
    // First, invoke the method to start scanning
    methodChannel.invokeMethod('startScanWifiNetworks', {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
    });
    // Then return the stream from event channel
    return eventChannel.receiveBroadcastStream().map((event) {
      if (event is Map<Object?, Object?>) {
        return event.cast<String, dynamic>();
      }
      return {};
    });
  }

  @override
  Future<bool?> provisionWifi(
    String deviceName,
    String proofOfPossession,
    String ssid,
    String passphrase,
  ) async {
    final args = {
      'deviceName': deviceName,
      'proofOfPossession': proofOfPossession,
      'ssid': ssid,
      'passphrase': passphrase,
    };
    return await methodChannel.invokeMethod<bool?>('provisionWifi', args);
  }
}
