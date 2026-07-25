// src/main.cpp
#include <Arduino.h>
#include <ArduinoOTA.h>
#include "config.h"
#include "pins.h"
#include "display.h"
#include "ble.h"
#include "wifi_stream.h"
#include "mochi_faces.h"
#include "touch.h"

// Global state definitions
SystemMode currentMode = MODE_MOCHI;
ClockStyle currentClockStyle = CLOCK_BIG_DIGITAL;
MochiEmotion currentMochiEmotion = MOCHI_HAPPY;
CameraFilter currentCameraFilter = CAMERA_NORMAL;

volatile bool modeChangedFlag = false;
volatile bool touchTriggeredFlag = false;
bool timeSynced = false;

// Battery & Multitasking States
volatile bool isLowBattery = false;
SemaphoreHandle_t displayMutex = NULL;

// Camera Frame Cache
uint8_t cachedCameraFrame[1024];
bool hasCachedFrame = false;

// Task functions
void Task1_UDP_Display(void* pvParameters);
void Task2_General(void* pvParameters);

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("--- Starting OverByte Second Screen Phone Case ---");
    
    // Configure inputs
    pinMode(PIN_BAT_ADC, ANALOG);
    touchInit();
    
    // Create Mutex for shared display access
    displayMutex = xSemaphoreCreateMutex();
    if (displayMutex == NULL) {
        Serial.println("Error creating display mutex!");
    }
    
    // Initialize components
    displayInit();
    bleInit();
    wifiStreamInit(); // Starts Wi-Fi AP, UDP Server, and ArduinoOTA
    
    // Show splash screen on boot
    if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
        displayClear();
        drawTextCentered(20, "OVERBYTE");
        drawTextCentered(35, "V1.0.0");
        drawTextCentered(50, "Waiting for BLE...");
        displayUpdate();
        xSemaphoreGive(displayMutex);
    }
    
    delay(1500);
    
    if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
        displayClear();
        displayUpdate();
        xSemaphoreGive(displayMutex);
    }

    // Perform initial ADC Battery check
    uint32_t adcSum = 0;
    for (int i = 0; i < 50; i++) {
        adcSum += analogReadMilliVolts(PIN_BAT_ADC);
        delay(1);
    }
    float avgPinMilliVolts = (float)adcSum / 50.0f;
    float batteryVoltage = (avgPinMilliVolts * 2.0f) / 1000.0f;
    int pct = (int)round((batteryVoltage - 3.2f) / (4.2f - 3.2f) * 100.0f);
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;
    
    bleUpdateBattery(pct);
    if (batteryVoltage >= 4.15f) {
        isLowBattery = false;
    } else if (pct <= 20) {
        isLowBattery = true;
    } else {
        isLowBattery = false;
    }
    Serial.printf("Initial Battery: %.2fV (%d%%), LowBattery=%s\n", batteryVoltage, pct, isLowBattery ? "TRUE" : "FALSE");
    
    // Create FreeRTOS Tasks pinned to Core 0 (since ESP32-C3 is single-core)
    xTaskCreatePinnedToCore(
        Task1_UDP_Display,
        "UDP_Display_Task",
        4096,
        NULL,
        2, // Higher priority for smooth frame processing
        NULL,
        0
    );

    xTaskCreatePinnedToCore(
        Task2_General,
        "General_Task",
        4096,
        NULL,
        1, // Lower priority
        NULL,
        0
    );
}

void loop() {
    // The standard loop task is suspended to let our FreeRTOS tasks run
    vTaskDelay(portMAX_DELAY);
}

// Task 1: Dedicated to the UDP Receiver loop and rendering video frames to the OLED display
void Task1_UDP_Display(void* pvParameters) {
    (void)pvParameters;
    
    for (;;) {
        if (currentMode == MODE_CAMERA && !isLowBattery) {
            const uint8_t* newFrame = wifiStreamGetLatestFrame();
            if (newFrame != nullptr) {
                // Cache frame in case filter changes while stream is idle
                memcpy(cachedCameraFrame, newFrame, 1024);
                hasCachedFrame = true;
                
                if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                    displayClear();
                    renderCameraStream(newFrame, currentCameraFilter);
                    displayUpdate();
                    xSemaphoreGive(displayMutex);
                }
            } else if (!hasCachedFrame) {
                // Display waiting screen if no frames received yet
                if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                    displayClear();
                    renderCameraStream(nullptr, currentCameraFilter);
                    displayUpdate();
                    xSemaphoreGive(displayMutex);
                }
            }
            vTaskDelay(pdMS_TO_TICKS(5)); // Prevent CPU starvation
        } else {
            vTaskDelay(pdMS_TO_TICKS(100)); // Idle/yield when not in camera mode or if battery is low
        }
    }
}

