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
            u8g2.setFont(u8g2_font_logisoso28_tn);
            snprintf(timeStr, sizeof(timeStr), "%02d:%02d", timeinfo.tm_hour, timeinfo.tm_min);
            drawTextCentered(42, timeStr);
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


void drawLowBatteryScreen(bool blinkState) {
    if (blinkState) {
        // Draw empty battery icon
        // Outer box (centered on screen)
        u8g2.drawFrame(49, 14, 30, 16);
        // Battery nipple
        u8g2.drawBox(79, 19, 3, 6);
        
        // Small warning exclamation mark inside battery
        u8g2.drawVLine(64, 18, 5);
        u8g2.drawPixel(64, 25);

        // Warning text
        u8g2.setFont(u8g2_font_6x10_tf);
        drawTextCentered(46, "LOW BATTERY");
        drawTextCentered(58, "PLEASE CHARGE");
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// renderActivity()
//
// Layout on 128×64 OLED (1-bit, u8g2):
//
//  ┌────────────────────────────────────────────────────────────────┐
//  │ ACTIVITY                                                       │  row y=10
//  │ [shoe] STEPS                            12,345                 │  row y=24
//  │ [heart] BPM                             72                     │  row y=38
//  │ [flame] CAL                             420 kcal               │  row y=52
//  └────────────────────────────────────────────────────────────────┘
//
// All bitmaps are 10×10 1-bit XBM patterns drawn inline.
// ─────────────────────────────────────────────────────────────────────────────

// 10×10 pixel-art shoe icon (XBM format, LSB first, row-major)
static const uint8_t SHOE_ICON[] PROGMEM = {
    // Each byte represents 8 horizontal pixels (left to right, LSB = leftmost)
    // Row 0-9:  (10 px wide → 2 bytes per row, second byte only uses low 2 bits)
    0x00, 0x00,   // ..........
    0x78, 0x00,   // .####.....
    0x7C, 0x00,   // .#####....
    0xFE, 0x01,   // .#######..  (bit8 = col 8)  → ##.......
    0xFE, 0x03,   // ########## 
    0xFE, 0x03,   // ##########
    0xFF, 0x03,   // ##########
    0xFE, 0x03,   // ##########
    0x00, 0x00,
    0x00, 0x00,
};

// 10×10 pixel-art heart icon (XBM format, LSB first)
static const uint8_t HEART_ICON[] PROGMEM = {
    0x00, 0x00,
    0x66, 0x00,   // .##..##...
    0xFF, 0x01,   // #########.
    0xFF, 0x01,   // #########.
    0xFF, 0x01,   // #########.
    0xFE, 0x00,   // .########.
    0xFC, 0x00,   // ..#######.
    0xF8, 0x00,   // ...######.
    0x70, 0x00,   // ....####..
    0x20, 0x00,   // .....##...
};

// 10×10 pixel-art flame icon (XBM format, LSB first)
static const uint8_t FLAME_ICON[] PROGMEM = {
    0x10, 0x00,   // ...#......
    0x38, 0x00,   // ..###.....
    0x7C, 0x00,   // .#####....
    0xFC, 0x00,   // ######....
    0xFE, 0x00,   // #######...
    0xEE, 0x00,   // ###.###...
    0xFE, 0x00,   // #######...
    0xFC, 0x00,   // ######....
    0x78, 0x00,   // .####.....
    0x30, 0x00,   // ..##......
};

void renderActivity(uint32_t steps, uint16_t bpm, uint16_t calories) {
    char buf[24];

    // ── Title row ──────────────────────────────────────────────────────────
    u8g2.setFont(u8g2_font_5x7_tf);
    u8g2.drawStr(0, 9, "ACTIVITY");

    // Horizontal separator under title
    u8g2.drawHLine(0, 12, 128);

    // ── Row helper lambda: icon + label (left) + value (right-aligned) ─────
    // Row 1: Steps (shoe icon at x=0, y=14 → icon is 10 tall so fits to y=24)
    u8g2.drawXBMP(0, 14, 10, 10, SHOE_ICON);
    u8g2.setFont(u8g2_font_5x7_tf);
    u8g2.drawStr(13, 23, "STEPS");
    // Right-align value
    snprintf(buf, sizeof(buf), "%lu", (unsigned long)steps);
    {
        int w = u8g2.getStrWidth(buf);
        u8g2.drawStr(128 - w, 23, buf);
    }

    // Thin separator
    u8g2.drawHLine(0, 26, 128);

    // ── Row 2: Heart Rate ───────────────────────────────────────────────────
    u8g2.drawXBMP(0, 28, 10, 10, HEART_ICON);
    u8g2.drawStr(13, 37, "BPM");
    snprintf(buf, sizeof(buf), "%u", bpm);
    {
        int w = u8g2.getStrWidth(buf);
        u8g2.drawStr(128 - w, 37, buf);
    }

    u8g2.drawHLine(0, 40, 128);

    // ── Row 3: Calories ─────────────────────────────────────────────────────
    u8g2.drawXBMP(0, 42, 10, 10, FLAME_ICON);
    u8g2.drawStr(13, 51, "KCAL");
    snprintf(buf, sizeof(buf), "%u", calories);
    {
        int w = u8g2.getStrWidth(buf);
        u8g2.drawStr(128 - w, 51, buf);
    }

    u8g2.drawHLine(0, 54, 128);

    // ── Footer: "LIVE" badge if we have non-zero data ─────────────────────
    if (steps > 0 || bpm > 0) {
        u8g2.drawStr(0, 63, "* iOS LIVE");
    } else {
        u8g2.drawStr(0, 63, "waiting...");
    }
}