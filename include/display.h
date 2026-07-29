// include/display.h
#pragma once
#include <U8g2lib.h>
#include "config.h"

// Initialize the physical OLED display (SH1106, I2C)
void displayInit();

// Clear the display backbuffer
void displayClear();

// Push backbuffer to physical display
void displayUpdate();

// Utility to draw centered string
void drawTextCentered(int y, const char* text);

// Render the clock faces based on current ClockStyle sub-state
void renderClock(ClockStyle style);

// Render a specific frame of a Mochi animation
void renderMochi(MochiEmotion emotion, uint8_t frameIndex);

// Render Apple HealthKit activity data on the OLED
void renderActivity(uint32_t steps, uint16_t bpm, uint16_t calories);

// Render the blinking low battery override screen
void drawLowBatteryScreen(bool blinkState);