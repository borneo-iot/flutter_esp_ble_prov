import Flutter
import UIKit
import ESPProvision

public class SwiftFlutterEspBleProvPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let START_SCAN_BLE_DEVICES = "startScanBleDevices"
    private let START_SCAN_WIFI_NETWORKS = "startScanWifiNetworks"
    private let SCAN_WIFI_NETWORKS = "scanWifiNetworks"
    private let PROVISION_WIFI = "provisionWifi"
    
    private var eventSink: FlutterEventSink?
    private var bleEventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_esp_ble_prov", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "flutter_esp_ble_prov_wifi_scan", binaryMessenger: registrar.messenger())
        let bleEventChannel = FlutterEventChannel(name: "flutter_esp_ble_prov_ble_scan", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterEspBleProvPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
        bleEventChannel.setStreamHandler(instance)
    }
    

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let provisionService = BLEProvisionService(result: result, eventSink: eventSink, bleEventSink: bleEventSink);
        let arguments = call.arguments as! [String: Any]
        
        if(call.method == START_SCAN_BLE_DEVICES) {
            let prefix = arguments["prefix"] as! String
            provisionService.startScanBleDevices(prefix: prefix)
        } else if(call.method == START_SCAN_WIFI_NETWORKS) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            provisionService.startScanWifiNetworks(deviceName: deviceName, proofOfPossession: proofOfPossession)
        } else if (call.method == PROVISION_WIFI) {
            let deviceName = arguments["deviceName"] as! String
            let proofOfPossession = arguments["proofOfPossession"] as! String
            let ssid = arguments["ssid"] as! String
            let passphrase = arguments["passphrase"] as! String
            provisionService.provision(
                deviceName: deviceName,
                proofOfPossession: proofOfPossession,
                ssid: ssid,
                passphrase: passphrase
            )
        } else {
            result("iOS " + UIDevice.current.systemVersion)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let args = arguments as? [String: Any], let channel = args["channel"] as? String {
            if channel == "wifi" {
                eventSink = events
            } else if channel == "ble" {
                bleEventSink = events
            }
        } else {
            // Default to wifi for backward compatibility
            eventSink = events
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
}

protocol ProvisionService {
    var result: FlutterResult { get }
    func searchDevices(prefix: String) -> Void
    func startScanWifiNetworks(deviceName: String, proofOfPossession: String) -> Void
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) -> Void
}

private class BLEProvisionService: ProvisionService {
    fileprivate var result: FlutterResult
    fileprivate var eventSink: FlutterEventSink?
    fileprivate var bleEventSink: FlutterEventSink?
    
    init(result: @escaping FlutterResult, eventSink: FlutterEventSink?, bleEventSink: FlutterEventSink?) {
        self.result = result
        self.eventSink = eventSink
        self.bleEventSink = bleEventSink
    }
    
    func startScanBleDevices(prefix: String) {
        ESPProvisionManager.shared.searchESPDevices(devicePrefix: prefix, transport:.ble, security:.secure) { deviceList, error in
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
            }
            var seenDevices = Set<String>()
            deviceList?.forEach { device in
                if !seenDevices.contains(device.name) {
                    seenDevices.insert(device.name)
                    self.bleEventSink?(device.name)
                }
            }
        }
    }
    
    func startScanWifiNetworks(deviceName: String, proofOfPossession: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession) {
            device in
            device?.scanWifiList { wifiList, error in
                if(error != nil) {
                    NSLog("Error scanning wifi networks, deviceName: \(deviceName) ")
                    // Handle error via eventSink if needed
                }
                wifiList?.forEach { network in
                    let networkDict = ["ssid": network.ssid, "rssi": String(network.rssi)]
                    self.eventSink?(networkDict)
                }
                device?.disconnect()
            }
        }
    }
    
    func provision(deviceName: String, proofOfPossession: String, ssid: String, passphrase: String) {
        self.connect(deviceName: deviceName, proofOfPossession: proofOfPossession){
            device in
            device?.provision(ssid: ssid, passPhrase: passphrase) { status in
                switch status {
                case .success:
                    NSLog("Success provisioning device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(true)
                case .configApplied:
                    NSLog("Wifi config applied device. ssid: \(ssid), deviceName: \(deviceName) ")
                case .failure:
                    NSLog("Failed to provision device. ssid: \(ssid), deviceName: \(deviceName) ")
                    self.result(false)
                }
            }
        }
    }
    
    private func connect(deviceName: String, proofOfPossession: String, completionHandler: @escaping (ESPDevice?) -> Void) {
        ESPProvisionManager.shared.createESPDevice(deviceName: deviceName, transport: .ble, security: .secure, proofOfPossession: proofOfPossession) { espDevice, error in
            
            if(error != nil) {
                ESPErrorHandler.handle(error: error!, result: self.result)
            }
            espDevice?.connect { status in
                switch status {
                case .connected:
                    completionHandler(espDevice!)
                case let .failedToConnect(error):
                    ESPErrorHandler.handle(error: error, result: self.result)
                default:
                    self.result(FlutterError(code: "DEVICE_DISCONNECTED", message: nil, details: nil))
                }
            }
        }
    }
    
}

private class ESPErrorHandler {
    static func handle(error: ESPError, result: FlutterResult) {
        result(FlutterError(code: String(error.code), message: error.description, details: nil))
    }
}
