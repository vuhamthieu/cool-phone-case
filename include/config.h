// include/config.h
#pragma once
#include <Arduino.h>

// BLE UUIDs
#define CONTROL_SERVICE_UUID          "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_MODE_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_TIME_UUID      "e3223119-944c-477c-abf1-efac3e8b15d0"
#define CHARACTERISTIC_CLOCK_STYLE_UUID "c5b6a7d8-e9f0-1234-abcd-ef1234567890"

// Wi-Fi Config for OTA only
#if __has_include("secrets.h")
#include "secrets.h"
#else
#error "secrets.h is missing! Copy secrets.h.example to secrets.h and customize your local credentials."
#endif

// 2 Main Modes (MODE_ACTIVITY and MODE_CAMERA have been removed)
enum SystemMode {
    MODE_CLOCK    = 0,
    MODE_MOCHI    = 1
};

// Sub-states for Clock Mode
enum ClockStyle {
    CLOCK_BIG_DIGITAL = 0,
    CLOCK_DIGITAL_DATE = 1,
    CLOCK_ANALOG = 2,
    CLOCK_STYLE_MAX = 3
};

// Sub-states for Mochi Mode
enum MochiEmotion {
    MOCHI_DEFAULT = 0,
    MOCHI_WHAT = 1,
    MOCHI_JUDGE = 2,
    MOCHI_HAPPY = 3,
    MOCHI_ANGRY = 4,
    MOCHI_EMOTION_MAX = 5
};

// Global States
extern SystemMode currentMode;
extern ClockStyle currentClockStyle;
extern MochiEmotion currentMochiEmotion;
extern volatile bool modeChangedFlag;
extern volatile bool touchTriggeredFlag;
extern bool timeSynced;

// Battery & Multitasking States
extern volatile bool isLowBattery;
extern SemaphoreHandle_t displayMutex;

// Touch Gesture States
extern bool mochiGestureActive;
extern MochiEmotion mochiActiveGestureEmotion;
extern unsigned long mochiGestureEndTime;