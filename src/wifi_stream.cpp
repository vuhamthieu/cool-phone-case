// src/wifi_stream.cpp
#include "wifi_stream.h"
#include "config.h"
#include <WiFi.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

static WiFiUDP udp;
static bool wifiRunning = false;

// Double buffer setup to prevent screen tearing during rendering
static uint8_t frameBufferA[1024];
static uint8_t frameBufferB[1024];
static uint8_t* writeBuffer = frameBufferA;
static uint8_t* readBuffer = frameBufferB;
static volatile bool newFrameAvailable = false;

void wifiStreamInit() {
    if (wifiRunning) return;
    
    Serial.println("Initializing Wi-Fi AP...");
    WiFi.mode(WIFI_AP);
    
    // Configure AP IP (Standard 192.168.4.1 setup)
    IPAddress local_IP(192, 168, 4, 1);
    IPAddress gateway(192, 168, 4, 1);
    IPAddress subnet(255, 255, 255, 0);
    WiFi.softAPConfig(local_IP, gateway, subnet);
    
    if (WiFi.softAP(AP_SSID, AP_PASSWORD)) {
        Serial.printf("SoftAP Ready. SSID: %s\n", AP_SSID);
        Serial.print("SoftAP IP: ");
        Serial.println(WiFi.softAPIP());
    } else {
        Serial.println("SoftAP initialization failed!");
        return;
    }
    
    // Bind UDP port
    if (udp.begin(UDP_PORT)) {
        Serial.printf("UDP Server listening on port %d\n", UDP_PORT);
        wifiRunning = true;
        newFrameAvailable = false;
        // Reset buffers
        memset(frameBufferA, 0, 1024);
        memset(frameBufferB, 0, 1024);
    } else {
        Serial.println("Failed to bind UDP server.");
    }

    // Initialize ArduinoOTA
    ArduinoOTA.setHostname("OverByte");
    ArduinoOTA.setPassword(OTA_PASSWORD);
    
    ArduinoOTA.onStart([]() {
        Serial.println("OTA Update Started...");
    });
    ArduinoOTA.onEnd([]() {
        Serial.println("\nOTA Update Finished.");
    });
    ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
        Serial.printf("OTA Progress: %u%%\r", (progress / (total / 100)));
    });
    ArduinoOTA.onError([](ota_error_t error) {
        Serial.printf("OTA Error[%u]: ", error);
        if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
        else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
        else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
        else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
        else if (error == OTA_END_ERROR) Serial.println("End Failed");
    });
    
    ArduinoOTA.begin();
    Serial.println("ArduinoOTA Initialized.");
}

const uint8_t* wifiStreamGetLatestFrame() {
    if (!wifiRunning) return nullptr;
    
    // Check if a packet is available
    int packetSize = udp.parsePacket();
    if (packetSize > 0) {
        // Standard monochrome 128x64 grid is exactly 1024 bytes
        if (packetSize == 1024) {
            int bytesRead = udp.read(writeBuffer, 1024);
            if (bytesRead == 1024) {
                // Swap the write buffer and read buffer
                uint8_t* temp = writeBuffer;
                writeBuffer = readBuffer;
                readBuffer = temp;
                newFrameAvailable = true;
            }
        } else {
            // Discard mismatched packet sizes to keep flow clean
            udp.flush();
        }
    }
    
    if (newFrameAvailable) {
        return readBuffer; // Return the read buffer containing the last stable frame
    }
    
    return nullptr;
}

