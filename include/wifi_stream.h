// include/wifi_stream.h
#pragma once
#include <Arduino.h>

// Start Wi-Fi AP and initialize UDP socket listener
void wifiStreamStart();

// Shutdown Wi-Fi AP and close UDP socket to conserve power
void wifiStreamStop();

// Check UDP socket for new frame data. 
// Returns pointer to latest 1024-byte frame if available, else nullptr.
const uint8_t* wifiStreamGetLatestFrame();
