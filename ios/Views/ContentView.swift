import SwiftUI
import WebKit

// MARK: - Navigation State

enum ActiveScreen {
    case home, faces, tiles, settings, tips, store
}

// MARK: - Active Preview Enum

enum ActivePreview: Equatable {
    case clock(Int)
    case emote(Int)
    case activity
}

// MARK: - Pixel Font Helper (used only on FacesView)

private let pixelFont = "PressStart2P-Regular"
private func pFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(pixelFont, size: size)
}

// MARK: - Color Palette

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
    @StateObject private var healthKit = HealthKitManager()

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
            case .tiles:    SimplePage(title: "TILES", icon: "square.grid.2x2", activeScreen: $activeScreen)
            case .settings: SettingsPage(activeScreen: $activeScreen)
            case .tips:     SimplePage(title: "USER GUIDE", icon: "lightbulb", activeScreen: $activeScreen)
            case .store:    SimplePage(title: "STORE", icon: "bag", activeScreen: $activeScreen)
            }
        }
        .onAppear {
            healthKit.requestAuthorization { _ in }
        }
    }
}

// MARK: - Home View (Modern styling as exactly the UI in the image)

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Logo ──────────────────────────────────────────────────────
                HStack(spacing: 0) {
                    Text("OVER")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    Text("B")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.red)
                    Text("YTE")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)
                .padding(.bottom, 8)

                // ── Status ────────────────────────────────────────────────────
                Text(
                    bleManager.isConnected
                        ? "Your case is connected."
                        : "Your case isn't connected to your phone."
                )
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                // ── Connect / Disconnect button ───────────────────────────────
                Button {
                    bleManager.isConnected ? bleManager.disconnect() : bleManager.startScanning()
                } label: {
                    Text(bleManager.isConnected ? "DISCONNECT" : "CONNECT")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red) // Connect button red color
                        .cornerRadius(28)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 32)

                // ── Search row ────────────────────────────────────────────────
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // ── Primary Nav Card (FACES | TILES) ───────────────────────────
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        // Faces Button
                        Button {
                            activeScreen = .faces
                        } label: {
                            VStack(spacing: 12) {
                                ModernRobotIcon()
                                Text("FACES")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }

                        // Vertical Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 80)

                        // Tiles Button
                        Button {
                            activeScreen = .tiles
                        } label: {
                            VStack(spacing: 12) {
                                ModernGridIcon()
                                Text("TILES")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        }
                    }
                }
                .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // ── Secondary Nav Card (Settings / Tips / Store) ───────────────
                VStack(spacing: 0) {
                    // Settings row
                    HomeNavListRow(
                        icon: AnyView(ModernSettingIcon()),
                        title: "SETTING",
                        subtitle: "Notifications • Display • Health"
                    ) {
                        activeScreen = .settings
                    }

                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.leading, 70)

                    // Tips row
                    HomeNavListRow(
                        icon: AnyView(ModernTipsIcon()),
                        title: "TIPS AND USER GUIDE"
                    ) {
                        activeScreen = .tips
                    }

                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.leading, 70)

                    // Store row
                    HomeNavListRow(
                        icon: AnyView(ModernStoreIcon()),
                        title: "STORE"
                    ) {
                        activeScreen = .store
                    }
                }
                .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                .cornerRadius(24)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)

                // ── Bottom branding badge ──────────────────────────────────────
                HStack {
                    Spacer()
                    ModernBrandBadge()
                    Spacer()
                }
                .padding(.bottom, 32)
            }
        }
        .background(pixelBlack)
    }
}

// MARK: - Home Navigation Row Helper

struct HomeNavListRow: View {
    let icon: AnyView
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                icon
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Faces View (8-bit scroll layout)

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmoteIndex: Int
    @ObservedObject var healthKit: HealthKitManager

    // Active preview state
    @State private var activePreview: ActivePreview = .clock(0)

    private let clockFaces: [(label: String, style: Int)] = [
        ("BIG DIGITAL", 0),
        ("DIGITAL DATE", 1),
        ("ANALOG",       2),
    ]

