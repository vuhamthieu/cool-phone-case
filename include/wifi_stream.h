// include/wifi_stream.h
#pragma once
#include <Arduino.h>

// Initialize Wi-Fi AP, UDP socket, and ArduinoOTA at boot
void wifiStreamInit();

// Check UDP socket for new frame data. 
// Returns pointer to latest 1024-byte frame if available, else nullptr.
const uint8_t* wifiStreamGetLatestFrame();

