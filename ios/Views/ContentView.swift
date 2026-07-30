import SwiftUI
import WebKit

// MARK: - Navigation State

enum ActiveScreen {
    case home, faces, tiles, settings, tips, store
}

enum ActivePreview: Equatable {
    case clock(Int)
    case emote(Int)
}

// MARK: - Pixel Font Helper

private let pixelFont = "PressStart2P-Regular"
private func pFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    .custom(pixelFont, size: size)
}

// MARK: - Color Palette (Glyph Dark High-Contrast Aesthetic)

private let glyphBg        = Color.black
private let glyphCardBg    = Color(white: 0.07)
private let glyphTextMuted = Color(white: 0.5)
private let glyphTextActive = Color.white
private let glyphAccent    = Color.red

// MARK: - ContentView Root

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var activeScreen: ActiveScreen = .home
    @State private var selectedClockStyle: Int = 0   // 0=Big Digital, 1=Digital Date, 2=Analog
    @State private var selectedEmoteIndex: Int = 0

    var body: some View {
        ZStack {
            glyphBg.ignoresSafeArea()

            switch activeScreen {
            case .home:
                HomeView(activeScreen: $activeScreen)
            case .faces:
                FacesView(
                    activeScreen: $activeScreen,
                    selectedClockStyle: $selectedClockStyle,
                    selectedEmoteIndex: $selectedEmoteIndex
                )
            case .tiles:    TilesView(activeScreen: $activeScreen)
            case .settings: SettingsPage(activeScreen: $activeScreen)
            case .tips:     SimplePage(title: "USER GUIDE", icon: "lightbulb", activeScreen: $activeScreen)
            case .store:    SimplePage(title: "STORE", icon: "bag", activeScreen: $activeScreen)
            }
        }
    }
}

