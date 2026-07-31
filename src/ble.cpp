// src/ble.cpp
#include "ble.h"
#include "config.h"
#include "display.h"
#include <NimBLEDevice.h>
#include "nimble/nimble/host/include/host/ble_hs.h"
#include <sys/time.h>

// AMS UUIDs
#define AMS_SERVICE_UUID          "89D3502B-0F36-433A-8EF4-C502AD55F8DC"
#define AMS_ENTITY_UPDATE_UUID    "2F7CABCE-808D-411F-9A0C-BB92BA96C102"

static volatile bool isConnected = false;


// ─────────────────────────────────────────────────────────────────────────────
// Server connection callbacks
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// ANCS Task Declaration
// ─────────────────────────────────────────────────────────────────────────────
void ancsTask(void *pvParameters);
static NimBLEAddress connectedPeerAddress;
static volatile uint16_t activeConnHandle = 0xFFFF;
static volatile bool shouldStartANCS = false;

struct NimBLEClientHack {
    void* vtable;               
    NimBLEAddress m_peerAddress;
    uint16_t m_conn_id;    
    int m_lastErr;
    bool m_connEstablished;
};

// ─────────────────────────────────────────────────────────────────────────────
// Server connection callbacks
// ─────────────────────────────────────────────────────────────────────────────
class ServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer, ble_gap_conn_desc* desc) override {
        isConnected = true;
        activeConnHandle = desc->conn_handle;
        connectedPeerAddress = NimBLEAddress(desc->peer_ota_addr);
        Serial.printf("iOS App Connected via BLE: %s (conn_handle=%d)\n", connectedPeerAddress.toString().c_str(), activeConnHandle);
        
        if (NimBLEDevice::isBonded(connectedPeerAddress)) {
            Serial.println("Device is already bonded in NVS database. Waiting for iOS to auto-encrypt...");
        } else {
            Serial.println("Not bonded — forcing pairing now.");
            NimBLEDevice::startSecurity(desc->conn_handle);
        }
    }

    void onDisconnect(NimBLEServer* pServer, ble_gap_conn_desc* desc) override {
        isConnected = false;
        shouldStartANCS = false;
        activeConnHandle = 0xFFFF;
        Serial.println("iOS App Disconnected");
        NimBLEDevice::getAdvertising()->start();
    }

    void onAuthenticationComplete(ble_gap_conn_desc* desc) override {
        if (!isConnected) return;
        activeConnHandle = desc->conn_handle;
        if (desc->sec_state.encrypted) {
            Serial.println("BLE Authentication Complete & Encrypted! Queuing ANCS start.");
            shouldStartANCS = true;
        } else {
            Serial.println("BLE Authentication Failed!");
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Instant Redraw Helper
// ─────────────────────────────────────────────────────────────────────────────
static void triggerDisplayRefresh() {
    modeChangedFlag = true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode characteristic: 1-byte mode index  [0=CLOCK | 1..5=MOCHI emotes]
// ─────────────────────────────────────────────────────────────────────────────
class ModeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string value = pCharacteristic->getValue();
        Serial.printf("[MODE] onWrite fired! len=%d\n", (int)value.length());
        if (value.length() > 0) {
            uint8_t modeVal = (uint8_t)value[0];
            Serial.printf("[MODE] Successfully parsed byte: %d\n", modeVal);
            if (modeVal == 0) {
                currentMode = MODE_CLOCK;
                modeChangedFlag = true;
                triggerDisplayRefresh();
            } else if (modeVal >= 1 && modeVal <= 5) {
                currentMode = MODE_MOCHI;
                appSelectedMochiEmotion = (MochiEmotion)(modeVal - 1);
                currentMochiEmotion = appSelectedMochiEmotion;
                modeChangedFlag = true;
                triggerDisplayRefresh();
            } else {
                Serial.printf("[MODE] Invalid mode value received: %d\n", modeVal);
            }
        }
    }
    void onWrite(NimBLECharacteristic *pCharacteristic, ble_gap_conn_desc* desc) override {
        onWrite(pCharacteristic);
    }
    void onRead(NimBLECharacteristic *pCharacteristic) override {
        Serial.println("[MODE] onRead fired");
    }
};

class TimeCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string rxValue = pCharacteristic->getValue();
        Serial.printf("[TIME] onWrite fired! len=%d\n", (int)rxValue.length());
        for (size_t i = 0; i < rxValue.length(); i++) {
            Serial.printf("[TIME]   byte[%d] = 0x%02X\n", (int)i, (uint8_t)rxValue[i]);
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
            Serial.printf("[TIME] RTC synced to Unix: %u\n", timestamp);
            triggerDisplayRefresh();
        } else {
            Serial.println("[TIME] Invalid timestamp");
        }
    }
    void onWrite(NimBLECharacteristic *pCharacteristic, ble_gap_conn_desc* desc) override {
        onWrite(pCharacteristic);
    }
};

class ClockStyleCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string value = pCharacteristic->getValue();
        Serial.printf("[CLOCK_STYLE] onWrite fired! len=%d\n", (int)value.length());
        if (value.length() > 0) {
            uint8_t styleVal = (uint8_t)value[0];
            Serial.printf("[CLOCK_STYLE] Successfully parsed byte: %d\n", styleVal);
            if (styleVal < CLOCK_STYLE_MAX) {
                currentClockStyle = (ClockStyle)styleVal;
                triggerDisplayRefresh();
            } else {
                Serial.printf("[CLOCK_STYLE] Invalid style value received: %d\n", styleVal);
            }
        }
    }
    void onWrite(NimBLECharacteristic *pCharacteristic, ble_gap_conn_desc* desc) override {
        onWrite(pCharacteristic);
    }
};

class SettingsCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string value = pCharacteristic->getValue();
        Serial.printf("[SETTINGS] onWrite fired! len=%d\n", (int)value.length());
        if (value.length() > 0) {
            uint8_t flags = (uint8_t)value[0];
            notificationsEnabled = (flags & 0x01) != 0;
            mediaControlEnabled = (flags & 0x02) != 0;
            Serial.printf("[SETTINGS] Successfully parsed byte: %d (Notifications=%d, Media=%d)\n", flags, notificationsEnabled, mediaControlEnabled);
        }
    }
    void onWrite(NimBLECharacteristic *pCharacteristic, ble_gap_conn_desc* desc) override {
        onWrite(pCharacteristic);
    }
};

class MediaCallback: public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *pCharacteristic) override {
        std::string value = pCharacteristic->getValue();
        Serial.printf("[MEDIA] onWrite fired! len=%d\n", (int)value.length());
        if (value.length() > 0) {
            size_t delimiterPos = value.find('|');
            if (delimiterPos != std::string::npos) {
                std::string songPart = value.substr(0, delimiterPos);
                std::string artistPart = value.substr(delimiterPos + 1);
                
                strncpy((char*)currentSong, songPart.c_str(), sizeof(currentSong) - 1);
                currentSong[sizeof(currentSong) - 1] = '\0';
                
                strncpy((char*)currentArtist, artistPart.c_str(), sizeof(currentArtist) - 1);
                currentArtist[sizeof(currentArtist) - 1] = '\0';
                
                Serial.printf("[MEDIA] Parsed Song: '%s', Artist: '%s'\n", currentSong, currentArtist);
            } else {
                strncpy((char*)currentSong, value.c_str(), sizeof(currentSong) - 1);
                currentSong[sizeof(currentSong) - 1] = '\0';
                strncpy((char*)currentArtist, "Unknown", sizeof(currentArtist) - 1);
                currentArtist[sizeof(currentArtist) - 1] = '\0';
                Serial.printf("[MEDIA] No delimiter. Parsed Song: '%s'\n", currentSong);
            }
            hasMediaUpdate = true;
            triggerDisplayRefresh();
        }
    }
    void onWrite(NimBLECharacteristic *pCharacteristic, ble_gap_conn_desc* desc) override {
        onWrite(pCharacteristic);
    }
};


