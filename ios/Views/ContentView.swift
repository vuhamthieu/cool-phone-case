import SwiftUI
import WebKit
import AVFoundation

// MARK: - Navigation State

enum ActiveScreen {
    case home, faces, videoStream, tiles, settings, tips, store
}

// MARK: - Pixel Font Helper

private let pixelFont = "PressStart2P-Regular"
private func pFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(pixelFont, size: size)
}

// MARK: - Pixel Colors

private let pixelBlue   = Color(red: 31/255, green: 105/255, blue: 255/255)
private let pixelRed    = Color.red
private let pixelWhite  = Color.white
private let pixelGray   = Color(white: 0.45)
private let pixelBlack  = Color.black

// MARK: - ContentView Root

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var activeScreen: ActiveScreen = .home
    @State private var selectedClockStyle: Int = 0   // 0=Big Digital, 1=Digital Date, 2=Analog
    @State private var selectedEmoteIndex: Int = 0

    @StateObject private var cameraManager = CameraManager()
    @StateObject private var udpStreamer   = UDPStreamer()
    @StateObject private var healthKit     = HealthKitManager()
    @State private var isCameraStreaming   = false

    var body: some View {
        ZStack {
            pixelBlack.ignoresSafeArea()

            switch activeScreen {
            case .home:
                HomeView(activeScreen: $activeScreen)
            case .faces:
                FacesView(
                    activeScreen: $activeScreen,
                    selectedClockStyle: $selectedClockStyle,
                    selectedEmoteIndex: $selectedEmoteIndex,
                    healthKit: healthKit
                )
            case .videoStream:
                CameraView(
                    activeScreen: $activeScreen,
                    isCameraStreaming: $isCameraStreaming,
                    cameraManager: cameraManager,
                    udpStreamer: udpStreamer
                )
            case .tiles:   SimplePage(title: "TILES",    icon: "square.grid.2x2", activeScreen: $activeScreen)
            case .settings: SettingsPage(activeScreen: $activeScreen)
            case .tips:    SimplePage(title: "USER GUIDE", icon: "lightbulb", activeScreen: $activeScreen)
            case .store:   SimplePage(title: "STORE",    icon: "bag",         activeScreen: $activeScreen)
            }
        }
        .onChange(of: isCameraStreaming) { on in
            if on {
                cameraManager.onFrameCaptured = { udpStreamer.streamFrame($0) }
                udpStreamer.start(); cameraManager.start()
            } else {
                cameraManager.stop(); udpStreamer.stop()
            }
        }
        .onAppear {
            healthKit.requestAuthorization { _ in }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Logo ──────────────────────────────────────────────────────
                HStack(spacing: 0) {
                    PixelText("OVER", size: 26, color: pixelWhite)
                    PixelText("B",    size: 26, color: pixelRed)
                    PixelText("YTE",  size: 26, color: pixelWhite)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 52)
                .padding(.bottom, 16)

                // ── Status ────────────────────────────────────────────────────
                PixelText(
                    bleManager.isConnected
                        ? "Your watch is connected."
                        : "Your watch isn't connected to your phone.",
                    size: 8,
                    color: pixelGray
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)

                // ── Connect / Disconnect button ───────────────────────────────
                Button {
                    bleManager.isConnected ? bleManager.disconnect() : bleManager.startScanning()
                } label: {
                    PixelText(
                        bleManager.isConnected ? "DISCONNECT" : "CONNECT",
                        size: 12,
                        color: pixelBlack
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(bleManager.isConnected ? pixelRed : pixelBlue)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 36)

                // ── Search row ────────────────────────────────────────────────
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(pixelWhite)
                        .font(.system(size: 22, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // ── Primary nav grid (FACES | VIDEO STREAM | TILES) ───────────
                PixelBorderBox {
                    HStack(spacing: 0) {
                        NavCell(icon: AnyView(RobotFaceIcon(size: 42)), label: "FACES") {
                            activeScreen = .faces
                        }
                        PixelDivider(axis: .vertical)
                        NavCell(icon: AnyView(CameraPixelIcon(size: 42)), label: "VIDEO STREAM") {
                            activeScreen = .videoStream
                        }
                        PixelDivider(axis: .vertical)
                        NavCell(icon: AnyView(GridPixelIcon(size: 42)), label: "TILES") {
                            activeScreen = .tiles
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

                // ── Secondary nav list (Settings / Tips / Store) ──────────────
                PixelBorderBox {
                    VStack(spacing: 0) {
                        ListNavRow(
                            icon: AnyView(GearPixelIcon()),
                            title: "SETTING",
                            subtitle: "NOTIFICATIONS • DISPLAY • HEALTH"
                        ) { activeScreen = .settings }
                        PixelDivider(axis: .horizontal)
                        ListNavRow(
                            icon: AnyView(BulbPixelIcon()),
                            title: "TIPS AND USER GUIDE"
                        ) { activeScreen = .tips }
                        PixelDivider(axis: .horizontal)
                        ListNavRow(
                            icon: AnyView(BagPixelIcon()),
                            title: "STORE"
                        ) { activeScreen = .store }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)

                // ── Bottom branding ───────────────────────────────────────────
                HStack {
                    Spacer()
                    BottomBrandBadge()
                    Spacer()
                }
                .padding(.bottom, 24)
            }
        }
        .background(pixelBlack)
    }
}

// MARK: - Faces View

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmoteIndex: Int
    @ObservedObject var healthKit: HealthKitManager

    // 0 = CLOCK, 1 = EMOTE, 2 = ACTIVITY
    @State private var faceCategory: Int = 0

    // Clock faces available on the ESP32 (mapped to display.cpp styles)
    private let clockFaces: [(label: String, style: Int)] = [
        ("BIG DIGITAL", 0),
        ("DIGITAL DATE", 1),
        ("ANALOG",       2),
    ]

    // Emote faces with associated GIF filenames
    private let emoteFaces: [(label: String, gif: String)] = [
        ("IDLE",    "default"),
        ("WHAT",    "what"),
        ("JUDGING", "juding"),
        ("HAPPY",   "happy"),
        ("ANGRY",   "angry"),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Back header ────────────────────────────────────────────────
            HStack {
                Button {
                    activeScreen = .home
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(pixelWhite)
                        PixelText("FACES", size: 14, color: pixelWhite)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ── OLED Preview section ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 16) {
                            // Left: live OLED render
                            ZStack {
                                pixelBlack
                                switch faceCategory {
                                case 0: OLEDClockPreview(style: selectedClockStyle)
                                case 1: OLEDEmotePreview(gifName: emoteFaces[selectedEmoteIndex].gif)
                                default: OLEDActivityPreview(healthKit: healthKit)
                                }
                            }
                            .frame(width: 148, height: 148)
                            .border(pixelWhite, width: 2)

                            // Right: title + info
                            VStack(alignment: .leading, spacing: 10) {
                                PixelText(selectedFaceTitle, size: 9, color: pixelWhite)
                                    .fixedSize(horizontal: false, vertical: true)
                                if faceCategory == 0 {
                                    PixelText("Clock Face", size: 7, color: pixelGray)
                                    PixelText("u8g2 render", size: 7, color: pixelGray)
                                } else if faceCategory == 1 {
                                    PixelText("Animated", size: 7, color: pixelGray)
                                    PixelText("GIF Emote", size: 7, color: pixelGray)
                                } else {
                                    PixelText("HealthKit", size: 7, color: pixelGray)
                                    PixelText("Activity", size: 7, color: pixelGray)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(pixelBlack)
                        .border(pixelWhite, width: 2)
                    }
                    .padding(.horizontal, 16)

                    // ── Category tabs ─────────────────────────────────────────
                    HStack(spacing: 0) {
                        ForEach(Array(["CLOCK","EMOTE","ACTIVITY"].enumerated()), id: \.offset) { idx, name in
                            Button {
                                withAnimation(.none) { faceCategory = idx }
                            } label: {
                                PixelText(name, size: 8, color: faceCategory == idx ? pixelBlack : pixelWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(faceCategory == idx ? pixelWhite : pixelBlack)
                            }
                            if idx < 2 {
                                Rectangle().fill(pixelWhite).frame(width: 2)
                            }
                        }
                    }
                    .border(pixelWhite, width: 2)
                    .padding(.horizontal, 16)

                    // ── Category content ──────────────────────────────────────
                    Group {
                        switch faceCategory {
                        case 0: clockSection
                        case 1: emoteSection
                        default: activitySection
                        }
                    }
                    .padding(.horizontal, 16)

                    // ── Bottom branding ───────────────────────────────────────
                    HStack {
                        Spacer()
                        BottomBrandBadge()
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
                .padding(.top, 4)
            }
        }
        .background(pixelBlack)
    }

    // MARK: - Section builders

    private var clockSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PixelText("CLOCK", size: 8, color: pixelGray)
                Spacer()
                // SYNC TIME button
                Button {
                    bleManager.syncTime()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 10, weight: .black))
                        PixelText("SYNC TIME", size: 6, color: pixelBlack)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(pixelWhite)
                }
                .disabled(!bleManager.isConnected)
                .opacity(bleManager.isConnected ? 1.0 : 0.4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(clockFaces, id: \.style) { face in
                        Button {
                            selectedClockStyle = face.style
                            if bleManager.isConnected { bleManager.sendMode(0) }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    pixelBlack
                                    OLEDClockPreview(style: face.style)
                                }
                                .frame(width: 110, height: 90)
                                .border(
                                    selectedClockStyle == face.style ? pixelBlue : pixelWhite.opacity(0.25),
                                    width: selectedClockStyle == face.style ? 2 : 1
                                )

                                PixelText(face.label, size: 6,
                                    color: selectedClockStyle == face.style ? pixelBlue : pixelGray)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .border(pixelWhite.opacity(0.2), width: 1)
    }

    private var emoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PixelText("EMOTE", size: 8, color: pixelGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(emoteFaces.enumerated()), id: \.offset) { idx, face in
                        Button {
                            selectedEmoteIndex = idx
                            if bleManager.isConnected { bleManager.sendMode(1) }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    pixelBlack
                                    // Render actual GIF inside the slot
                                    GifImageView(name: face.gif)
                                        .frame(width: 90, height: 75)
                                        .clipped()
                                }
                                .frame(width: 100, height: 80)
                                .border(
                                    selectedEmoteIndex == idx ? pixelBlue : pixelWhite.opacity(0.25),
                                    width: selectedEmoteIndex == idx ? 2 : 1
                                )

                                PixelText(face.label, size: 6,
                                    color: selectedEmoteIndex == idx ? pixelBlue : pixelGray)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .border(pixelWhite.opacity(0.2), width: 1)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PixelText("ACTIVITY", size: 8, color: pixelGray)
                Spacer()
                Button {
                    healthKit.fetchAllMetrics()
                    // After a short delay so queries return, push data over BLE
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        bleManager.sendActivityData(
                            steps:    UInt32(healthKit.stepCount),
                            bpm:      UInt16(healthKit.heartRate),
                            calories: UInt16(healthKit.activeCalories)
                        )
                    }
                } label: {
                    PixelText("SYNC TO OLED", size: 6, color: pixelBlack)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(pixelWhite)
                }
            }


            if !healthKit.isAuthorized {
                Button {
                    healthKit.requestAuthorization { _ in }
                } label: {
                    PixelText("GRANT HEALTHKIT ACCESS", size: 8, color: pixelBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pixelBlue)
                }
            }

            VStack(spacing: 0) {
                ActivityRow(icon: "figure.walk",    label: "STEPS",    value: "\(healthKit.stepCount)", unit: "STEPS", accent: pixelBlue)
                PixelDivider(axis: .horizontal)
                ActivityRow(icon: "heart.fill",     label: "HEART RATE", value: "\(healthKit.heartRate)", unit: "BPM", accent: pixelRed)
                PixelDivider(axis: .horizontal)
                ActivityRow(icon: "flame.fill",     label: "CALORIES", value: "\(healthKit.activeCalories)", unit: "KCAL", accent: pixelRed)
                PixelDivider(axis: .horizontal)
                ActivityRow(icon: "battery.100",    label: "BATTERY",  value: "\(bleManager.batteryLevel)%", unit: "CASE", accent: pixelBlue)
            }
            .border(pixelWhite.opacity(0.3), width: 1)
        }
        .padding(14)
        .border(pixelWhite.opacity(0.2), width: 1)
    }

    // MARK: - Helpers

    private var selectedFaceTitle: String {
        switch faceCategory {
        case 0: return clockFaces[selectedClockStyle].label
        case 1: return emoteFaces[selectedEmoteIndex].label.uppercased() + " EMOTE"
        default: return "ACTIVITY FACE"
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(accent)
                .frame(width: 28)

            PixelText(label, size: 7, color: pixelGray)

            Spacer()

            PixelText(value, size: 10, color: pixelWhite)
            PixelText(unit, size: 7, color: pixelGray)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }
}

// MARK: - Camera View (persistent stream)

struct CameraView: View {
    @Binding var activeScreen: ActiveScreen
    @Binding var isCameraStreaming: Bool
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var udpStreamer: UDPStreamer

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PixelBackHeader(title: "CAMERA STREAM") { activeScreen = .home }
                .padding(.top, 56)
                .padding(.horizontal, 16)

            ZStack {
                pixelBlack
                if isCameraStreaming {
                    CameraStreamView(cameraManager: cameraManager, udpStreamer: udpStreamer)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(pixelGray)
                        PixelText("STREAM OFF", size: 9, color: pixelGray)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .border(pixelWhite, width: 2)
            .padding(.horizontal, 16)

            Button {
                isCameraStreaming.toggle()
            } label: {
                PixelText(
                    isCameraStreaming ? "TURN OFF STREAM" : "TURN ON STREAM",
                    size: 10,
                    color: isCameraStreaming ? pixelBlack : pixelWhite
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isCameraStreaming ? pixelWhite : pixelBlack)
                .border(pixelWhite, width: 2)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(pixelBlack)
    }
}

// MARK: - Settings Page

struct SettingsPage: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @State private var notificationsOn = true
    @State private var brightness: Double = 0.8
    @State private var healthSyncOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PixelBackHeader(title: "SETTINGS") { activeScreen = .home }
                .padding(.top, 56)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PixelBorderBox {
                        VStack(spacing: 0) {
                            // Notifications
                            HStack {
                                PixelText("NOTIFICATIONS", size: 8, color: pixelWhite)
                                Spacer()
                                Toggle("", isOn: $notificationsOn)
                                    .toggleStyle(SwitchToggleStyle(tint: pixelBlue))
                                    .labelsHidden()
                            }
                            .padding(16)
                            PixelDivider(axis: .horizontal)

                            // Brightness
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    PixelText("BRIGHTNESS", size: 8, color: pixelWhite)
                                    Spacer()
                                    PixelText("\(Int(brightness * 100))%", size: 8, color: pixelGray)
                                }
                                Slider(value: $brightness).accentColor(pixelBlue)
                            }
                            .padding(16)
                            PixelDivider(axis: .horizontal)

                            // Health Sync
                            HStack {
                                PixelText("HEALTH SYNC", size: 8, color: pixelWhite)
                                Spacer()
                                Toggle("", isOn: $healthSyncOn)
                                    .toggleStyle(SwitchToggleStyle(tint: pixelBlue))
                                    .labelsHidden()
                            }
                            .padding(16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(pixelBlack)
    }
}

// MARK: - Generic Simple Page

struct SimplePage: View {
    let title: String
    let icon: String
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PixelBackHeader(title: title) { activeScreen = .home }
                .padding(.top, 56)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(pixelGray)
                .frame(maxWidth: .infinity)
            PixelText("COMING SOON", size: 10, color: pixelGray)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            Spacer()
        }
        .background(pixelBlack)
    }
}

// MARK: - OLED Clock Preview (replicating u8g2 rendering)

struct OLEDClockPreview: View {
    let style: Int   // 0 = BIG_DIGITAL, 1 = DIGITAL_DATE, 2 = ANALOG
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            pixelBlack
            switch style {
            case 0: bigDigital
            case 1: digitalDate
            default: analogFace
            }
        }
        .onReceive(timer) { now = $0 }
    }

    // CLOCK_BIG_DIGITAL — u8g2_font_logisoso28_tn style
    @ViewBuilder private var bigDigital: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                PixelText(fmt("HH:mm"), size: 22, color: pixelWhite)
                PixelText(fmt(":ss"),   size: 10, color: pixelWhite)
            }
            HStack {
                PixelText("BLE OK", size: 5, color: pixelGray)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }

    // CLOCK_DIGITAL_DATE — u8g2_font_ncenB14_tr style
    @ViewBuilder private var digitalDate: some View {
        VStack(spacing: 6) {
            PixelText(fmt("HH:mm:ss"), size: 12, color: pixelWhite)
            PixelText(fmt("EEEE, MMM dd"), size: 6, color: pixelWhite)
        }
    }

    // CLOCK_ANALOG — analog dial + digital readout
    @ViewBuilder private var analogFace: some View {
        HStack(spacing: 10) {
            PixelAnalogDial(date: now, size: 90)
            VStack(alignment: .leading, spacing: 4) {
                PixelText(fmt("HH:mm"), size: 10, color: pixelWhite)
                PixelText(fmt(":ss"),   size: 7,  color: pixelGray)
                PixelText(fmt("dd/MM"), size: 7,  color: pixelWhite)
            }
        }
    }

    private func fmt(_ format: String) -> String {
        let f = DateFormatter(); f.dateFormat = format
        return f.string(from: now)
    }
}