// MARK: - Home View (Glyph Minimal Styling - Scaled Up)

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Logo (Scale: 18 -> 26) ──────────────────────────────────
                HStack(spacing: 0) {
                    PixelText("OVER", size: 26, color: glyphTextActive)
                    PixelText("B",    size: 26, color: glyphAccent)
                    PixelText("YTE",  size: 26, color: glyphTextActive)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24) // Removed massive top padding (Safe Area handles top naturally)
                .padding(.bottom, 12)

                // ── Status ──────────────────────────────────────────────────
                PixelText(
                    bleManager.isConnected
                        ? "Your case is connected."
                        : "Your case isn't connected to your phone.",
                    size: 9,
                    color: glyphTextMuted
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // ── Battery Level (visible when connected) ────────────────────
                if bleManager.isConnected {
                    PixelText("CASE BATTERY: \(bleManager.batteryLevel)%", size: 8, color: glyphTextMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 16)
                }

                // ── Connect / Disconnect button ──────────────────────────────
                Button {
                    bleManager.isConnected ? bleManager.disconnect() : bleManager.startScanning()
                } label: {
                    HStack(spacing: 16) {
                        Circle()
                            .stroke(glyphTextActive, lineWidth: 2)
                            .background(bleManager.isConnected ? Circle().fill(glyphAccent) : nil)
                            .frame(width: 14, height: 14)

                        PixelText(
                            bleManager.isConnected ? "DISCONNECT" : "CONNECT",
                            size: 12,
                            color: glyphTextActive
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(glyphTextActive, lineWidth: 2)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 48)
                .padding(.bottom, 36)

                // ── Section Title: WIDGETS (Scale: 6 -> 9)
                PixelText("WIDGETS", size: 9, color: glyphTextMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                // ── Primary Nav Widget Cells (FACES | TILES - Double Icon Size) 
                HStack(spacing: 16) {
                    Button {
                        activeScreen = .faces
                    } label: {
                        VStack(spacing: 16) {
                            PrimaryIconContainer(name: "icon_faces", isRobot: true)
                                .frame(width: 80, height: 80) // Doubled size
                            PixelText("FACES", size: 9, color: glyphTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }

                    Button {
                        activeScreen = .tiles
                    } label: {
                        VStack(spacing: 16) {
                            PrimaryIconContainer(name: "icon_tiles", isRobot: false)
                                .frame(width: 80, height: 80) // Doubled size
                            PixelText("TILES", size: 9, color: glyphTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)

                // ── Section Title: SETTINGS (Scale: 6 -> 9)
                PixelText("SETTINGS", size: 9, color: glyphTextMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                // ── Secondary Nav Rows (Enlarged CustomIconContainer circle sizes)
                VStack(spacing: 10) {
                    HomeNavListRow(
                        iconName: "icon_setting",
                        fallbackSymbol: "gearshape.fill",
                        title: "SETTING",
                        subtitle: "Notifications • Display • Health"
                    ) {
                        activeScreen = .settings
                    }
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                    HomeNavListRow(
                        iconName: "icon_tips",
                        fallbackSymbol: "lightbulb.fill",
                        title: "TIPS AND USER GUIDE"
                    ) {
                        activeScreen = .tips
                    }
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                    HomeNavListRow(
                        iconName: "icon_store",
                        fallbackSymbol: "bag.fill",
                        title: "STORE"
                    ) {
                        activeScreen = .store
                    }
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(glyphBg)
    }
}

// MARK: - Home Navigation Row Helper (Scaled Up)

struct HomeNavListRow: View {
    let iconName: String          // Asset catalog name
    let fallbackSymbol: String    // SF Symbol fallback
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                // Flat icon — no grey circle, just the image itself
                Group {
                    if let uiImg = UIImage(named: iconName) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: fallbackSymbol)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(glyphTextMuted)
                    }
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(pFont(9))
                        .foregroundColor(glyphTextActive)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let sub = subtitle {
                        Text(sub)
                            .font(pFont(7))
                            .foregroundColor(glyphTextMuted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Faces View (Premium Scrollable Watch Face Layout - Scaled Up)

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmoteIndex: Int

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
            // Back Header (Removed top 56 padding)
            HStack {
                Button {
                    activeScreen = .home
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(glyphTextActive)
                        PixelText("FACES", size: 14, color: glyphTextActive) // 9 -> 14
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16) // Substituted with a safe top margin
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // 1. Section: PREVIEW (Centered full-width layout)
                    VStack(alignment: .leading, spacing: 10) {
                        PixelText("PREVIEW", size: 9, color: glyphTextMuted) // 6 -> 9
                            .padding(.horizontal, 4)

                        // Full-width rectangular preview container
                        ZStack {
                            glyphCardBg
                                .cornerRadius(8)

                            ZStack {
                                switch activePreview {
                                case .clock(let style):
                                    OLEDClockPreview(style: style)
                                case .emote(let index):
                                    OLEDEmotePreview(gifName: emoteFaces[index].gif)
                                }
                            }
                            .scaleEffect(1.3) // Perfectly centered and enlarged content
                        }
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        )

                        // Selected watch face title & details positioned directly below the box
                        VStack(alignment: .leading, spacing: 6) {
                            PixelText(previewTitle, size: 12, color: glyphTextActive) // 8 -> 12
                            PixelText(previewAttributes, size: 9, color: glyphTextMuted) // 6 -> 9
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 16)

                    // 2. Section: CLOCK (Enlarged select items & buttons)
                    VStack(alignment: .leading, spacing: 10) {
                        PixelText("CLOCK", size: 9, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                PixelText("CLOCK WIDGETS", size: 9, color: glyphTextActive)
                                Spacer()
                                Button {
                                    bleManager.syncTime()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                        PixelText("SYNC TIME", size: 8, color: .black) // 5 -> 8
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(glyphTextActive)
                                    .cornerRadius(6)
                                }
                                .disabled(!bleManager.isConnected)
                                .opacity(bleManager.isConnected ? 1.0 : 0.4)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) { // Increased spacing
                                    ForEach(clockFaces, id: \.style) { face in
                                        Button {
                                            selectedClockStyle = face.style
                                            activePreview = .clock(face.style)
                                            if bleManager.isConnected {
                                                bleManager.sendMode(0)
                                                bleManager.sendClockStyle(style: face.style)
                                            }
                                        } label: {
                                            VStack(spacing: 10) {
                                                // Enlarged option box (80 -> 120)
                                                ZStack {
                                                    glyphBg
                                                        .cornerRadius(8)
                                                    
                                                    OLEDClockPreview(style: face.style)
                                                        .frame(width: 96, height: 48) // Enlarged layout
                                                        .clipped()
                                                }
                                                .frame(width: 120, height: 120)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedClockStyle == face.style ? glyphTextActive : Color.clear, lineWidth: 2)
                                                )
                                                
                                                VStack(spacing: 6) {
                                                    PixelText(face.label, size: 8, color: selectedClockStyle == face.style ? glyphTextActive : glyphTextMuted)
                                                    if selectedClockStyle == face.style {
                                                        Circle()
                                                            .fill(glyphAccent)
                                                            .frame(width: 6, height: 6) // Enlarged accent dot
                                                    } else {
                                                        Spacer().frame(height: 6)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(18)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 3. Section: EMOTE
                    VStack(alignment: .leading, spacing: 10) {
                        PixelText("EMOTE", size: 9, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 20) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) { // Increased spacing
                                    ForEach(Array(emoteFaces.enumerated()), id: \.offset) { idx, face in
                                        Button {
                                            selectedEmoteIndex = idx
                                            activePreview = .emote(idx)
                                            if bleManager.isConnected { bleManager.sendMode(1) }
                                        } label: {
                                            VStack(spacing: 10) {
                                                // Enlarged emote option box (80 -> 120)
                                                ZStack {
                                                    glyphBg
                                                        .cornerRadius(8)

                                                    GifImageView(name: face.gif)
                                                        .frame(width: 90, height: 90) // Doubled layout
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .frame(width: 120, height: 120)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedEmoteIndex == idx ? glyphTextActive : Color.clear, lineWidth: 2)
                                                )

                                                VStack(spacing: 6) {
                                                    PixelText(face.label, size: 8, color: selectedEmoteIndex == idx ? glyphTextActive : glyphTextMuted)
                                                    if selectedEmoteIndex == idx {
                                                        Circle()
                                                            .fill(glyphAccent)
                                                            .frame(width: 6, height: 6)
                                                    } else {
                                                        Spacer().frame(height: 6)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(18)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(glyphBg)
    }

    // MARK: - Helper getters

    private var previewTitle: String {
        switch activePreview {
        case .clock(let style):
            return clockFaces[style].label
        case .emote(let index):
            return emoteFaces[index].label.uppercased() + " EMOTE"
        }
    }

    private var previewAttributes: String {
        switch activePreview {
        case .clock(let style):
            if style == 0 {
                return "Digital  Seconds  Status"
            } else if style == 1 {
                return "Time  Weekday  Date"
            } else {
                return "Dial  Hands  Digital"
            }
        case .emote:
            return "GIF  Animated  Mochi"
        }
    }
}

// MARK: - Settings Page (Scaled Up)

struct SettingsPage: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @State private var notificationsOn = true
    @State private var brightness: Double = 0.8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                activeScreen = .home
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(glyphTextActive)
                    PixelText("SETTINGS", size: 12, color: glyphTextActive) // 8 -> 12
                }
            }
            .padding(.top, 16) // Removed top 56 padding
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        // Notifications
                        HStack {
                            PixelText("NOTIFICATIONS", size: 10, color: glyphTextActive) // 7 -> 10
                            Spacer()
                            Toggle("", isOn: $notificationsOn)
                                .toggleStyle(SwitchToggleStyle(tint: glyphAccent))
                                .labelsHidden()
                        }
                        .padding(18)
                        Divider().background(Color.white.opacity(0.05))

                        // Brightness
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                PixelText("BRIGHTNESS", size: 10, color: glyphTextActive) // 7 -> 10
                                Spacer()
                                PixelText("\(Int(brightness * 100))%", size: 8, color: glyphTextMuted) // 6 -> 8
                            }
                            Slider(value: $brightness).accentColor(glyphAccent)
                        }
                        .padding(18)
                    }
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(glyphBg)
    }
}

// MARK: - Generic Simple Page (Scaled Up)

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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(glyphTextActive)
                    PixelText(title, size: 12, color: glyphTextActive) // 8 -> 12
                }
            }
            .padding(.top, 16) // Removed top 56 padding
            .padding(.horizontal, 16)
            .padding(.bottom, 24)

            Spacer()
            Image(systemName: icon)
                .font(.system(size: 80)) // Enlarged
                .foregroundColor(glyphTextMuted)
                .frame(maxWidth: .infinity)
            PixelText("COMING SOON", size: 12, color: glyphTextMuted) // 8 -> 12
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
            Spacer()
        }
        .background(glyphBg)
    }
}

// MARK: - OLED Clock Preview (replicating u8g2 rendering)

struct OLEDClockPreview: View {
    let style: Int   // 0 = BIG_DIGITAL, 1 = DIGITAL_DATE, 2 = ANALOG
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            glyphBg
            switch style {
            case 0: bigDigital
            case 1: digitalDate
            default: analogFace
            }
        }
        .onReceive(timer) { now = $0 }
    }

    @ViewBuilder private var bigDigital: some View {
        PixelText(fmt("HH:mm"), size: 22, color: glyphTextActive)
    }

    @ViewBuilder private var digitalDate: some View {
        VStack(spacing: 6) {
            PixelText(fmt("HH:mm:ss"), size: 12, color: glyphTextActive)
            PixelText(fmt("EEEE, MMM dd"), size: 6, color: glyphTextActive)
        }
    }

    @ViewBuilder private var analogFace: some View {
        HStack(spacing: 10) {
            PixelAnalogDial(date: now, size: 90)
            VStack(alignment: .leading, spacing: 4) {
                PixelText(fmt("HH:mm"), size: 10, color: glyphTextActive)
                PixelText(fmt(":ss"),   size: 7,  color: glyphTextMuted)
                PixelText(fmt("dd/MM"), size: 7,  color: glyphTextActive)
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
        case 1: return glyphTextActive
        case 2: return glyphAccent
        default: return glyphBg
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


// MARK: - GIF Web View

struct GifImageView: View {
    let name: String
    var body: some View {
        if Bundle.main.url(forResource: name, withExtension: "gif") != nil {
            _WKGifView(gifName: name)
        } else {
            ZStack {
                glyphBg
                PixelText("NO GIF", size: 6, color: glyphTextMuted)
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
        content.background(glyphBg).border(glyphTextActive, width: 2)
    }
}

struct PixelDivider: View {
    enum Axis { case horizontal, vertical }
    let axis: Axis
    var body: some View {
        Rectangle().fill(glyphTextMuted.opacity(0.25))
            .frame(
                width:  axis == .horizontal ? nil : 1.5,
                height: axis == .horizontal ? 1.5 : nil
            )
    }
}

// MARK: - Modern Vector Icons for Home Screen (Doubled in Size)

struct ModernRobotIcon: View {
    var body: some View {
        VStack(spacing: 4) {
            // Antenna with red dot
            ZStack {
                Rectangle().fill(Color.red).frame(width: 8, height: 8)
                    .offset(y: -8)
                Rectangle().fill(Color(white: 0.5)).frame(width: 4, height: 12)
            }
            // Head (Doubled dimensions)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.5), lineWidth: 4)
                    .frame(width: 64, height: 48)
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.5))
                        .frame(width: 10, height: 10)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.5))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(width: 80, height: 80)
    }
}

struct ModernGridIcon: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3).stroke(Color(white: 0.5), lineWidth: 3).frame(width: 24, height: 24)
                RoundedRectangle(cornerRadius: 3).stroke(Color(white: 0.5), lineWidth: 3).frame(width: 24, height: 24)
            }
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3).stroke(Color(white: 0.5), lineWidth: 3).frame(width: 24, height: 24)
                RoundedRectangle(cornerRadius: 3).stroke(Color(white: 0.5), lineWidth: 3).frame(width: 24, height: 24)
            }
        }
        .frame(width: 80, height: 80)
    }
}

// MARK: - Custom Icon Container (loads bundle assets or falls back to system designs - Doubled)

struct CustomIconContainer: View {
    let name: String
    let fallbackSymbol: String
    let fallbackAccentColor: Color
    var fallbackAccentBottom: Bool = false
    var fallbackIsBag: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.12))
                .frame(width: 64, height: 64) // Increased from 56 to 64
            
            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40) // Increased to at least 40x40
            } else {
                // Fallback to vector/SF Symbol
                if fallbackIsBag {
                    ZStack {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 28)) // Increased to at least 24
                            .foregroundColor(glyphTextMuted)
                        Image(systemName: "bag")
                            .font(.system(size: 28))
                            .foregroundColor(fallbackAccentColor)
                    }
                } else {
                    ZStack {
                        Image(systemName: fallbackSymbol)
                            .font(.system(size: 28)) // Increased to at least 24
                            .foregroundColor(glyphTextMuted)
                        
                        if fallbackAccentBottom {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(fallbackAccentColor)
                                    .frame(width: 10, height: 5)
                                    .padding(.bottom, 18)
                            }
                        } else {
                            Circle()
                                .fill(fallbackAccentColor)
                                .frame(width: 9, height: 9)
                        }
                    }
                }
            }
        }
        .frame(width: 64, height: 64)
    }
}

// MARK: - Primary Navigation Icon Container (Doubled)

struct PrimaryIconContainer: View {
    let name: String
    let isRobot: Bool

    var body: some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80) // Doubled from 38/42 to 80
        } else {
            if isRobot {
                ModernRobotIcon()
            } else {
                ModernGridIcon()
            }
        }
    }
}
