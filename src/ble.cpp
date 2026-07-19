// src/ble.cpp
#include "ble.h"
#include "config.h"
#include <NimBLEDevice.h>
#include <sys/time.h>

static bool isConnected = false;

class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) override {
        isConnected = true;
        Serial.println("iOS App Connected via BLE");
    }

    void onDisconnect(NimBLEServer* pServer) override {
        isConnected = false;
        Serial.println("iOS App Disconnected");
        // NimBLE automatically restarts advertising by default, but let's be explicit
        NimBLEDevice::getAdvertising()->start();
    }
};

class ModeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            uint8_t modeVal = rxValue[0];
            if (modeVal <= 2) {
                SystemMode newMode = (SystemMode)modeVal;
                if (currentMode != newMode) {
                    currentMode = newMode;
                    modeChangedFlag = true;
                    Serial.printf("Mode changed over BLE: %d\n", currentMode);
                }
            }
        }
    }
};

class TimeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        uint32_t timestamp = 0;
        
        if (rxValue.length() == 4) {
            // Binary 32-bit Unix timestamp format
            memcpy(&timestamp, rxValue.data(), 4);
        } else if (rxValue.length() > 0) {
            // Decimal ASCII string format (for debugging/serial)
            timestamp = strtoul(rxValue.c_str(), NULL, 10);
        }
        
        if (timestamp > 0) {
            struct timeval tv;
            tv.tv_sec = timestamp;
            tv.tv_usec = 0;
            settimeofday(&tv, NULL);
            timeSynced = true;
            Serial.printf("RTC Time synchronized: %u\n", timestamp);
        }
    }
};

void bleInit() {
    NimBLEDevice::init("Mochi_Case");
    
    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    
    NimBLEService *pService = pServer->createService(CONTROL_SERVICE_UUID);
    
    // Mode Change Characteristic: Write / Read
    NimBLECharacteristic *pModeChar = pService->createCharacteristic(
        CHARACTERISTIC_MODE_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::READ
    );
    pModeChar->setCallbacks(new ModeCallback());
    
    // Time Sync Characteristic: Write
    NimBLECharacteristic *pTimeChar = pService->createCharacteristic(
        CHARACTERISTIC_TIME_UUID,
        NIMBLE_PROPERTY::WRITE
    );
    pTimeChar->setCallbacks(new TimeCallback());
    
    pService->start();
    
    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(CONTROL_SERVICE_UUID);
    // Help iOS discover service quickly
    pAdvertising->setScanResponse(true);
    pAdvertising->start();
    
    Serial.println("BLE Initialized. Advertising: Mochi_Case");
}

bool bleIsConnected() {
    return isConnected;
}