// MARK: - Pixel Analog Dial (Bresenham grid — zero rotationEffect, zero Circle)

/// Renders a 32×32 pixel grid where every cell is a hard Rectangle() block.
/// Clock border, tick marks, and all three hands are plotted with a
/// Bresenham integer line — genuinely blocky, no anti-aliasing possible.
struct PixelAnalogDial: View {
    let date: Date
    let size: CGFloat

    private let G = 32   // grid dimension

    var body: some View {
        let grid = buildGrid()
        let cell = size / CGFloat(G)

        VStack(spacing: 0) {
            ForEach(0..<G, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<G, id: \.self) { col in
                        Rectangle()
                            .fill(colorFor(grid[row][col]))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }

    // 0 = black   1 = white   2 = blue (second hand)
    private func colorFor(_ v: Int) -> Color {
        switch v {
        case 1: return pixelWhite
        case 2: return pixelBlue
        default: return pixelBlack
        }
    }

    private func buildGrid() -> [[Int]] {
        var g = Array(repeating: Array(repeating: 0, count: G), count: G)
        let cx = G / 2, cy = G / 2
        let R  = G / 2 - 2

        // 1. Circle border via integer distance check
        for row in 0..<G {
            for col in 0..<G {
                let dx = col - cx, dy = row - cy
                let d2 = dx*dx + dy*dy
                if d2 >= (R-1)*(R-1) && d2 <= R*R { g[row][col] = 1 }
            }
        }

        // 2. Cardinal tick marks (2-pixel deep at 12, 3, 6, 9)
        let ticks: [(Int,Int)] = [
            (cx, cy - R + 1), (cx, cy - R + 2),
            (cx, cy + R - 1), (cx, cy + R - 2),
            (cx - R + 1, cy), (cx - R + 2, cy),
            (cx + R - 1, cy), (cx + R - 2, cy),
        ]
        for (col, row) in ticks where row >= 0 && row < G && col >= 0 && col < G {
            g[row][col] = 1
        }

        // 3. Parse time
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = Double(comps.hour   ?? 0)
        let m = Double(comps.minute ?? 0)
        let s = Double(comps.second ?? 0)

        // 4. Draw hands with Bresenham
        let hourDeg   = (h.truncatingRemainder(dividingBy: 12)) * 30 + m * 0.5 - 90
        let minuteDeg = m * 6 + s * 0.1 - 90
        let secondDeg = s * 6 - 90

        drawHand(on: &g, cx: cx, cy: cy, deg: hourDeg,   len: Int(Double(R) * 0.50), color: 1)
        drawHand(on: &g, cx: cx, cy: cy, deg: minuteDeg, len: Int(Double(R) * 0.72), color: 1)
        drawHand(on: &g, cx: cx, cy: cy, deg: secondDeg, len: Int(Double(R) * 0.82), color: 2)

        // 5. Center dot (2x2)
        for dr in 0..<2 { for dc in 0..<2 {
            let r = cy+dr, c = cx+dc
            if r < G && c < G { g[r][c] = 1 }
        }}

        return g
    }

    private func drawHand(on grid: inout [[Int]],
                          cx: Int, cy: Int, deg: Double, len: Int, color: Int) {
        let rad = deg * .pi / 180.0
        let x1 = cx + Int((Double(len) * cos(rad)).rounded())
        let y1 = cy + Int((Double(len) * sin(rad)).rounded())
        for (col, row) in bresenham(x0: cx, y0: cy, x1: x1, y1: y1) {
            if row >= 0 && row < G && col >= 0 && col < G { grid[row][col] = color }
        }
    }

    private func bresenham(x0: Int, y0: Int, x1: Int, y1: Int) -> [(Int,Int)] {
        var pts: [(Int,Int)] = []
        var x = x0, y = y0
        let dx = abs(x1-x0), dy = abs(y1-y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        while true {
            pts.append((x, y))
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 > -dy { err -= dy; x += sx }
            if e2 <  dx { err += dx; y += sy }
        }
        return pts
    }
}


// MARK: - OLED Emote Preview (loops the GIF)

struct OLEDEmotePreview: View {
    let gifName: String

    var body: some View {
        GifImageView(name: gifName)
            .frame(width: 128, height: 128)
            .clipped()
    }
}

// MARK: - OLED Activity Preview (battery + steps + HR)

struct OLEDActivityPreview: View {
    @ObservedObject var healthKit: HealthKitManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            actRow(icon: "figure.walk", val: "\(healthKit.stepCount) STEPS",   color: pixelBlue)
            actRow(icon: "heart.fill",  val: "\(healthKit.heartRate) BPM",      color: pixelRed)
            actRow(icon: "flame.fill",  val: "\(healthKit.activeCalories) KCAL", color: pixelRed)
        }
        .padding(10)
    }

    @ViewBuilder
    private func actRow(icon: String, val: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
            PixelText(val, size: 6, color: pixelWhite)
        }
    }
}

