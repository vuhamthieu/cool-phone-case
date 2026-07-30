// src/touch.cpp
#include "touch.h"
#include "config.h"
#include "pins.h"
#include "display.h"

// Touch variables
static bool lastTouchState = LOW;
static unsigned long lastDebounceTime = 0;
static const unsigned long DEBOUNCE_DELAY_MS = 30;

// Gesture state variables
int mochiTapCount = 0;
unsigned long mochiLastTapTime = 0;
bool mochiTouchIsHeld = false;
unsigned long mochiTouchStartTime = 0;
bool mochiGestureActive = false;
MochiEmotion mochiActiveGestureEmotion = MOCHI_DEFAULT;
unsigned long mochiGestureEndTime = 0;

void touchInit() {
    pinMode(PIN_TOUCH, INPUT);
}

void touchProcess() {
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
                    Serial.println("Gesture: Constant rubbing > 15s -> Angry face");
                }
                mochiGestureEndTime = 0; // Remain angry as long as held
            } else if (heldTime > 1000 && !mochiTouchIsHeld) { // Held for over 1s -> Happy face
                mochiTouchIsHeld = true;
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_HAPPY;
                mochiGestureEndTime = 0; // Remain happy as long as held
                Serial.println("Gesture: Hold/Rub detected -> Happy face");
            }
        }

        // Edge detection settled
        if (currentTouchState == HIGH && !touchTriggeredFlag) {
            touchTriggeredFlag = true;

            // Touch only controls Mochi emote mode — clock style is set by the iOS app via BLE
            if (currentMode == MODE_MOCHI) {
                mochiTouchStartTime = millis();
                mochiTouchIsHeld = false;
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
    
    // Check if the tap sequence has completed (450ms of inactivity after tap)
    if (currentMode == MODE_MOCHI && mochiTapCount > 0 && currentTouchState == LOW) {
        if (millis() - mochiLastTapTime > 450) {
            if (mochiTapCount == 1) {
                // 1 Tap -> What face
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_WHAT;
                mochiGestureEndTime = millis() + 2000;
                Serial.println("Gesture: 1 Tap -> What face");
            } else if (mochiTapCount >= 2) {
                // 2+ Taps -> Judging face
                mochiGestureActive = true;
                mochiActiveGestureEmotion = MOCHI_JUDGE;
                mochiGestureEndTime = millis() + 2500;
                Serial.println("Gesture: 2 Taps -> Judging face");
            }
            mochiTapCount = 0;
        }
    }
    
    lastTouchState = currentTouchState;
}