// Task 2: Handles the general loop (ArduinoOTA handle(), BLE Events, ADC battery polling, and touch sensor status checks)
void Task2_General(void* pvParameters) {
    (void)pvParameters;
    
    unsigned long lastBatteryCheck = 0;
    unsigned long lastBlinkToggle = 0;
    bool blinkState = false;
    
    // Animation timing for Mochi
    unsigned long lastMochiFrameTime = 0;
    uint8_t mochiFrameIndex = 0;

    for (;;) {
        // 1. Handle OTA updates
        ArduinoOTA.handle();
        
        // 2. Poll Capacitive Touch Sensor status checks
        touchProcess();
        
        // 3. Battery Polling every 60 seconds (non-blocking)
        unsigned long now = millis();
        if (now - lastBatteryCheck >= 60000 || lastBatteryCheck == 0) {
            lastBatteryCheck = now;
            
            // Read 50 ADC samples in quick succession
            uint32_t adcSum = 0;
            for (int i = 0; i < 50; i++) {
                adcSum += analogReadMilliVolts(PIN_BAT_ADC);
                delay(1);
            }
            float avgPinMilliVolts = (float)adcSum / 50.0f;
            float batteryVoltage = (avgPinMilliVolts * 2.0f) / 1000.0f;
            
            // Map actual voltage (from 3.2V to 4.2V) to percentage (0% - 100%)
            int pct = (int)round((batteryVoltage - 3.2f) / (4.2f - 3.2f) * 100.0f);
            if (pct < 0) pct = 0;
            if (pct > 100) pct = 100;
            
            // Update this value to the BLE Battery Characteristic
            bleUpdateBattery(pct);
            
            // Update low battery flag status
            if (batteryVoltage >= 4.15f) {
                isLowBattery = false;
            } else if (pct <= 20) {
                isLowBattery = true;
            } else {
                isLowBattery = false;
            }
            
            Serial.printf("Battery Polling: %.2fV (%d%%), LowBattery=%s\n", batteryVoltage, pct, isLowBattery ? "TRUE" : "FALSE");
        }
        
        // 4. Handle Mode Transitions triggered by BLE write characteristic
        if (modeChangedFlag) {
            modeChangedFlag = false;
            if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                displayClear();
                displayUpdate();
                xSemaphoreGive(displayMutex);
            }
        }
        
        // 5. Render current active Mode
        if (isLowBattery) {
            if (now - lastBlinkToggle >= 500) {
                blinkState = !blinkState;
                lastBlinkToggle = now;
            }
            
            // Priority Alert Override: immediately draw blinking empty battery
            if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                displayClear();
                drawLowBatteryScreen(blinkState);
                displayUpdate();
                xSemaphoreGive(displayMutex);
            }
            vTaskDelay(pdMS_TO_TICKS(100)); // Refresh warning screen at 10Hz
        } else {
            switch (currentMode) {
                case MODE_CLOCK:
                    if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                        displayClear();
                        renderClock(currentClockStyle);
                        displayUpdate();
                        xSemaphoreGive(displayMutex);
                    }
                    vTaskDelay(pdMS_TO_TICKS(100)); // 10Hz UI refresh for clock is plenty
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

                    unsigned long frameNow = millis();
                    uint16_t delayMs = mochiAnimations[currentMochiEmotion].frameDelayMs;
                    
                    if (frameNow - lastMochiFrameTime >= delayMs) {
                        lastMochiFrameTime = frameNow;
                        mochiFrameIndex = (mochiFrameIndex + 1) % mochiAnimations[currentMochiEmotion].frameCount;
                    }
                    
                    if (xSemaphoreTake(displayMutex, portMAX_DELAY) == pdTRUE) {
                        displayClear();
                        renderMochi(currentMochiEmotion, mochiFrameIndex);
                        displayUpdate();
                        xSemaphoreGive(displayMutex);
                    }
                    vTaskDelay(pdMS_TO_TICKS(30)); // 30Hz frame render rate
                    break;
                }
                    
                case MODE_CAMERA:
                    // Task 1 handles camera rendering, so Task 2 yields
                    vTaskDelay(pdMS_TO_TICKS(50));
                    break;
            }
        }
    }
}