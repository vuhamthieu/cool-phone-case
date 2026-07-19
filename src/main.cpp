// src/main.cpp
#include <Arduino.h>
#include "config.h"
#include "pins.h"
#include "display.h"
#include "ble.h"
#include "wifi_stream.h"
#include "mochi_faces.h"

// Global state definitions
SystemMode currentMode = MODE_MOCHI;
ClockStyle currentClockStyle = CLOCK_BIG_DIGITAL;
MochiEmotion currentMochiEmotion = MOCHI_HAPPY;
CameraFilter currentCameraFilter = CAMERA_NORMAL;

volatile bool modeChangedFlag = false;
volatile bool touchTriggeredFlag = false;
bool timeSynced = false;

// Variables for Touch Debouncing
static bool lastTouchState = LOW;
static unsigned long lastDebounceTime = 0;
static const unsigned long DEBOUNCE_DELAY_MS = 30; 

// Variables for Mochi animation control
static unsigned long lastMochiFrameTime = 0;
static uint8_t mochiFrameIndex = 0;

// Gesture recognition variables for Mochi Mode
static int mochiTapCount = 0;
static unsigned long mochiLastTapTime = 0;
static bool mochiTouchIsHeld = false;
static unsigned long mochiTouchStartTime = 0;
static bool mochiGestureActive = false;
static MochiEmotion mochiActiveGestureEmotion = MOCHI_DEFAULT;
static unsigned long mochiGestureEndTime = 0;

// Frame buffer cache to allow instant rendering when switching filters
static uint8_t cachedCameraFrame[1024];
static bool hasCachedFrame = false;

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("--- Starting Mochi Second Screen Phone Case ---");
    
    // Configure inputs
    pinMode(PIN_TOUCH, INPUT);
    
    // Initialize components
    displayInit();
    bleInit();
    
    // Show splash screen on boot
    displayClear();
    drawTextCentered(20, "MOCHI CASE");
    drawTextCentered(35, "V1.0.0");
    drawTextCentered(50, "Waiting for BLE...");
    displayUpdate();
    
    delay(1500);
    displayClear();
}

void handleTouchInput() {
    bool currentTouchState = digitalRead(PIN_TOUCH);
    
    // Check if the Touch state changed
    if (currentTouchState != lastTouchState) {
        lastDebounceTime = millis();
    }
    
    if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY_MS) {
        // Continuous check for hold/rub gesture in Mochi mode
        if (currentMode == MODE_MOCHI && currentTouchState == HIGH) {
            unsigned long heldTime = millis() - mochiTouchStartTime;
            if (heldTime > 15000) { // Held/rubbed for over 15s -> Angry face
                mochiTouchIsHeld = true;
                mochiGestureActive = true;
                if (mochiActiveGestureEmotion != MOCHI_ANGRY) {
                    mochiActiveGestureEmotion = MOCHI_ANGRY;
                    mochiFrameIndex = 0;
                    lastMochiFrameTime = millis();
                    Serial.println("Gesture: Constant rubbing > 15s -> Angry face");
                }
                mochiGestureEndTime = 0; // Remain angry as long as held
            } else if (heldTime > 1000 && !mochiTouchIsHeld) { // Held for over 1s -> Happy face
                mochiTouchIsHeld = true;
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_HAPPY;
                mochiGestureEndTime = 0; // Remain happy as long as held
                mochiFrameIndex = 0;
                lastMochiFrameTime = millis();
                Serial.println("Gesture: Hold/Rub detected -> Happy face");
            }
        }

        // Edge detection settled
        if (currentTouchState == HIGH && !touchTriggeredFlag) {
            touchTriggeredFlag = true;
            
            // Cycle sub-states based on current mode
            switch (currentMode) {
                case MODE_CLOCK:
                    currentClockStyle = (ClockStyle)((currentClockStyle + 1) % CLOCK_STYLE_MAX);
                    Serial.printf("Clock Style changed to: %d\n", currentClockStyle);
                    break;
                case MODE_MOCHI:
                    mochiTouchStartTime = millis();
                    mochiTouchIsHeld = false;
                    break;
                case MODE_CAMERA:
                    currentCameraFilter = (CameraFilter)((currentCameraFilter + 1) % CAMERA_FILTER_MAX);
                    Serial.printf("Camera Filter changed to: %d\n", currentCameraFilter);
                    
                    // Force a re-render of cached frame with new filter
                    if (hasCachedFrame) {
                        displayClear();
                        renderCameraStream(cachedCameraFrame, currentCameraFilter);
                        displayUpdate();
                    }
                    break;
            }
        } else if (currentTouchState == LOW && touchTriggeredFlag) {
            // Touch released
            touchTriggeredFlag = false;
            
            if (currentMode == MODE_MOCHI) {
                if (mochiTouchIsHeld) {
                    // Just released a hold/rub gesture
                    if (mochiActiveGestureEmotion == MOCHI_ANGRY) {
                        mochiGestureEndTime = millis() + 2000; // Stay angry for 2s post-release
                    } else {
                        mochiGestureEndTime = millis() + 800; // Stay happy for 800ms post-release
                    }
                    mochiTouchIsHeld = false;
                } else {
                    // Short tap detected
                    mochiTapCount++;
                    mochiLastTapTime = millis();
                    Serial.printf("Mochi tap count: %d\n", mochiTapCount);
                }
            }
        }
    }
    
    // Check if the tap sequence has completed (300ms of inactivity after tap)
    if (currentMode == MODE_MOCHI && mochiTapCount > 0 && currentTouchState == LOW) {
        if (millis() - mochiLastTapTime > 450) {
            if (mochiTapCount == 1) {
                // 1 Tap -> What face
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_WHAT;
                mochiGestureEndTime = millis() + 2000;
                mochiFrameIndex = 0;
                lastMochiFrameTime = millis();
                Serial.println("Gesture: 1 Tap -> What face");
            } else if (mochiTapCount >= 2) {
                // 2+ Taps -> Judging face
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_JUDGE;
                mochiGestureEndTime = millis() + 2500;
                mochiFrameIndex = 0;
                lastMochiFrameTime = millis();
                Serial.println("Gesture: 2 Taps -> Judging face");
            }
            mochiTapCount = 0;
        }
    }
    
    lastTouchState = currentTouchState;
}