// MARK: - GIF viewer using WKWebView

struct GifImageView: View {
    let name: String

    var body: some View {
        if Bundle.main.url(forResource: name, withExtension: "gif") != nil {
            _WKGifView(gifName: name)
        } else {
            ZStack {
                pixelBlack
                PixelText("NO GIF", size: 6, color: pixelGray)
            }
        }
    }
}

struct _WKGifView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.isUserInteractionEnabled = false
        wv.scrollView.isScrollEnabled = false
        wv.backgroundColor = .black
        wv.scrollView.backgroundColor = .black
        wv.isOpaque = false
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard let url = Bundle.main.url(forResource: gifName, withExtension: "gif") else { return }
        let html = """
        <!DOCTYPE html><html>
        <head><meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <style>html,body{margin:0;padding:0;width:100vw;height:100vh;background:#000;
        display:flex;justify-content:center;align-items:center;}
        img{width:100%;height:100%;object-fit:contain;image-rendering:pixelated;}</style>
        </head><body><img src='\(url.absoluteString)'></body></html>
        """
        uiView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }
}

// MARK: - Shared UI Primitives

/// Pixel-font text helper
struct PixelText: View {
    let text: String
    let size: CGFloat
    let color: Color
    init(_ text: String, size: CGFloat, color: Color = .white) {
        self.text = text; self.size = size; self.color = color
    }
    var body: some View {
        Text(text)
            .font(pFont(size))
            .foregroundColor(color)
    }
}

