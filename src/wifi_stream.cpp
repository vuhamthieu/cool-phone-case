// src/wifi_stream.cpp
#include "wifi_stream.h"
#include "config.h"
#include <WiFi.h>
#include <ArduinoOTA.h>

static bool wifiRunning = false;

void wifiStreamInit() {
    if (wifiRunning) return;
    
    Serial.println("Initializing Wi-Fi AP for OTA...");
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
        wifiRunning = true;
    } else {
        Serial.println("SoftAP initialization failed!");
        return;
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
    return nullptr;
}