class MySecurityCallbacks : public NimBLESecurityCallbacks {
    uint32_t onPassKeyRequest() override {
        Serial.println("[SECURITY] onPassKeyRequest (returning 123456)");
        return 123456;
    }
    void onPassKeyNotify(uint32_t pass_key) override {
        Serial.printf("[SECURITY] onPassKeyNotify: PIN is %06u\n", pass_key);
        if (displayMutex != NULL && xSemaphoreTake(displayMutex, pdMS_TO_TICKS(150)) == pdTRUE) {
            displayClear();
            char buf[32];
            snprintf(buf, sizeof(buf), "PIN: %06u", pass_key);
            drawTextCentered(25, "PAIRING REQUEST");
            drawTextCentered(40, buf);
            displayUpdate();
            xSemaphoreGive(displayMutex);
        }
    }
    bool onSecurityRequest() override {
        Serial.println("[SECURITY] onSecurityRequest (accepting)");
        return true;
    }
    void onAuthenticationComplete(ble_gap_conn_desc* desc) override {
        Serial.printf("[SECURITY] onAuthenticationComplete: status=%d, encrypted=%d, bonded=%d\n",
                      desc->sec_state.encrypted ? 0 : 1,
                      desc->sec_state.encrypted,
                      desc->sec_state.bonded);
        if (desc->sec_state.encrypted) {
            shouldStartANCS = true;
        }
    }
    bool onConfirmPIN(uint32_t pin) override {
        Serial.printf("[SECURITY] onConfirmPIN: %06u\n", pin);
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// BLE initialisation
// ─────────────────────────────────────────────────────────────────────────────
static NimBLECharacteristic* pBatteryLevelChar = nullptr;

void bleInit() {
    NimBLEDevice::init("OverByte");

    NimBLEDevice::setSecurityAuth(true, true, true);
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_DISPLAY_ONLY); // Display PIN on OLED for secure pairing
    NimBLEDevice::setSecurityPasskey(123456); 
    NimBLEDevice::setSecurityInitKey(BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID);
    NimBLEDevice::setSecurityRespKey(BLE_SM_PAIR_KEY_DIST_ENC | BLE_SM_PAIR_KEY_DIST_ID);
    NimBLEDevice::setSecurityCallbacks(new MySecurityCallbacks());

    NimBLEServer *pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());

    NimBLEService *pService = pServer->createService(CONTROL_SERVICE_UUID);