/// Pixel border box
struct PixelBorderBox<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.background(pixelBlack).border(pixelWhite, width: 2)
    }
}

/// 1-pixel hard divider
struct PixelDivider: View {
    enum Axis { case horizontal, vertical }
    let axis: Axis
    var body: some View {
        Rectangle().fill(pixelWhite.opacity(0.35))
            .frame(
                width:  axis == .horizontal ? nil : 2,
                height: axis == .horizontal ? 2   : nil
            )
    }
}

/// Back navigation header
struct PixelBackHeader: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(pixelWhite)
                PixelText(title, size: 12, color: pixelWhite)
            }
        }
    }
}

/// Nav cell for the 3-icon grid
struct NavCell: View {
    let icon: AnyView
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                icon
                PixelText(label, size: 6, color: pixelWhite)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
    }
}

/// Row in the secondary list
struct ListNavRow: View {
    let icon: AnyView
    let title: String
    var subtitle: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                icon
                VStack(alignment: .leading, spacing: 5) {
                    PixelText(title, size: 8, color: pixelWhite)
                    if let sub = subtitle {
                        PixelText(sub, size: 5, color: pixelGray)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Pixel Sprite primitive

/// Renders a pixel-map [[Int]] as a grid of hard Rectangle() blocks.
/// Values: 0 = black, 1 = white, 2 = red, 3 = blue
struct PixelSprite: View {
    let pixels: [[Int]]
    let pixelSize: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<pixels.count, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<pixels[row].count, id: \.self) { col in
                        Rectangle()
                            .fill(fill(pixels[row][col]))
                            .frame(width: pixelSize, height: pixelSize)
                    }
                }
            }
        }
    }

    private func fill(_ v: Int) -> Color {
        switch v {
        case 1: return pixelWhite
        case 2: return pixelRed
        case 3: return pixelBlue
        default: return pixelBlack
        }
    }
}

