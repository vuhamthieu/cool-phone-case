// src/ble.cpp
#include "ble.h"
#include "config.h"
#include <NimBLEDevice.h>
#include <sys/time.h>

static bool isConnected = false;

// ─────────────────────────────────────────────────────────────────────────────
// Server connection callbacks
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// ANCS Task Declaration
// ─────────────────────────────────────────────────────────────────────────────
void ancsTask(void *pvParameters);
static NimBLEAddress connectedPeerAddress;
static bool shouldStartANCS = false;

// ─────────────────────────────────────────────────────────────────────────────
// Server connection callbacks
// ─────────────────────────────────────────────────────────────────────────────
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer, ble_gap_conn_desc* desc) override {
        isConnected = true;
        connectedPeerAddress = NimBLEAddress(desc->peer_ota_addr);
        Serial.printf("iOS App Connected via BLE: %s\n", connectedPeerAddress.toString().c_str());
        
        // If already bonded, start ANCS client
        if (pServer->getPeerInfo(desc->conn_handle).isBonded()) {
            Serial.println("Device is already bonded, queuing ANCS start.");
            shouldStartANCS = true;
        }
    }

    void onDisconnect(NimBLEServer* pServer, ble_gap_conn_desc* desc) override {
        isConnected = false;
        shouldStartANCS = false;
        Serial.println("iOS App Disconnected");
        NimBLEDevice::getAdvertising()->start();
    }

    void onAuthenticationComplete(ble_gap_conn_desc* desc) override {
        if (!isConnected) return;
        if (desc->sec_state.encrypted) {
            Serial.println("BLE Authentication Complete & Encrypted! Queuing ANCS start.");
            shouldStartANCS = true;
        } else {
            Serial.println("BLE Authentication Failed!");
        }
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

        Serial.printf("TimeCallback: received %d byte(s)\n", (int)rxValue.length());
        for (size_t i = 0; i < rxValue.length(); i++) {
            Serial.printf("  [%d] = 0x%02X\n", (int)i, (uint8_t)rxValue[i]);
        }

        uint32_t timestamp = 0;
        if (rxValue.length() == 4) {
            memcpy(&timestamp, rxValue.data(), 4);
        } else if (rxValue.length() > 0) {
            timestamp = strtoul(rxValue.c_str(), NULL, 10);
        }

        if (timestamp > 0) {
            struct timeval tv;
            tv.tv_sec  = (time_t)timestamp;   
            tv.tv_usec = 0;
            settimeofday(&tv, NULL);
            timeSynced = true;
            Serial.printf("RTC synced. Local time set to Unix: %u\n", timestamp);
        } else {
            Serial.println("TimeCallback: invalid timestamp, RTC not updated");
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Clock style characteristic: 1-byte style index [0=BIG_DIGITAL | 1=DIGITAL_DATE | 2=ANALOG]
// ─────────────────────────────────────────────────────────────────────────────
class ClockStyleCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            uint8_t styleVal = rxValue[0];
            if (styleVal < CLOCK_STYLE_MAX) {
                currentClockStyle = (ClockStyle)styleVal;
                Serial.printf("Clock Style changed over BLE: %d\n", currentClockStyle);
            }
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Settings characteristic: bit 0 = Notifications, bit 1 = Media
// ─────────────────────────────────────────────────────────────────────────────
class SettingsCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            uint8_t flags = rxValue[0];
            notificationsEnabled = (flags & 0x01) != 0;
            mediaControlEnabled = (flags & 0x02) != 0;
            Serial.printf("Settings updated: Notifications=%d, Media=%d\n", notificationsEnabled, mediaControlEnabled);
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// BLE initialisation
// ─────────────────────────────────────────────────────────────────────────────
static NimBLECharacteristic* pBatteryLevelChar = nullptr;

void bleInit() {
    NimBLEDevice::init("OverByte");

    // Enable Security for ANCS (Bonding)
    NimBLEDevice::setSecurityAuth(true, true, true);
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_NO_INPUT_OUTPUT);
    NimBLEDevice::setSecurityInitKey(BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID);
    NimBLEDevice::setSecurityRespKey(BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID);

    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService *pService = pServer->createService(CONTROL_SERVICE_UUID);

    // Mode characteristic
    NimBLECharacteristic *pModeChar = pService->createCharacteristic(
        CHARACTERISTIC_MODE_UUID,
        NIMBLE_PROPERTY::WRITE_ENC | NIMBLE_PROPERTY::READ_ENC
    );
    pModeChar->setCallbacks(new ModeCallback());

    // Time-sync characteristic
    NimBLECharacteristic *pTimeChar = pService->createCharacteristic(
        CHARACTERISTIC_TIME_UUID,
        NIMBLE_PROPERTY::WRITE_ENC
    );
    pTimeChar->setCallbacks(new TimeCallback());

    // Clock style characteristic
    NimBLECharacteristic *pClockStyleChar = pService->createCharacteristic(
        CHARACTERISTIC_CLOCK_STYLE_UUID,
        NIMBLE_PROPERTY::WRITE_ENC
    );
    pClockStyleChar->setCallbacks(new ClockStyleCallback());

    // Settings characteristic
    NimBLECharacteristic *pSettingsChar = pService->createCharacteristic(
        CHARACTERISTIC_SETTINGS_UUID,
        NIMBLE_PROPERTY::WRITE_ENC
    );
    pSettingsChar->setCallbacks(new SettingsCallback());

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

    Serial.println("BLE Initialized. Advertising: OverByte (Control + Battery)");

    // Spawn ANCS Background Task
    xTaskCreatePinnedToCore(
        ancsTask,
        "ANCS_Task",
        4096,
        NULL,
        1,
        NULL,
        0
    );
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

// ─────────────────────────────────────────────────────────────────────────────
// ANCS Client Task and Callbacks
// ─────────────────────────────────────────────────────────────────────────────
static NimBLEClient* pANCSClient = nullptr;
static NimBLERemoteCharacteristic* pControlPoint = nullptr;
static NimBLERemoteCharacteristic* pDataSource = nullptr;

static volatile uint32_t pendingNotifUID = 0;

static void notifyCB(NimBLERemoteCharacteristic* pRemoteCharacteristic, uint8_t* pData, size_t length, bool isNotify) {
    if (!notificationsEnabled) return;

    if (pRemoteCharacteristic->getUUID().equals(NimBLEUUID(ANCS_NOTIF_SRC_UUID))) {
        if (length >= 8) {
            uint8_t eventID = pData[0];
            uint32_t notifUID = pData[4] | (pData[5] << 8) | (pData[6] << 16) | (pData[7] << 24);

            // 0 = Added, 1 = Modified, 2 = Removed
            if (eventID == 0 || eventID == 1) { 
                Serial.printf("ANCS: New Notification UID: %u\n", notifUID);
                pendingNotifUID = notifUID;
            }
        }
    } else if (pRemoteCharacteristic->getUUID().equals(NimBLEUUID(ANCS_DATA_SRC_UUID))) {
        if (length > 5 && pData[0] == 0) { // CommandIDGetNotificationAttributes
            size_t idx = 5;
            memset((void*)notificationApp, 0, sizeof(notificationApp));
            memset((void*)notificationSender, 0, sizeof(notificationSender));
            bool hasData = false;

            while (idx < length) {
                uint8_t attrID = pData[idx++];
                if (idx + 1 >= length) break;
                uint16_t attrLen = pData[idx] | (pData[idx+1] << 8);
                idx += 2;
                if (idx + attrLen > length) break;

                if (attrID == 0) { // AppIdentifier
                    char bundleID[128] = {0};
                    size_t cpyLen = (attrLen < sizeof(bundleID) - 1) ? attrLen : sizeof(bundleID) - 1;
                    memcpy(bundleID, &pData[idx], cpyLen);
                    
                    // User Request: Use strrchr to slice the bundle ID
                    char* lastDot = strrchr(bundleID, '.');
                    if (lastDot != nullptr) {
                        if (*(lastDot + 1) != '\0') {
                            strncpy((char*)notificationApp, lastDot + 1, sizeof(notificationApp) - 1);
                        } else {
                            // Dot is at the very end? Fallback to full
                            strncpy((char*)notificationApp, bundleID, sizeof(notificationApp) - 1);
                        }
                    } else {
                        // No dot found, fallback to full string
                        strncpy((char*)notificationApp, bundleID, sizeof(notificationApp) - 1);
                    }
                    hasData = true;
                } else if (attrID == 1) { // Title
                    size_t cpyLen = (attrLen < sizeof(notificationSender) - 1) ? attrLen : sizeof(notificationSender) - 1;
                    memcpy((void*)notificationSender, &pData[idx], cpyLen);
                    hasData = true;
                }
                idx += attrLen;
            }

            if (hasData) {
                if (strlen(notificationSender) == 0) {
                    strncpy((char*)notificationSender, "Notification", sizeof(notificationSender)-1);
                }
                Serial.printf("ANCS Parsed -> App: %s, Sender: %s\n", notificationApp, notificationSender);
                hasNewNotification = true;
            }
        }
    }
}

void ancsTask(void *pvParameters) {
    while (true) {
        if (shouldStartANCS && isConnected) {
            shouldStartANCS = false;
            if (pANCSClient == nullptr) {
                pANCSClient = NimBLEDevice::createClient();
            }

            if (!pANCSClient->isConnected()) {
                if (pANCSClient->connect(connectedPeerAddress)) {
                    Serial.println("ANCS Client Connected to peer.");
                    
                    NimBLERemoteService* pANCSService = pANCSClient->getService(NimBLEUUID(ANCS_SERVICE_UUID));
                    if (pANCSService != nullptr) {
                        pControlPoint = pANCSService->getCharacteristic(NimBLEUUID(ANCS_CTRL_PT_UUID));
                        pDataSource = pANCSService->getCharacteristic(NimBLEUUID(ANCS_DATA_SRC_UUID));
                        NimBLERemoteCharacteristic* pNotifSource = pANCSService->getCharacteristic(NimBLEUUID(ANCS_NOTIF_SRC_UUID));

                        if (pDataSource && pDataSource->canNotify()) {
                            pDataSource->subscribe(true, notifyCB);
                            Serial.println("ANCS Data Source Subscribed");
                        }
                        if (pNotifSource && pNotifSource->canNotify()) {
                            pNotifSource->subscribe(true, notifyCB);
                            Serial.println("ANCS Notification Source Subscribed");
                        }
                    } else {
                        Serial.println("ANCS Service not found on peer.");
                    }
                } else {
                    Serial.println("ANCS Client failed to connect.");
                }
            }
        }

        // Process pending notification requests outside the BLE callback
        if (pendingNotifUID != 0 && pControlPoint != nullptr && pANCSClient != nullptr && pANCSClient->isConnected()) {
            uint32_t uid = pendingNotifUID;
            pendingNotifUID = 0; // Clear it

            uint8_t cmd[8];
            cmd[0] = 0; // CommandIDGetNotificationAttributes
            cmd[1] = uid & 0xFF; 
            cmd[2] = (uid >> 8) & 0xFF; 
            cmd[3] = (uid >> 16) & 0xFF; 
            cmd[4] = (uid >> 24) & 0xFF; // UID
            cmd[5] = 0; // AppIdentifier
            cmd[6] = 1; // Title
            cmd[7] = 32; // Max Title Len
            
            pControlPoint->writeValue(cmd, 8, true);
        }

        vTaskDelay(pdMS_TO_TICKS(100)); // check every 100ms
    }
}
