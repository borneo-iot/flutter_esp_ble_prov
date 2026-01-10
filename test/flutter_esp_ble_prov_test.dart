import 'package:flutter_esp_ble_prov/flutter_esp_ble_prov.dart';
import 'package:flutter_esp_ble_prov/src/flutter_esp_ble_prov_method_channel.dart';
import 'package:flutter_esp_ble_prov/src/flutter_esp_ble_prov_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterEspBleProvPlatform
    with MockPlatformInterfaceMixin
    implements FlutterEspBleProvPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Stream<String> scanBleDevices(String prefix) => Stream.fromIterable(['device1', 'device2']);

  @override
  Stream<Map<String, dynamic>> scanWifiNetworks(String deviceName, String proofOfPossession) =>
      Stream.fromIterable([{'ssid': 'wifi1', 'rssi': -50}]);

  @override
  Future<bool?> provisionWifi(String deviceName, String proofOfPossession, String ssid, String passphrase) =>
      Future.value(true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final FlutterEspBleProvPlatform initialPlatform =
      FlutterEspBleProvPlatform.instance;

  test('$MethodChannelFlutterEspBleProv is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterEspBleProv>());
  });

  test('getPlatformVersion', () async {
    FlutterEspBleProv flutterEspBleProvPlugin = FlutterEspBleProv();
    MockFlutterEspBleProvPlatform fakePlatform =
        MockFlutterEspBleProvPlatform();
    FlutterEspBleProvPlatform.instance = fakePlatform;

    expect(await flutterEspBleProvPlugin.getPlatformVersion(), '42');
  });

  test('scanBleDevices', () async {
    FlutterEspBleProv flutterEspBleProvPlugin = FlutterEspBleProv();
    MockFlutterEspBleProvPlatform fakePlatform =
        MockFlutterEspBleProvPlatform();
    FlutterEspBleProvPlatform.instance = fakePlatform;

    final stream = flutterEspBleProvPlugin.scanBleDevices('PROV_');
    final devices = await stream.toList();
    expect(devices, ['device1', 'device2']);
  });
}