    // Mode characteristic
    NimBLECharacteristic *pModeChar = pService->createCharacteristic(
        CHARACTERISTIC_MODE_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    pModeChar->setCallbacks(new ModeCallback());

    // Time-sync characteristic
    NimBLECharacteristic *pTimeChar = pService->createCharacteristic(
        CHARACTERISTIC_TIME_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    pTimeChar->setCallbacks(new TimeCallback());

    // Clock style characteristic
    NimBLECharacteristic *pClockStyleChar = pService->createCharacteristic(
        CHARACTERISTIC_CLOCK_STYLE_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    pClockStyleChar->setCallbacks(new ClockStyleCallback());

    // Settings characteristic
    NimBLECharacteristic *pSettingsChar = pService->createCharacteristic(
        CHARACTERISTIC_SETTINGS_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    pSettingsChar->setCallbacks(new SettingsCallback());

    // Media characteristic
    NimBLECharacteristic *pMediaChar = pService->createCharacteristic(
        CHARACTERISTIC_MEDIA_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::READ_AUTHEN | NIMBLE_PROPERTY::WRITE_AUTHEN
    );
    pMediaChar->setCallbacks(new MediaCallback());

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
    pAdvertising->setAppearance(0x00C0); // Generic Watch / Companion Display (0x00C0 = 192)

    // Apple ANCS Specification: AD Type 0x15 (128-bit Service Solicitation)
    // Payload: Length=17 (0x11), Type=0x15, ANCS UUID (16 bytes LSB)
    const char solData[] = {
        0x11, // Length (17 bytes: 1 byte type + 16 bytes UUID)
        0x15, // AD Type 0x15: 128-bit Service Solicitation
        (char)0xd0, (char)0x00, (char)0x2d, (char)0x12, 
        (char)0x1e, (char)0x4b, (char)0x0f, (char)0xa4, 
        (char)0x99, (char)0x4e, (char)0xce, (char)0xb5, 
        (char)0x31, (char)0xf4, (char)0x05, (char)0x79
    };

    NimBLEAdvertisementData advData;
    advData.setFlags(0x06); // General Discoverable + BR/EDR Not Supported (Mandatory for iOS)
    advData.setName("OverByte");
    advData.addData((char*)solData, sizeof(solData));
    pAdvertising->setAdvertisementData(advData);

    // Scan Response Data (Control Service UUID for iOS Swift app discovery)
    NimBLEAdvertisementData scanData;
    scanData.setCompleteServices(NimBLEUUID(CONTROL_SERVICE_UUID));
    pAdvertising->setScanResponseData(scanData);

    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMaxPreferred(0x12);
    NimBLEDevice::startAdvertising();

    Serial.println("BLE Initialized. Advertising: OverByte");

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
    Serial.println("\n--- [ANCS DEBUG] RAW PACKET RECEIVED ---");
    Serial.printf("UUID: %s | Len: %d\n", pRemoteCharacteristic->getUUID().toString().c_str(), (int)length);

    if (pRemoteCharacteristic->getUUID().equals(NimBLEUUID(ANCS_NOTIF_SRC_UUID))) {
        if (length >= 8) {
            uint8_t eventID = pData[0];
            uint32_t notifUID = pData[4] | (pData[5] << 8) | (pData[6] << 16) | (pData[7] << 24);

            Serial.printf("[ANCS] Notification Event -> ID: %d, UID: %u\n", eventID, notifUID);
            
            // 0 = Added, 1 = Modified
            if (eventID == 0 || eventID == 1) { 
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
                    
                    char* lastDot = strrchr(bundleID, '.');
                    if (lastDot != nullptr && *(lastDot + 1) != '\0') {
                        strncpy((char*)notificationApp, lastDot + 1, sizeof(notificationApp) - 1);
                    } else {
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
                Serial.printf("[ANCS SUCCESS] App: %s | Sender: %s\n", notificationApp, notificationSender);
                hasNewNotification = true;
            }
        }
    } else if (pRemoteCharacteristic->getUUID().equals(NimBLEUUID(AMS_ENTITY_UPDATE_UUID))) {
        if (length >= 3) {
            uint8_t entityID = pData[0];
            uint8_t attributeID = pData[1];
            uint8_t flags = pData[2]; // EntityUpdateFlags
            
            if (entityID == 2) { // EntityIDTrack
                size_t strLen = length - 3;
                if (attributeID == 0) { // Artist
                    size_t cpyLen = (strLen < sizeof(currentArtist) - 1) ? strLen : sizeof(currentArtist) - 1;
                    memcpy((void*)currentArtist, &pData[3], cpyLen);
                    currentArtist[cpyLen] = '\0';
                    Serial.printf("[AMS] Track Artist: %s\n", currentArtist);
                } else if (attributeID == 2) { // Title
                    size_t cpyLen = (strLen < sizeof(currentSong) - 1) ? strLen : sizeof(currentSong) - 1;
                    memcpy((void*)currentSong, &pData[3], cpyLen);
                    currentSong[cpyLen] = '\0';
                    Serial.printf("[AMS] Track Title: %s\n", currentSong);
                    hasMediaUpdate = true;
                    triggerDisplayRefresh();
                }
            }
        }
    }
}


void ancsTask(void *pvParameters) {
    int retryDelay = 1500;
    const int maxDelay = 5000;
    
    while (true) {
        if (shouldStartANCS && isConnected && activeConnHandle != 0xFFFF) {
            ble_gap_conn_desc desc;
            if (ble_gap_conn_find(activeConnHandle, &desc) == 0) {
                if (!desc.sec_state.encrypted) {
                    Serial.println("ANCS: Connection not encrypted yet. Waiting for encryption/bonding...");
                    vTaskDelay(pdMS_TO_TICKS(500));
                    continue; 
                }
            }

            shouldStartANCS = false;
            
            vTaskDelay(pdMS_TO_TICKS(retryDelay)); 

            if (pANCSClient == nullptr) {
                pANCSClient = NimBLEDevice::createClient();
            }

            if (pANCSClient != nullptr) {
                NimBLEClientHack* pHack = (NimBLEClientHack*)pANCSClient;
                pHack->m_conn_id = activeConnHandle;
                pHack->m_connEstablished = true;

                Serial.printf("ANCS: Querying ANCS service (delay=%d ms)...\n", retryDelay);
                pANCSClient->deleteServices();

                NimBLERemoteService* pANCSService = pANCSClient->getService(NimBLEUUID(ANCS_SERVICE_UUID));
                
                if (pANCSService != nullptr) {
                    Serial.println("ANCS Service found!");
                    pControlPoint = pANCSService->getCharacteristic(NimBLEUUID(ANCS_CTRL_PT_UUID));
                    pDataSource = pANCSService->getCharacteristic(NimBLEUUID(ANCS_DATA_SRC_UUID));
                    NimBLERemoteCharacteristic* pNotifSource = pANCSService->getCharacteristic(NimBLEUUID(ANCS_NOTIF_SRC_UUID));

                    if (pDataSource && pDataSource->canNotify()) {
                        pDataSource->subscribe(true, notifyCB);
                        Serial.println("ANCS Data Source Subscribed!");
                    }
                    if (pNotifSource && pNotifSource->canNotify()) {
                        pNotifSource->subscribe(true, notifyCB);
                        Serial.println("ANCS Notification Source Subscribed!");
                    }

                    // Query for the AMS Service
                    Serial.println("AMS: Querying AMS service...");
                    NimBLERemoteService* pAMSService = pANCSClient->getService(NimBLEUUID(AMS_SERVICE_UUID));
                    if (pAMSService != nullptr) {
                        Serial.println("AMS Service found!");
                        NimBLERemoteCharacteristic* pEntityUpdateChar = pAMSService->getCharacteristic(NimBLEUUID(AMS_ENTITY_UPDATE_UUID));
                        if (pEntityUpdateChar != nullptr) {
                            if (pEntityUpdateChar->canNotify()) {
                                pEntityUpdateChar->subscribe(true, notifyCB);
                                Serial.println("AMS Entity Update Subscribed!");
                                
                                // Command to track Track Entity (2), Artist Attr (0), Title Attr (2)
                                uint8_t amsCmd[] = {2, 0, 2};
                                pEntityUpdateChar->writeValue(amsCmd, sizeof(amsCmd), true);
                                Serial.println("AMS Command written to Entity Update!");
                            }
                        }
                    } else {
                        Serial.println("AMS Service NOT found.");
                    }

                    retryDelay = 1500;

                } else {
                    Serial.println("ANCS Service not exposed by peer yet. Retrying...");
                    shouldStartANCS = true;
                    retryDelay += 1000;
                    if (retryDelay > maxDelay) retryDelay = maxDelay;
                }
            }
        }

        // Process pending notification requests outside the BLE callback
        if (pendingNotifUID != 0 && pControlPoint != nullptr && pANCSClient != nullptr && pANCSClient->isConnected()) {
            uint32_t uid = pendingNotifUID;
            pendingNotifUID = 0;

            Serial.printf("[ANCS] Requesting attributes for UID: %u\n", uid);

            uint8_t cmd[9];
            cmd[0] = 0; // CommandIDGetNotificationAttributes
            cmd[1] = uid & 0xFF; 
            cmd[2] = (uid >> 8) & 0xFF; 
            cmd[3] = (uid >> 16) & 0xFF; 
            cmd[4] = (uid >> 24) & 0xFF; // UID (4 bytes)
            cmd[5] = 0; // Attribute ID 0: AppIdentifier 
            cmd[6] = 1; // Attribute ID 1: Title 
            cmd[7] = 32; // Max Title Len LSB (32 bytes)
            cmd[8] = 0;  // Max Title Len MSB (0)
            
            pControlPoint->writeValue(cmd, 9, true);
        }

        vTaskDelay(pdMS_TO_TICKS(100)); // check every 100ms
    }
}
