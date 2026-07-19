// include/config.h
#pragma once
#include <Arduino.h>

// BLE UUIDs
#define CONTROL_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_MODE_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_TIME_UUID    "e3223119-944c-477c-abf1-efac3e8b15d0"

// Wi-Fi Config for Camera Streaming
#define AP_SSID     "MochiCase_AP"
#define AP_PASSWORD "mochicase123"
#define UDP_PORT    5001

// 3 Main Modes
enum SystemMode {
    MODE_CLOCK = 0,
    MODE_MOCHI = 1,
    MODE_CAMERA = 2
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

// Sub-states/Filters for Camera Mode
enum CameraFilter {
    CAMERA_NORMAL = 0,
    CAMERA_INVERTED = 1,
    CAMERA_VIEWFINDER = 2,
    CAMERA_FILTER_MAX = 3
};

// Global States
extern SystemMode currentMode;
extern ClockStyle currentClockStyle;
extern MochiEmotion currentMochiEmotion;
extern CameraFilter currentCameraFilter;
extern volatile bool modeChangedFlag;
extern volatile bool touchTriggeredFlag;
extern bool timeSynced;