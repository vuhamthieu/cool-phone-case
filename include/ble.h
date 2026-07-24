// include/ble.h
#pragma once
#include <Arduino.h>


// Initialize the BLE device, services, and characteristics
void bleInit();

// Returns true if an iOS client is currently connected via BLE
bool bleIsConnected();

// Updates the BLE battery level characteristic and notifies the client
void bleUpdateBattery(uint8_t percent);