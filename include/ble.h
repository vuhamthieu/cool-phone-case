// include/ble.h
#pragma once

// Initialize the BLE device, services, and characteristics
void bleInit();

// Returns true if an iOS client is currently connected via BLE
bool bleIsConnected();