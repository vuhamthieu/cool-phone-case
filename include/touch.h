// include/touch.h
#pragma once
#include <Arduino.h>

// Initialize capacitive touch pin
void touchInit();

// Poll capacitive touch sensor, process gestures (tap, double tap, hold),
// and update system states (modes, clock styles, mochi emotions, camera filters)
void touchProcess();