// MARK: - Pixel Art Icons (pure Rectangle grids — NO Circle, NO Path, NO rotationEffect)
// Values: 0=black  1=white  2=red  3=blue

// ── Robot Face (11 cols × 11 rows) ─────────────────────────────────────────
private let robotFacePixels: [[Int]] = [
    [0,0,0,0,0,2,0,0,0,0,0],  // red antenna tip
    [0,0,0,0,0,1,0,0,0,0,0],  // antenna stem
    [0,0,0,0,0,1,0,0,0,0,0],  // antenna stem
    [1,1,1,1,1,1,1,1,1,1,1],  // head top border
    [1,0,0,0,0,0,0,0,0,0,1],  // sides
    [1,0,1,1,0,0,1,1,0,0,1],  // left + right eye
    [1,0,1,1,0,0,1,1,0,0,1],  // eyes
    [1,0,0,0,0,0,0,0,0,0,1],  // blank
    [1,0,1,1,1,1,1,0,0,0,1],  // mouth bar
    [1,0,0,0,0,0,0,0,0,0,1],  // blank
    [1,1,1,1,1,1,1,1,1,1,1],  // head bottom border
]

struct RobotFaceIcon: View {
    let size: CGFloat
    var body: some View {
        PixelSprite(pixels: robotFacePixels,
                    pixelSize: size / CGFloat(robotFacePixels[0].count))
            .frame(width: size, height: size)
    }
}

