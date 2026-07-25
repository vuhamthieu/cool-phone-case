# OverByte: The Second Screen Phone Case

![OverByte 3D Concept](assets/tilt.png)

## Overview

So recently, I had this idea for a working second screen on the back of the phone. I just thought it might be interesting and look pretty cool to have something going on back there. 😄

That's basically how **OverByte** started. It’s a custom-built, cyberpunk-style smart case with a 1-bit OLED display, a touch sensor, and a native iOS app that connects via BLE. 

Nothing too crazy or battery-draining—just a raw, minimalist screen that shows the time, reacts to your touch with some fun emotes, and even streams the iPhone's camera. Just a fun little side project to make the back of the phone less boring! 🚀

## Key Features

*   **Procedural Watch Faces:** Real-time rendering of analog and digital clock interfaces directly on the microcontroller.
*   **Interactive Haptics & Emotes:** Utilizes a capacitive touch sensor to trigger state-based pixel-art expressions.
*   **Live Camera Streaming:** Streams visual data from the iPhone camera to the 1-bit OLED via a custom UDP/BLE pipeline.
*   **Native iOS Dashboard:** A custom-built SwiftUI companion app for mode management, time synchronization, and battery monitoring.

---

## Hardware Architecture

The hardware footprint is highly optimized for thickness and power efficiency, designed to seamlessly integrate into a custom 3D-printed phone case form factor.

*   **Microcontroller:** ESP32 (Manages BLE stack, display rendering, and touch interrupts)
*   **Display:** 128x64 Monochromatic OLED (SH1106/SSD1306) via I2C
*   **Sensor:** TTP223 Capacitive Touch Module
*   **Power System:** Li-Po battery with integrated custom charging circuitry

### Hardware Repository
All PCB designs, schematics, and mechanical files are open-source and available for review:
*   [Schematic Documentation (Image)](assets/schematic.png)
*   [Bill of Materials (BOM)]([add_your_BOM_file_here.csv])
*   [Gerber Manufacturing Files](hardware/gerber/)
*   [3D Enclosure Models (STL/STEP)](hardware/3d_models/)

---

## Software Stack

The project relies on a strictly partitioned architecture between the embedded system and the mobile client:

1.  **Embedded Firmware (C++ / ESP32):** 
    *   Developed within the PlatformIO environment.
    *   Leverages the `U8g2` library for highly optimized, low-level procedural graphics rendering.
2.  **iOS Client (Swift / SwiftUI):**
    *   Built with a modern TabBar architecture adhering to a strict monochromatic design language.
    *   Utilizes `XcodeGen` for dynamic `.xcodeproj` generation, ensuring clean version control and CI/CD compatibility.
    *   Implements native custom `GifImageView` components for pixel-perfect 1-bit display previews.

---

## Getting Started

### Flashing the Firmware
1. Install [PlatformIO](https://platformio.org/).
2. Navigate to the project root directory.
3. Connect the OverByte hardware via USB.
4. Execute the build and upload command: `pio run -t upload`.

### Building the iOS Application
To avoid merge conflicts with Xcode project files, this repository uses `XcodeGen`.
1. Install XcodeGen: `brew install xcodegen`.
2. Navigate to the `ios` directory.
3. Generate the project: `xcodegen generate`.
4. Open the generated `OverByte.xcodeproj` and build the application to your target iOS device.

---

## Progress & Gallery

### 3D Enclosure Concept
| Front View | Tilt View | Back View |
| :---: | :---: | :---: |
| <img src="assets/front.png" width="250"> | <img src="assets/tilt.png" width="250"> | <img src="assets/back.png" width="250"> |

### Hardware Design
| Schematic | PCB Layout | 3D PCB Render |
| :---: | :---: | :---: |
| <img src="assets/schematic.png" width="250"> | <img src="assets/pcb.png" width="250"> | <img src="assets/pcb_3d.png" width="250"> |

## License
This project is licensed under the MIT License. See the `LICENSE` file for full details.
