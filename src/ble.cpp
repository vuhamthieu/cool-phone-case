// src/ble.cpp
#include "ble.h"
#include "config.h"
#include <NimBLEDevice.h>
#include <sys/time.h>

static bool isConnected = false;

// ─────────────────────────────────────────────────────────────────────────────
// Server connection callbacks
// ─────────────────────────────────────────────────────────────────────────────
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) override {
        isConnected = true;
        Serial.println("iOS App Connected via BLE");
    }

    void onDisconnect(NimBLEServer* pServer) override {
        isConnected = false;
        Serial.println("iOS App Disconnected");
        NimBLEDevice::getAdvertising()->start();
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Mode characteristic: 1-byte mode index  [0=CLOCK | 1=MOCHI | 2=ACTIVITY]
// ─────────────────────────────────────────────────────────────────────────────
class ModeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            uint8_t modeVal = rxValue[0];
            if (modeVal <= 2) {   // 0-2 valid now
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

// ─────────────────────────────────────────────────────────────────────────────
// Time characteristic: 4-byte little-endian Unix timestamp
// ─────────────────────────────────────────────────────────────────────────────
class TimeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        uint32_t timestamp = 0;

        if (rxValue.length() == 4) {
            memcpy(&timestamp, rxValue.data(), 4);
        } else if (rxValue.length() > 0) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Activity characteristic:
//   8-byte little-endian payload written by the iOS app after HealthKit fetch:
//     Bytes 0-3: uint32_t  stepCount
//     Bytes 4-5: uint16_t  heartRateBPM
//     Bytes 6-7: uint16_t  activeCaloriesKcal
// ─────────────────────────────────────────────────────────────────────────────
class ActivityCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();

        if (rxValue.length() >= 8) {
            uint32_t steps    = 0;
            uint16_t bpm      = 0;
            uint16_t calories = 0;

            memcpy(&steps,    rxValue.data() + 0, 4);
            memcpy(&bpm,      rxValue.data() + 4, 2);
            memcpy(&calories, rxValue.data() + 6, 2);

            // Write atomically (these are word-aligned volatiles on Xtensa/RISC-V)
            activitySteps    = steps;
            activityBPM      = bpm;
            activityCalories = calories;

            Serial.printf("Activity update — Steps:%lu  BPM:%u  Cal:%u\n",
                          (unsigned long)steps, bpm, calories);
        } else {
            Serial.printf("Activity payload too short (%d bytes), ignored\n",
                          (int)rxValue.length());
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// BLE initialisation
// ─────────────────────────────────────────────────────────────────────────────
static NimBLECharacteristic* pBatteryLevelChar = nullptr;

void bleInit() {
    NimBLEDevice::init("OverByte");

    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService *pService = pServer->createService(CONTROL_SERVICE_UUID);

    // Mode characteristic
    NimBLECharacteristic *pModeChar = pService->createCharacteristic(
        CHARACTERISTIC_MODE_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::READ
    );
    pModeChar->setCallbacks(new ModeCallback());

    // Time-sync characteristic
    NimBLECharacteristic *pTimeChar = pService->createCharacteristic(
        CHARACTERISTIC_TIME_UUID,
        NIMBLE_PROPERTY::WRITE
    );
    pTimeChar->setCallbacks(new TimeCallback());

    // Activity data characteristic (write-only from iOS)
    NimBLECharacteristic *pActivityChar = pService->createCharacteristic(
        CHARACTERISTIC_ACTIVITY_UUID,
        NIMBLE_PROPERTY::WRITE
    );
    pActivityChar->setCallbacks(new ActivityCallback());

    pService->start();

    // Standard GATT Battery Service (0x180F) & Battery Level Characteristic (0x2A19)
    NimBLEService *pBatteryService = pServer->createService(NimBLEUUID((uint16_t)0x180F));
    pBatteryLevelChar = pBatteryService->createCharacteristic(
        NimBLEUUID((uint16_t)0x2A19),
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );
    uint8_t initialBat = 100;
    pBatteryLevelChar->setValue(&initialBat, 1);
    pBatteryService->start();

    NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(CONTROL_SERVICE_UUID);
    pAdvertising->addServiceUUID(NimBLEUUID((uint16_t)0x180F));
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.println("BLE Initialized. Advertising: OverByte (Control + Activity + Battery)");
}

bool bleIsConnected() {
    return isConnected;
}

void bleUpdateBattery(uint8_t percent) {
    if (pBatteryLevelChar != nullptr) {
        pBatteryLevelChar->setValue(&percent, 1);
        if (bleIsConnected()) {
            pBatteryLevelChar->notify();
            Serial.printf("BLE: Notified battery percentage: %d%%\n", percent);
        }
    }
}