// ── Camera (11 cols × 8 rows) ──────────────────────────────────────────────
// Body = bordered box with red dot; right = pixel trapezoid via stepped columns
private let cameraBodyPixels: [[Int]] = [
    [0,0,0,0,0,0,0,0,1,1,0],  // lens top step
    [1,1,1,1,1,1,1,0,1,1,1],  // body top + lens right
    [1,0,0,0,0,0,1,0,1,1,1],
    [1,0,0,2,0,0,1,0,1,1,1],  // red recording dot
    [1,0,0,0,0,0,1,0,1,1,1],
    [1,1,1,1,1,1,1,0,1,1,1],  // body bottom
    [0,0,0,0,0,0,0,0,1,1,0],  // lens bottom step
    [0,0,0,0,0,0,0,0,0,0,0],
]

struct CameraPixelIcon: View {
    let size: CGFloat
    var body: some View {
        PixelSprite(pixels: cameraBodyPixels,
                    pixelSize: size / CGFloat(cameraBodyPixels[0].count))
            .frame(width: size, height: size)
    }
}

// ── 2×2 Grid / Tiles (11 × 11) ─────────────────────────────────────────────
private let tilesPixels: [[Int]] = [
    [1,1,1,1,1,1,1,1,1,1,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,1,1,1,1,1,1,1,1,1,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,0,0,0,0,1,0,0,0,0,1],
    [1,1,1,1,1,1,1,1,1,1,1],
]

