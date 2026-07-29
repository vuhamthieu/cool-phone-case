import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Service and Characteristic UUIDs matching ESP32 firmware
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let modeCharacteristicUUID     = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let timeCharacteristicUUID     = CBUUID(string: "e3223119-944c-477c-abf1-efac3e8b15d0")
    // 8-byte activity payload: uint32 steps + uint16 bpm + uint16 calories (little-endian)
    static let activityCharacteristicUUID = CBUUID(string: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")

    // Standard GATT Battery service and characteristic UUIDs
    static let batteryServiceUUID        = CBUUID(string: "180F")
    static let batteryCharacteristicUUID = CBUUID(string: "2A19")

    @Published var isBluetoothReady       = false
    @Published var isConnected            = false
    @Published var connectionStatusText   = "Disconnected"
    @Published var discoveredPeripherals  = [CBPeripheral]()
    @Published var activePeripheral: CBPeripheral?
    @Published var batteryLevel: Int      = 100

    private var centralManager: CBCentralManager!
    private var modeCharacteristic: CBCharacteristic?
    private var timeCharacteristic: CBCharacteristic?
    private var activityCharacteristic: CBCharacteristic?
    private var batteryCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Central Manager Control

    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionStatusText = "Scanning for OverByte..."
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        self.activePeripheral = peripheral
        peripheral.delegate = self
        connectionStatusText = "Connecting..."
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = activePeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    // MARK: - BLE API Commands

    func sendMode(_ mode: UInt8) {
        guard let peripheral = activePeripheral, let char = modeCharacteristic else {
            print("BLE Warning: Device not connected or mode characteristic missing")
            return
        }
        var value = mode
        let data = Data(bytes: &value, count: 1)
        peripheral.writeValue(data, for: char, type: .withResponse)
        print("Sent main mode change to ESP32: \(mode)")
    }

    func syncTime() {
        guard let peripheral = activePeripheral, let char = timeCharacteristic else {
            print("BLE Warning: Device not connected or time characteristic missing")
            return
        }
        var timestamp = UInt32(Date().timeIntervalSince1970)
        let data = Data(bytes: &timestamp, count: MemoryLayout<UInt32>.size)
        peripheral.writeValue(data, for: char, type: .withResponse)
        print("Sent Unix timestamp to ESP32: \(timestamp)")
    }

    /// Pack HealthKit metrics into an 8-byte little-endian frame and write to the ESP32.
    ///
    /// Payload layout (matches `ActivityCallback::onWrite` in ble.cpp):
    ///   Bytes 0-3: UInt32  stepCount       (little-endian)
    ///   Bytes 4-5: UInt16  heartRateBPM    (little-endian)
    ///   Bytes 6-7: UInt16  activeCalories  (little-endian)
    func sendActivityData(steps: UInt32, bpm: UInt16, calories: UInt16) {
        guard let peripheral = activePeripheral, let char = activityCharacteristic else {
            print("BLE Warning: Device not connected or activity characteristic missing")
            return
        }
        var payload = Data(count: 8)
        payload.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: steps.littleEndian,    toByteOffset: 0, as: UInt32.self)
            ptr.storeBytes(of: bpm.littleEndian,      toByteOffset: 4, as: UInt16.self)
            ptr.storeBytes(of: calories.littleEndian, toByteOffset: 6, as: UInt16.self)
        }
        peripheral.writeValue(payload, for: char, type: .withResponse)
        print("Sent activity data — Steps:\(steps) BPM:\(bpm) Cal:\(calories)")
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isBluetoothReady = true
            connectionStatusText = "Ready to connect"
            startScanning()
        } else {
            isBluetoothReady = false
            isConnected = false
            connectionStatusText = "Bluetooth disabled"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            // Auto-connect to OverByte if found
            if peripheral.name == "OverByte" {
                connect(to: peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatusText = "Connected to \(peripheral.name ?? "Device")"
        peripheral.discoverServices([Self.serviceUUID, Self.batteryServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectionStatusText = "Failed to connect"
        startScanning()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        modeCharacteristic     = nil
        timeCharacteristic     = nil
        activityCharacteristic = nil
        batteryCharacteristic  = nil
        activePeripheral       = nil
        connectionStatusText   = "Disconnected"
        startScanning()
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }

        if let services = peripheral.services {
            for service in services {
                if service.uuid == Self.serviceUUID {
                    peripheral.discoverCharacteristics(
                        [Self.modeCharacteristicUUID,
                         Self.timeCharacteristicUUID,
                         Self.activityCharacteristicUUID],
                        for: service
                    )
                } else if service.uuid == Self.batteryServiceUUID {
                    peripheral.discoverCharacteristics([Self.batteryCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == Self.modeCharacteristicUUID {
                    modeCharacteristic = characteristic
                    print("Found Mode Characteristic")
                } else if characteristic.uuid == Self.timeCharacteristicUUID {
                    timeCharacteristic = characteristic
                    print("Found Time Characteristic")
                    // Sync time automatically on connect
                    syncTime()
                } else if characteristic.uuid == Self.activityCharacteristicUUID {
                    activityCharacteristic = characteristic
                    print("Found Activity Characteristic")
                } else if characteristic.uuid == Self.batteryCharacteristicUUID {
                    batteryCharacteristic = characteristic
                    print("Found Battery Characteristic")
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic) // read initially
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("BLE Error updating value: \(error?.localizedDescription ?? "unknown")")
            return
        }

        if characteristic.uuid == Self.batteryCharacteristicUUID {
            if let data = characteristic.value, let rawBattery = data.first {
                let level = Int(rawBattery)
                DispatchQueue.main.async {
                    self.batteryLevel = level
                    print("BLE: Updated battery level: \(level)%")
                }
            }
        }
    }
}
