import Foundation
import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    // Service and Characteristic UUIDs matching ESP32 firmware
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let modeCharacteristicUUID       = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let timeCharacteristicUUID       = CBUUID(string: "e3223119-944c-477c-abf1-efac3e8b15d0")
    static let clockStyleCharacteristicUUID = CBUUID(string: "c5b6a7d8-e9f0-1234-abcd-ef1234567890")
    static let settingsCharacteristicUUID   = CBUUID(string: "d4b6a7d8-e9f0-1234-abcd-ef1234567891")
    static let mediaCharacteristicUUID      = CBUUID(string: "e5b6a7d8-e9f0-1234-abcd-ef1234567892")


    // Standard GATT Battery service and characteristic UUIDs
    static let batteryServiceUUID        = CBUUID(string: "180F")
    static let batteryCharacteristicUUID = CBUUID(string: "2A19")

    @Published var isBluetoothReady       = false
    @Published var isConnected            = false
    @Published var connectionStatusText   = "Disconnected"
    @Published var discoveredPeripherals  = [CBPeripheral]()
    @Published var activePeripheral: CBPeripheral?
    @Published var batteryLevel: Int      = 100

    @AppStorage("isNotificationEnabled") var isNotificationEnabled = true
    @AppStorage("isMediaControlEnabled") var isMediaControlEnabled = true

    private var centralManager: CBCentralManager!
    private var modeCharacteristic: CBCharacteristic?
    private var timeCharacteristic: CBCharacteristic?
    private var clockStyleCharacteristic: CBCharacteristic?
    private var settingsCharacteristic: CBCharacteristic?
    private var mediaCharacteristic: CBCharacteristic?
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
        
        let options: [String: Any] = [
            CBConnectPeripheralOptionRequiresANCS: true
        ]
        centralManager.connect(peripheral, options: options)
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
        guard let peripheral = activePeripheral else {
            print("BLE syncTime: no active peripheral — not connected")
            return
        }
        guard let char = timeCharacteristic else {
            print("BLE syncTime: timeCharacteristic is nil — service may not have been discovered yet")
            return
        }

        let utcNow = Date().timeIntervalSince1970
        let tzOffset = TimeZone.current.secondsFromGMT()
        let localTimestamp = UInt32(utcNow) + UInt32(tzOffset)

        print("BLE syncTime: UTC=\(UInt32(utcNow))  TZ offset=\(tzOffset)s  Sending local=\(localTimestamp)")

        var payload = Data(count: 4)
        payload.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: localTimestamp.littleEndian, toByteOffset: 0, as: UInt32.self)
        }
        peripheral.writeValue(payload, for: char, type: .withResponse)
        print("BLE syncTime: wrote 4 bytes: \(payload.map { String(format: "%02X", $0) }.joined(separator: " "))")
    }

    /// Send selected clock style to the ESP32.
    func sendClockStyle(style: Int) {
        guard let peripheral = activePeripheral, let char = clockStyleCharacteristic else {
            print("BLE Warning: Device not connected or clock style characteristic missing")
            return
        }
        var val = UInt8(style)
        let data = Data(bytes: &val, count: 1)
        peripheral.writeValue(data, for: char, type: .withResponse)
        print("BLE: Sent clock style \(style) to ESP32")
    }

    /// Send smart settings to ESP32 (bit 0 = Notifications, bit 1 = Media)
    func sendSettings() {
        guard let peripheral = activePeripheral, let char = settingsCharacteristic else {
            return
        }
        var flags: UInt8 = 0
        if isNotificationEnabled { flags |= 1 << 0 }
        if isMediaControlEnabled { flags |= 1 << 1 }
        
        let data = Data(bytes: &flags, count: 1)
        peripheral.writeValue(data, for: char, type: .withResponse)
        print("BLE: Sent settings flags \(flags) to ESP32")
    } 

    /// Send media information to the ESP32 (formatted as "Song|Artist")
    func sendMediaInfo(song: String, artist: String) {
        guard let peripheral = activePeripheral, let char = mediaCharacteristic else {
            print("BLE Warning: Device not connected or media characteristic missing")
            return
        }
        let message = "\(song)|\(artist)"
        if let data = message.data(using: .utf8) {
            peripheral.writeValue(data, for: char, type: .withResponse)
            print("BLE: Sent media info '\(message)' to ESP32")
        }
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
        modeCharacteristic       = nil
        timeCharacteristic       = nil
        clockStyleCharacteristic = nil
        settingsCharacteristic   = nil
        mediaCharacteristic      = nil
        batteryCharacteristic    = nil
        activePeripheral         = nil
        connectionStatusText     = "Disconnected"
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
                         Self.clockStyleCharacteristicUUID,
                         Self.settingsCharacteristicUUID,
                         Self.mediaCharacteristicUUID],
                        for: service
                    )

                } else if service.uuid == Self.batteryServiceUUID {
                    peripheral.discoverCharacteristics([Self.batteryCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("BLE Error discovering characteristics: \(error!.localizedDescription)")
            return
        }

        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == Self.modeCharacteristicUUID {
                    modeCharacteristic = characteristic
                    print("Found Mode Characteristic")
                    peripheral.readValue(for: characteristic)
                } else if characteristic.uuid == Self.timeCharacteristicUUID {
                    timeCharacteristic = characteristic
                    print("Found Time Characteristic")
                } else if characteristic.uuid == Self.clockStyleCharacteristicUUID {
                    clockStyleCharacteristic = characteristic
                    print("Found Clock Style Characteristic")
                } else if characteristic.uuid == Self.settingsCharacteristicUUID {
                    settingsCharacteristic = characteristic
                    print("Found Settings Characteristic")
                } else if characteristic.uuid == Self.mediaCharacteristicUUID {
                    mediaCharacteristic = characteristic
                    print("Found Media Characteristic")
                } else if characteristic.uuid == Self.batteryCharacteristicUUID {
                    batteryCharacteristic = characteristic
                    print("Found Battery Characteristic")
                    peripheral.setNotifyValue(true, for: characteristic)
                    peripheral.readValue(for: characteristic)
                }

            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BLE Read error for \(characteristic.uuid): \(error.localizedDescription)")
            if (error as NSError).code == CBATTError.insufficientAuthentication.rawValue ||
               (error as NSError).code == CBATTError.insufficientEncryption.rawValue {
                print("BLE: Pairing required — iOS should show pairing dialog now")
            }
            return
        }

        if characteristic.uuid == Self.modeCharacteristicUUID {
            print("BLE: Mode read succeeded — device is paired! Syncing time and settings now.")
            syncTime()
            sendSettings()
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

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BLE WRITE FAILED for \(characteristic.uuid): \(error.localizedDescription)")
        } else {
            print("BLE WRITE OK for \(characteristic.uuid)")
        }
    }
}