struct GridPixelIcon: View {
    let size: CGFloat
    var body: some View {
        PixelSprite(pixels: tilesPixels,
                    pixelSize: size / CGFloat(tilesPixels[0].count))
            .frame(width: size, height: size)
    }
}

// ── Gear / Settings (11 × 11) ──────────────────────────────────────────────
// 8-tooth gear approximated as pixel bumps on a thick ring; red center hub
private let gearPixels: [[Int]] = [
    [0,0,0,1,1,1,1,0,0,0,0],  // top teeth
    [0,1,1,1,1,1,1,1,1,0,0],
    [1,1,1,0,0,0,0,1,1,1,0],  // side arms
    [1,1,0,0,2,2,0,0,1,1,0],  // ring + red hub
    [1,1,0,2,2,2,2,0,1,1,0],
    [1,1,0,2,2,2,2,0,1,1,0],
    [1,1,0,0,2,2,0,0,1,1,0],
    [1,1,1,0,0,0,0,1,1,1,0],
    [0,1,1,1,1,1,1,1,1,0,0],
    [0,0,0,1,1,1,1,0,0,0,0],  // bottom teeth
    [0,0,0,0,0,0,0,0,0,0,0],
]

struct GearPixelIcon: View {
    var body: some View {
        PixelSprite(pixels: gearPixels, pixelSize: 3)
            .frame(width: 33, height: 33)
    }
}