    private let emoteFaces: [(label: String, gif: String)] = [
        ("IDLE",    "default"),
        ("WHAT",    "what"),
        ("JUDGING", "juding"),
        ("HAPPY",   "happy"),
        ("ANGRY",   "angry"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back Header
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
                VStack(spacing: 24) {

                    // 1. The Top OLED Preview Box
                    VStack(alignment: .center, spacing: 10) {
                        ZStack {
                            pixelBlack
                            switch activePreview {
                            case .clock(let style):
                                OLEDClockPreview(style: style)
                            case .emote(let index):
                                OLEDEmotePreview(gifName: emoteFaces[index].gif)
                            case .activity:
                                OLEDActivityPreview(healthKit: healthKit)
                            }
                        }
                        .frame(width: 200, height: 100) // 2:1 aspect ratio
                        .border(pixelWhite, width: 2)

                        PixelText(previewTitle, size: 8, color: pixelWhite)
                            .padding(.top, 4)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .border(pixelWhite, width: 2)
                    .padding(.horizontal, 16)

                    // 2. The Clock Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            PixelText("CLOCK", size: 8, color: pixelGray)
                            Spacer()
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
                                        activePreview = .clock(face.style)
                                        if bleManager.isConnected { bleManager.sendMode(0) }
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                pixelBlack
                                                OLEDClockPreview(style: face.style)
                                            }
                                            .frame(width: 110, height: 90)
                                            .border(
                                                selectedClockStyle == face.style ? pixelRed : pixelWhite.opacity(0.25),
                                                width: selectedClockStyle == face.style ? 2 : 1
                                            )
                                            PixelText(face.label, size: 6, color: selectedClockStyle == face.style ? pixelRed : pixelGray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .border(pixelWhite, width: 2)
                    .padding(.horizontal, 16)

                    // 3. The Emote Section
                    VStack(alignment: .leading, spacing: 12) {
                        PixelText("EMOTE", size: 8, color: pixelGray)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(emoteFaces.enumerated()), id: \.offset) { idx, face in
                                    Button {
                                        selectedEmoteIndex = idx
                                        activePreview = .emote(idx)
                                        if bleManager.isConnected { bleManager.sendMode(1) }
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                pixelBlack
                                                GifImageView(name: face.gif)
                                                    .frame(width: 90, height: 75)
                                                    .clipped()
                                            }
                                            .frame(width: 100, height: 80)
                                            .border(
                                                selectedEmoteIndex == idx ? pixelRed : pixelWhite.opacity(0.25),
                                                width: selectedEmoteIndex == idx ? 2 : 1
                                            )
                                            PixelText(face.label, size: 6, color: selectedEmoteIndex == idx ? pixelRed : pixelGray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .border(pixelWhite, width: 2)
                    .padding(.horizontal, 16)

                    // 4. The Activity Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            PixelText("ACTIVITY", size: 8, color: pixelGray)
                            Spacer()
                            Button {
                                healthKit.fetchAllMetrics()
                                activePreview = .activity
                                if bleManager.isConnected {
                                    bleManager.sendMode(2) // Mode 2 is activity on C++ firmware
                                }
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
                                    .background(pixelRed)
                            }
                        }

                        VStack(spacing: 0) {
                            ActivityRow(icon: "figure.walk", label: "STEPS", value: "\(healthKit.stepCount)", unit: "STEPS", accent: pixelBlue)
                            PixelDivider(axis: .horizontal)
                            ActivityRow(icon: "heart.fill", label: "HEART RATE", value: "\(healthKit.heartRate)", unit: "BPM", accent: pixelRed)
                            PixelDivider(axis: .horizontal)
                            ActivityRow(icon: "flame.fill", label: "CALORIES", value: "\(healthKit.activeCalories)", unit: "KCAL", accent: pixelRed)
                            PixelDivider(axis: .horizontal)
                            ActivityRow(icon: "battery.100", label: "BATTERY", value: "\(bleManager.batteryLevel)%", unit: "CASE", accent: pixelBlue)
                        }
                        .border(pixelWhite.opacity(0.3), width: 1)
                    }
                    .padding(14)
                    .border(pixelWhite, width: 2)
                    .padding(.horizontal, 16)

                    // Bottom branding badge
                    HStack {
                        Spacer()
                        ModernBrandBadge()
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(pixelBlack)
    }

    // MARK: - Preview Titles

    private var previewTitle: String {
        switch activePreview {
        case .clock(let style):
            return clockFaces[style].label
        case .emote(let index):
            return emoteFaces[index].label.uppercased() + " EMOTE"
        case .activity:
            return "ACTIVITY FACE"
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

// MARK: - Settings Page

struct SettingsPage: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @State private var notificationsOn = true
    @State private var brightness: Double = 0.8
    @State private var healthSyncOn = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Standard back navigation
            Button {
                activeScreen = .home
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("SETTINGS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 56)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        // Notifications
                        HStack {
                            Text("NOTIFICATIONS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $notificationsOn)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                .labelsHidden()
                        }
                        .padding(16)
                        Divider()

                        // Brightness
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("BRIGHTNESS")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(brightness * 100))%")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            Slider(value: $brightness).accentColor(.red)
                        }
                        .padding(16)
                        Divider()

                        // Health Sync
                        HStack {
                            Text("HEALTH SYNC")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $healthSyncOn)
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                                .labelsHidden()
                        }
                        .padding(16)
                    }
                    .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                    .cornerRadius(24)
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
            Button {
                activeScreen = .home
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 56)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
            Text("COMING SOON")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
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

    @ViewBuilder private var digitalDate: some View {
        VStack(spacing: 6) {
            PixelText(fmt("HH:mm:ss"), size: 12, color: pixelWhite)
            PixelText(fmt("EEEE, MMM dd"), size: 6, color: pixelWhite)
        }
    }

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

// MARK: - Pixel Analog Dial (Bresenham grid)

struct PixelAnalogDial: View {
    let date: Date
    let size: CGFloat

    private let G = 32

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

    private func colorFor(_ v: Int) -> Color {
        switch v {
        case 1: return pixelWhite
        case 2: return pixelRed // Replaced blue with red
        default: return pixelBlack
        }
    }

    private func buildGrid() -> [[Int]] {
        var g = Array(repeating: Array(repeating: 0, count: G), count: G)
        let cx = G / 2, cy = G / 2
        let R  = G / 2 - 2

        for row in 0..<G {
            for col in 0..<G {
                let dx = col - cx, dy = row - cy
                let d2 = dx*dx + dy*dy
                if d2 >= (R-1)*(R-1) && d2 <= R*R { g[row][col] = 1 }
            }
        }

        let ticks: [(Int,Int)] = [
            (cx, cy - R + 1), (cx, cy - R + 2),
            (cx, cy + R - 1), (cx, cy + R - 2),
            (cx - R + 1, cy), (cx - R + 2, cy),
            (cx + R - 1, cy), (cx + R - 2, cy),
        ]
        for (col, row) in ticks where row >= 0 && row < G && col >= 0 && col < G {
            g[row][col] = 1
        }

        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = Double(comps.hour   ?? 0)
        let m = Double(comps.minute ?? 0)
        let s = Double(comps.second ?? 0)

        let hourDeg   = (h.truncatingRemainder(dividingBy: 12)) * 30 + m * 0.5 - 90
        let minuteDeg = m * 6 + s * 0.1 - 90
        let secondDeg = s * 6 - 90

        drawHand(on: &g, cx: cx, cy: cy, deg: hourDeg,   len: Int(Double(R) * 0.50), color: 1)
        drawHand(on: &g, cx: cx, cy: cy, deg: minuteDeg, len: Int(Double(R) * 0.72), color: 1)
        drawHand(on: &g, cx: cx, cy: cy, deg: secondDeg, len: Int(Double(R) * 0.82), color: 2)

        for dr in 0..<2 { for dc in 0..<2 {
            let r = cy+dr, c = cx+dc
            if r < G && c < G { g[r][c] = 1 }
        }}

        return g
    }

    private func drawHand(on grid: inout [[Int]], cx: Int, cy: Int, deg: Double, len: Int, color: Int) {
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

// MARK: - OLED Emote Preview

struct OLEDEmotePreview: View {
    let gifName: String
    var body: some View {
        GifImageView(name: gifName)
            .frame(width: 128, height: 128)
            .clipped()
    }
}

// MARK: - OLED Activity Preview

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

// MARK: - GIF Web View

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

struct PixelBorderBox<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.background(pixelBlack).border(pixelWhite, width: 2)
    }
}

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

// MARK: - Modern Vector Icons for Home Screen

struct ModernRobotIcon: View {
    var body: some View {
        VStack(spacing: 2) {
            // Antenna with red dot
            ZStack {
                Rectangle().fill(Color.red).frame(width: 4, height: 4)
                    .offset(y: -4)
                Rectangle().fill(Color.white).frame(width: 2, height: 6)
            }
            // Head
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 36, height: 26)
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 42, height: 42)
    }
}

struct ModernGridIcon: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2).stroke(Color.white, lineWidth: 2).frame(width: 14, height: 14)
                RoundedRectangle(cornerRadius: 2).stroke(Color.white, lineWidth: 2).frame(width: 14, height: 14)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 2).stroke(Color.white, lineWidth: 2).frame(width: 14, height: 14)
                RoundedRectangle(cornerRadius: 2).stroke(Color.white, lineWidth: 2).frame(width: 14, height: 14)
            }
        }
        .frame(width: 42, height: 42)
    }
}

struct ModernSettingIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 38, height: 38)
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            Circle()
                .fill(Color.red)
                .frame(width: 5, height: 5)
        }
    }
}

struct ModernTipsIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 38, height: 38)
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 6, height: 3)
                    .padding(.bottom, 10)
            }
        }
    }
}

struct ModernStoreIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 38, height: 38)
            Image(systemName: "bag.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            Image(systemName: "bag")
                .font(.system(size: 18))
                .foregroundColor(.red)
        }
    }
}

struct ModernBrandBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
                .frame(width: 52, height: 52)
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    Rectangle().fill(Color.red).frame(width: 9, height: 9)
                    Rectangle().fill(Color.red).frame(width: 9, height: 9)
                }
                HStack(spacing: 3) {
                    Rectangle().fill(Color.red).frame(width: 9, height: 9)
                    Rectangle().fill(Color.red).frame(width: 9, height: 9)
                }
            }
        }
    }
}
