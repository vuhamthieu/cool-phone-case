// src/display.cpp
#include "display.h"
#include "pins.h"
#include "mochi_faces.h"
#include <time.h>
#include <math.h>

// Initialize physical display using HW I2C
// For ESP32-C3 Super Mini, default I2C pins are SDA=8, SCL=9.
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE, PIN_OLED_SCL, PIN_OLED_SDA);

void displayInit() {
    u8g2.begin();
    u8g2.setFont(u8g2_font_6x10_tf); // Default small readable font
}

void displayClear() {
    u8g2.clearBuffer();
}

void displayUpdate() {
    u8g2.sendBuffer();
}

void drawTextCentered(int y, const char* text) {
    int width = u8g2.getStrWidth(text);
    int x = (128 - width) / 2;
    u8g2.drawStr(x, y, text);
}

// Draw a beautiful analog clock face
void drawAnalogClock(int centerX, int centerY, int radius, int hr, int min, int sec) {
    // Clock face boundary
    u8g2.drawCircle(centerX, centerY, radius);
    u8g2.drawCircle(centerX, centerY, 1); // Center dot
    
    // Draw tick marks for 12, 3, 6, 9 o'clock
    u8g2.drawLine(centerX, centerY - radius, centerX, centerY - radius + 3);
    u8g2.drawLine(centerX, centerY + radius, centerX, centerY + radius - 3);
    u8g2.drawLine(centerX - radius, centerY, centerX - radius + 3, centerY);
    u8g2.drawLine(centerX + radius, centerY, centerX + radius - 3, centerY);
    
    // Angles in radians
    float secAngle = (sec * 6 - 90) * M_PI / 180.0;
    float minAngle = (min * 6 - 90) * M_PI / 180.0;
    float hrAngle  = ((hr % 12) * 30 + min * 0.5 - 90) * M_PI / 180.0;
    
    // Hand lengths
    int hrLength = radius * 0.5;
    int minLength = radius * 0.75;
    int secLength = radius * 0.85;
    
    // Draw hands
    u8g2.drawLine(centerX, centerY, centerX + hrLength * cos(hrAngle), centerY + hrLength * sin(hrAngle));
    u8g2.drawLine(centerX, centerY, centerX + minLength * cos(minAngle), centerY + minLength * sin(minAngle));
    
    // Draw seconds hand with thin line
    u8g2.drawLine(centerX, centerY, centerX + secLength * cos(secAngle), centerY + secLength * sin(secAngle));
}

void renderClock(ClockStyle style) {
    time_t now;
    struct tm timeinfo;
    time(&now);
    localtime_r(&now, &timeinfo);
    
    char timeStr[16];
    char dateStr[32];
    
    switch (style) {
        case CLOCK_BIG_DIGITAL:
            // Large font digits: e.g. u8g2_font_logisoso28_tn
            u8g2.setFont(u8g2_font_logisoso28_tn);
            snprintf(timeStr, sizeof(timeStr), "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
            drawTextCentered(42, timeStr);
            
            // Draw small seconds below the clock
            u8g2.setFont(u8g2_font_6x10_tf);
            snprintf(timeStr, sizeof(timeStr), ":%02d", timeinfo.tm_sec);
            u8g2.drawStr(100, 52, timeStr);
            
            // Connection icon indicator
            if (timeSynced) {
                u8g2.drawStr(5, 58, "BLE OK");
            } else {
                u8g2.drawStr(5, 58, "NO SYNC");
            }
            break;
            
        case CLOCK_DIGITAL_DATE:
            // Medium digital style with Date displayed
            u8g2.setFont(u8g2_font_ncenB14_tr);
            snprintf(timeStr, sizeof(timeStr), "%02d:%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
            drawTextCentered(28, timeStr);
            
            u8g2.setFont(u8g2_font_6x12_tr);
            // Format: e.g., "Saturday, Jul 18"
            strftime(dateStr, sizeof(dateStr), "%A, %b %d", &timeinfo);
            drawTextCentered(48, dateStr);
            break;
            
        case CLOCK_ANALOG:
            // Render Analog dial on the left, Digital read on the right
            drawAnalogClock(34, 32, 28, timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
            
            // Render HH:MM:SS text to the right
            u8g2.setFont(u8g2_font_7x14_tf);
            snprintf(timeStr, sizeof(timeStr), "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
            u8g2.drawStr(75, 28, timeStr);
            
            u8g2.setFont(u8g2_font_6x10_tf);
            snprintf(timeStr, sizeof(timeStr), ":%02d", timeinfo.tm_sec);
            u8g2.drawStr(110, 28, timeStr);
            
            // Year/Date
            snprintf(dateStr, sizeof(dateStr), "%02d/%02d", timeinfo.tm_mday, timeinfo.tm_mon + 1);
            u8g2.drawStr(80, 48, dateStr);
            break;
            
        default:
            break;
    }
}

void renderMochi(MochiEmotion emotion, uint8_t frameIndex) {
    if (emotion >= MOCHI_EMOTION_MAX) return;
    
    // Mochi animation struct handles XBM frame loading
    const MochiAnimation anim = mochiAnimations[emotion];
    uint8_t frame = frameIndex % anim.frameCount;
    
    // Draw centered 128x64 XBM frame
    u8g2.drawXBMP(0, 0, 128, 64, anim.frames[frame]);
}

void renderCameraStream(const uint8_t* frameBuffer, CameraFilter filter) {
    if (frameBuffer == nullptr) {
        u8g2.setFont(u8g2_font_6x10_tf);
        drawTextCentered(32, "WAITING FOR STREAM");
        return;
    }
    
    if (filter == CAMERA_INVERTED) {
        // Invert the 1-bit buffer bytes (1024 bytes)
        uint8_t invertedBuffer[1024];
        for (int i = 0; i < 1024; i++) {
            invertedBuffer[i] = ~frameBuffer[i];
        }
        u8g2.drawXBMP(0, 0, 128, 64, invertedBuffer);
    } else {
        // Render normal stream
        u8g2.drawXBMP(0, 0, 128, 64, frameBuffer);
    }
    
    // Draw Viewfinder Overlay if requested
    if (filter == CAMERA_VIEWFINDER) {
        u8g2.setDrawColor(2); // XOR mode so overlay is visible on both black and white pixels
        
        // Center crosshair
        u8g2.drawHLine(60, 32, 8);
        u8g2.drawVLine(64, 28, 8);
        
        // Corners brackets
        u8g2.drawHLine(4, 4, 8);
        u8g2.drawVLine(4, 4, 8);
        
        u8g2.drawHLine(116, 4, 8);
        u8g2.drawVLine(123, 4, 8);
        
        u8g2.drawHLine(4, 59, 8);
        u8g2.drawVLine(4, 52, 8);
        
        u8g2.drawHLine(116, 59, 8);
        u8g2.drawVLine(123, 52, 8);
        
        u8g2.setDrawColor(1); // Restore normal write mode
    }
}