void loop() {
    // 1. Process Touch Sensor Inputs
    handleTouchInput();
    
    // 2. Handle Mode Transitions triggered by BLE write characteristic
    if (modeChangedFlag) {
        modeChangedFlag = false;
        
        // Mode transition side effects
        if (currentMode == MODE_CAMERA) {
            // Turning on Camera mode -> boot Wi-Fi SoftAP and UDP
            wifiStreamStart();
        } else {
            // Leaving Camera mode -> shutdown Wi-Fi to save battery
            wifiStreamStop();
            hasCachedFrame = false;
        }
        
        displayClear();
    }
    
    // 3. Render current active Mode
    switch (currentMode) {
        case MODE_CLOCK:
            displayClear();
            renderClock(currentClockStyle);
            displayUpdate();
            delay(100); // 10Hz UI refresh for clock is plenty
            break;
            
        case MODE_MOCHI: {
            // Apply gesture animation overrides if active
            if (mochiGestureActive) {
                if (mochiGestureEndTime > 0 && millis() > mochiGestureEndTime) {
                    mochiGestureActive = false;
                    currentMochiEmotion = MOCHI_DEFAULT;
                    mochiFrameIndex = 0;
                    lastMochiFrameTime = millis();
                } else {
                    currentMochiEmotion = mochiActiveGestureEmotion;
                }
            } else {
                currentMochiEmotion = MOCHI_DEFAULT;
            }

            unsigned long now = millis();
            uint16_t delayMs = mochiAnimations[currentMochiEmotion].frameDelayMs;
            
            if (now - lastMochiFrameTime >= delayMs) {
                lastMochiFrameTime = now;
                mochiFrameIndex = (mochiFrameIndex + 1) % mochiAnimations[currentMochiEmotion].frameCount;
            }
            
            displayClear();
            renderMochi(currentMochiEmotion, mochiFrameIndex);
            displayUpdate();
            delay(30); // 30Hz frame render rate
            break;
        }
            
        case MODE_CAMERA: {
            const uint8_t* newFrame = wifiStreamGetLatestFrame();
            if (newFrame != nullptr) {
                // Cache frame in case filter changes while stream is idle
                memcpy(cachedCameraFrame, newFrame, 1024);
                hasCachedFrame = true;
                
                displayClear();
                renderCameraStream(newFrame, currentCameraFilter);
                displayUpdate();
            } else if (!hasCachedFrame) {
                // Display waiting screen if no frames received yet
                displayClear();
                renderCameraStream(nullptr, currentCameraFilter);
                displayUpdate();
            }
            // Yield to background tasks/Wi-Fi stack
            delay(5);
            break;
        }
    }
}