// ── Lightbulb (9 cols × 12 rows) ───────────────────────────────────────────
private let bulbPixels: [[Int]] = [
    [0,0,1,1,1,1,1,0,0],  // top of bulb
    [0,1,1,0,0,0,1,1,0],
    [1,1,0,0,0,0,0,1,1],
    [1,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,1],
    [1,1,0,0,0,0,0,1,1],
    [0,1,1,1,1,1,1,1,0],  // base of bulb dome
    [0,0,1,1,1,1,1,0,0],  // collar
    [0,0,0,1,1,1,0,0,0],  // neck
    [0,0,2,2,2,2,2,0,0],  // red base
    [0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0],
]

struct BulbPixelIcon: View {
    var body: some View {
        PixelSprite(pixels: bulbPixels, pixelSize: 3)
            .frame(width: 27, height: 36)
    }
}

// ── Shopping Bag (9 cols × 11 rows) ────────────────────────────────────────
// Handle = red U-shape pixels; body = bordered rectangle
private let bagPixels: [[Int]] = [
    [0,0,2,2,0,2,2,0,0],  // handle top
    [0,0,2,0,0,0,2,0,0],  // handle sides
    [0,0,2,0,0,0,2,0,0],
    [1,1,1,1,1,1,1,1,1],  // bag top border
    [1,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,1],
    [1,0,0,0,0,0,0,0,1],
    [1,1,1,1,1,1,1,1,1],  // bag bottom border
    [0,0,0,0,0,0,0,0,0],
]

struct BagPixelIcon: View {
    var body: some View {
        PixelSprite(pixels: bagPixels, pixelSize: 3)
            .frame(width: 27, height: 33)
    }
}

// ── Bottom Brand Badge (13×13 pixel ring with blue 2×2 squares) ────────────
// Computed once at launch via a stored property closure
private let brandBadgePixels: [[Int]] = {
    let G = 13, cx = 6, cy = 6, R = 6
    var g = Array(repeating: Array(repeating: 0, count: G), count: G)
    // Pixel ring border
    for row in 0..<G { for col in 0..<G {
        let dx = col-cx, dy = row-cy, d = dx*dx + dy*dy
        if d >= (R-1)*(R-1) && d <= R*R { g[row][col] = 1 }
    }}
    // 4 blue squares (2×2 each) at the four quadrant centres
    for (r,c) in [(3,3),(3,8),(8,3),(8,8)] {
        g[r][c]=3; g[r][c+1]=3; g[r+1][c]=3; g[r+1][c+1]=3
    }
    return g
}()

struct BottomBrandBadge: View {
    var body: some View {
        PixelSprite(pixels: brandBadgePixels, pixelSize: 4)
            .frame(width: 52, height: 52)
    }
}
