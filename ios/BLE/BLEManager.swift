import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Service and Characteristic UUIDs matching ESP32 firmware
    static let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    static let modeCharacteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let timeCharacteristicUUID = CBUUID(string: "e3223119-944c-477c-abf1-efac3e8b15d0")
    
    @Published var isBluetoothReady = false
    @Published var isConnected = false
    @Published var connectionStatusText = "Disconnected"
    @Published var discoveredPeripherals = [CBPeripheral]()
    @Published var activePeripheral: CBPeripheral?
    
    private var centralManager: CBCentralManager!
    private var modeCharacteristic: CBCharacteristic?
    private var timeCharacteristic: CBCharacteristic?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Central Manager Control
    
    func startScanning() {
        guard centralManager.state == .poweredOn else { return }
        connectionStatusText = "Scanning for Mochi Case..."
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            // Auto connect to Mochi_Case if found
            if peripheral.name == "Mochi_Case" {
                connect(to: peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatusText = "Connected to \(peripheral.name ?? "Device")"
        peripheral.discoverServices([Self.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectionStatusText = "Failed to connect"
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        modeCharacteristic = nil
        timeCharacteristic = nil
        activePeripheral = nil
        connectionStatusText = "Disconnected"
        startScanning()
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        
        if let services = peripheral.services {
            for service in services {
                if service.uuid == Self.serviceUUID {
                    peripheral.discoverCharacteristics([Self.modeCharacteristicUUID, Self.timeCharacteristicUUID], for: service)
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
                }
            }
        }
    }
}
