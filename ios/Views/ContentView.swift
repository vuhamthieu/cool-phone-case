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
    @StateObject private var healthKit = HealthKitManager()

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

// MARK: - Home View (Glyph Minimal Styling)

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Logo ──────────────────────────────────────────────────────
                HStack(spacing: 0) {
                    PixelText("OVER", size: 18, color: glyphTextActive)
                    PixelText("B",    size: 18, color: glyphAccent)
                    PixelText("YTE",  size: 18, color: glyphTextActive)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 64)
                .padding(.bottom, 8)

                // ── Status ────────────────────────────────────────────────────
                PixelText(
                    bleManager.isConnected
                        ? "Your case is connected."
                        : "Your case isn't connected to your phone.",
                    size: 7,
                    color: glyphTextMuted
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                // ── Connect / Disconnect button (BACKGROUND button style) ──────
                Button {
                    bleManager.isConnected ? bleManager.disconnect() : bleManager.startScanning()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(glyphTextActive, lineWidth: 1.5)
                            .background(bleManager.isConnected ? Circle().fill(glyphAccent) : nil)
                            .frame(width: 10, height: 10)
                        
                        PixelText(
                            bleManager.isConnected ? "DISCONNECT" : "CONNECT",
                            size: 8,
                            color: glyphTextActive
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(glyphCardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(glyphTextActive, lineWidth: 1.5)
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 48)
                .padding(.bottom, 36)

                // ── Search row ────────────────────────────────────────────────
                HStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(glyphTextActive)
                        .font(.system(size: 20, weight: .bold))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // ── Section Title: WIDGETS
                PixelText("WIDGETS", size: 6, color: glyphTextMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // ── Primary Nav Widget Cells (FACES | TILES) ────────────────────
                HStack(spacing: 12) {
                    Button {
                        activeScreen = .faces
                    } label: {
                        VStack(spacing: 12) {
                            PrimaryIconContainer(name: "icon_faces", isRobot: true)
                                .frame(width: 42, height: 42)
                            PixelText("FACES", size: 6, color: glyphTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
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
                        VStack(spacing: 12) {
                            PrimaryIconContainer(name: "icon_tiles", isRobot: false)
                                .frame(width: 42, height: 42)
                            PixelText("TILES", size: 6, color: glyphTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)

                // ── Section Title: SETTINGS
                PixelText("SETTINGS", size: 6, color: glyphTextMuted)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                // ── Secondary Nav Rows ─────────────────────────────────────────
                VStack(spacing: 8) {
                    HomeNavListRow(
                        icon: AnyView(CustomIconContainer(name: "icon_setting", fallbackSymbol: "gearshape.fill", fallbackAccentColor: glyphAccent)),
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
                        icon: AnyView(CustomIconContainer(name: "icon_tips", fallbackSymbol: "lightbulb.fill", fallbackAccentColor: glyphAccent, fallbackAccentBottom: true)),
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
                        icon: AnyView(CustomIconContainer(name: "icon_store", fallbackSymbol: "bag.fill", fallbackAccentColor: glyphAccent, fallbackIsBag: true)),
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
                VStack(alignment: .leading, spacing: 6) {
                    PixelText(title, size: 7, color: glyphTextActive)
                    if let sub = subtitle {
                        PixelText(sub, size: 5, color: glyphTextMuted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(glyphTextMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Faces View (Glyph scrollable Watch Face Layout)

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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(glyphTextActive)
                        PixelText("FACES", size: 9, color: glyphTextActive)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // 1. Section: PREVIEW
                    VStack(alignment: .leading, spacing: 8) {
                        PixelText("PREVIEW", size: 6, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        HStack(spacing: 20) {
                            // Left Side: Circular Watch Face Preview
                            ZStack {
                                Circle()
                                    .fill(glyphBg)
                                    .frame(width: 130, height: 130)
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1.5))

                                ZStack {
                                    switch activePreview {
                                    case .clock(let style):
                                        OLEDClockPreview(style: style)
                                    case .emote(let index):
                                        OLEDEmotePreview(gifName: emoteFaces[index].gif)
                                    case .activity:
                                        OLEDActivityPreview(healthKit: healthKit)
                                    }
                                }
                                .frame(width: 90, height: 45)
                                .clipped()
                            }

                            // Right Side: Title + Attributes + Carousel Indicator
                            VStack(alignment: .leading, spacing: 8) {
                                PixelText(previewTitle, size: 8, color: glyphTextActive)
                                    .fixedSize(horizontal: false, vertical: true)

                                PixelText(previewAttributes, size: 6, color: glyphTextMuted)

                                // Carousel Dot indicators
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(activeIndicatorIndex == 0 ? glyphAccent : glyphTextMuted.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(activeIndicatorIndex == 1 ? glyphAccent : glyphTextMuted.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                    Circle()
                                        .fill(activeIndicatorIndex == 2 ? glyphAccent : glyphTextMuted.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                }
                                .padding(.top, 4)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 2. Section: CLOCK
                    VStack(alignment: .leading, spacing: 8) {
                        PixelText("CLOCK", size: 6, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                PixelText("CLOCK WIDGETS", size: 6, color: glyphTextActive)
                                Spacer()
                                Button {
                                    bleManager.syncTime()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.black)
                                        PixelText("SYNC TIME", size: 5, color: .black)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(glyphTextActive)
                                    .cornerRadius(4)
                                }
                                .disabled(!bleManager.isConnected)
                                .opacity(bleManager.isConnected ? 1.0 : 0.4)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(clockFaces, id: \.style) { face in
                                        Button {
                                            selectedClockStyle = face.style
                                            activePreview = .clock(face.style)
                                            if bleManager.isConnected { bleManager.sendMode(0) }
                                        } label: {
                                            VStack(spacing: 8) {
                                                // Square with small cornerRadius option view
                                                ZStack {
                                                    glyphBg
                                                        .cornerRadius(6)
                                                    
                                                    OLEDClockPreview(style: face.style)
                                                        .frame(width: 64, height: 32)
                                                        .clipped()
                                                }
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(selectedClockStyle == face.style ? glyphTextActive : Color.clear, lineWidth: 1.5)
                                                )
                                                
                                                VStack(spacing: 4) {
                                                    PixelText(face.label, size: 5, color: selectedClockStyle == face.style ? glyphTextActive : glyphTextMuted)
                                                    if selectedClockStyle == face.style {
                                                        Circle()
                                                            .fill(glyphAccent)
                                                            .frame(width: 4, height: 4)
                                                    } else {
                                                        Spacer().frame(height: 4)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(16)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 3. Section: EMOTE
                    VStack(alignment: .leading, spacing: 8) {
                        PixelText("EMOTE", size: 6, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(Array(emoteFaces.enumerated()), id: \.offset) { idx, face in
                                        Button {
                                            selectedEmoteIndex = idx
                                            activePreview = .emote(idx)
                                            if bleManager.isConnected { bleManager.sendMode(1) }
                                        } label: {
                                            VStack(spacing: 8) {
                                                ZStack {
                                                    glyphBg
                                                        .cornerRadius(6)

                                                    GifImageView(name: face.gif)
                                                        .frame(width: 64, height: 64)
                                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(selectedEmoteIndex == idx ? glyphTextActive : Color.clear, lineWidth: 1.5)
                                                )

                                                VStack(spacing: 4) {
                                                    PixelText(face.label, size: 5, color: selectedEmoteIndex == idx ? glyphTextActive : glyphTextMuted)
                                                    if selectedEmoteIndex == idx {
                                                        Circle()
                                                            .fill(glyphAccent)
                                                            .frame(width: 4, height: 4)
                                                    } else {
                                                        Spacer().frame(height: 4)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(16)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 4. Section: ACTIVITY
                    VStack(alignment: .leading, spacing: 8) {
                        PixelText("ACTIVITY", size: 6, color: glyphTextMuted)
                            .padding(.horizontal, 4)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                PixelText("LIVE HEALTH METRICS", size: 6, color: glyphTextActive)
                                Spacer()
                                Button {
                                    healthKit.fetchAllMetrics()
                                    activePreview = .activity
                                    if bleManager.isConnected {
                                        bleManager.sendMode(2)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        bleManager.sendActivityData(
                                            steps:    UInt32(healthKit.stepCount),
                                            bpm:      UInt16(healthKit.heartRate),
                                            calories: UInt16(healthKit.activeCalories)
                                        )
                                    }
                                } label: {
                                    PixelText("SYNC TO OLED", size: 5, color: .black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(glyphTextActive)
                                        .cornerRadius(4)
                                }
                            }

                            if !healthKit.isAuthorized {
                                Button {
                                    healthKit.requestAuthorization { _ in }
                                } label: {
                                    PixelText("GRANT HEALTHKIT ACCESS", size: 6, color: .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(glyphAccent)
                                        .cornerRadius(4)
                                }
                            }

                            VStack(spacing: 0) {
                                ActivityRow(icon: "figure.walk", assetName: "icon_steps", label: "STEPS", value: "\(healthKit.stepCount)", unit: "STEPS", accent: pixelBlue)
                                Divider().background(Color.white.opacity(0.05))
                                ActivityRow(icon: "heart.fill", assetName: "icon_heartrate", label: "HEART RATE", value: "\(healthKit.heartRate)", unit: "BPM", accent: glyphAccent)
                                Divider().background(Color.white.opacity(0.05))
                                ActivityRow(icon: "flame.fill", assetName: "icon_calories", label: "CALORIES", value: "\(healthKit.activeCalories)", unit: "KCAL", accent: glyphAccent)
                                Divider().background(Color.white.opacity(0.05))
                                ActivityRow(icon: "battery.100", assetName: "icon_battery", label: "BATTERY", value: "\(bleManager.batteryLevel)%", unit: "CASE", accent: pixelBlue)
                            }
                            .background(glyphBg)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(16)
                        .background(glyphCardBg)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
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
        case .activity:
            return "ACTIVITY FACE"
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
        case .activity:
            return "Steps  BPM  Calories"
        }
    }

    private var activeIndicatorIndex: Int {
        switch activePreview {
        case .clock: return 0
        case .emote: return 1
        case .activity: return 2
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let assetName: String
    let label: String
    let value: String
    let unit: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            if let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(accent)
                    .frame(width: 20, height: 20)
                    .frame(width: 24)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(accent)
                    .frame(width: 24)
            }

            PixelText(label, size: 5, color: glyphTextMuted)

            Spacer()

            PixelText(value, size: 7, color: glyphTextActive)
            PixelText(unit, size: 5, color: glyphTextMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
            Button {
                activeScreen = .home
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(glyphTextActive)
                    PixelText("SETTINGS", size: 8, color: glyphTextActive)
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
                            PixelText("NOTIFICATIONS", size: 7, color: glyphTextActive)
                            Spacer()
                            Toggle("", isOn: $notificationsOn)
                                .toggleStyle(SwitchToggleStyle(tint: glyphAccent))
                                .labelsHidden()
                        }
                        .padding(16)
                        Divider().background(Color.white.opacity(0.05))

                        // Brightness
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                PixelText("BRIGHTNESS", size: 7, color: glyphTextActive)
                                Spacer()
                                PixelText("\(Int(brightness * 100))%", size: 6, color: glyphTextMuted)
                            }
                            Slider(value: $brightness).accentColor(glyphAccent)
                        }
                        .padding(16)
                        Divider().background(Color.white.opacity(0.05))

                        // Health Sync
                        HStack {
                            PixelText("HEALTH SYNC", size: 7, color: glyphTextActive)
                            Spacer()
                            Toggle("", isOn: $healthSyncOn)
                                .toggleStyle(SwitchToggleStyle(tint: glyphAccent))
                                .labelsHidden()
                        }
                        .padding(16)
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
                        .foregroundColor(glyphTextActive)
                    PixelText(title, size: 8, color: glyphTextActive)
                }
            }
            .padding(.top, 56)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Spacer()
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(glyphTextMuted)
                .frame(maxWidth: .infinity)
            PixelText("COMING SOON", size: 8, color: glyphTextMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
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
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                PixelText(fmt("HH:mm"), size: 22, color: glyphTextActive)
                PixelText(fmt(":ss"),   size: 10, color: glyphTextActive)
            }
            HStack {
                PixelText("BLE OK", size: 5, color: glyphTextMuted)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
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

// MARK: - OLED Activity Preview

struct OLEDActivityPreview: View {
    @ObservedObject var healthKit: HealthKitManager
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            actRow(icon: "figure.walk", val: "\(healthKit.stepCount) STEPS",   color: pixelBlue)
            actRow(icon: "heart.fill",  val: "\(healthKit.heartRate) BPM",      color: glyphAccent)
            actRow(icon: "flame.fill",  val: "\(healthKit.activeCalories) KCAL", color: glyphAccent)
        }
        .padding(10)
    }

    @ViewBuilder
    private func actRow(icon: String, val: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(color)
            PixelText(val, size: 6, color: glyphTextActive)
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

// MARK: - Modern Vector Icons for Home Screen

struct ModernRobotIcon: View {
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Rectangle().fill(Color.red).frame(width: 4, height: 4)
                    .offset(y: -4)
                Rectangle().fill(Color(white: 0.5)).frame(width: 2, height: 6)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(white: 0.5), lineWidth: 2.5)
                    .frame(width: 32, height: 24)
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.5))
                        .frame(width: 5, height: 5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.5))
                        .frame(width: 5, height: 5)
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
                RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.5), lineWidth: 2).frame(width: 12, height: 12)
                RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.5), lineWidth: 2).frame(width: 12, height: 12)
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.5), lineWidth: 2).frame(width: 12, height: 12)
                RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.5), lineWidth: 2).frame(width: 12, height: 12)
            }
        }
        .frame(width: 42, height: 42)
    }
}

// MARK: - Custom Icon Container (loads bundle assets or falls back to system designs)

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
                .frame(width: 38, height: 38)
            
            if let uiImage = UIImage(named: name) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                // Fallback to vector/SF Symbol
                if fallbackIsBag {
                    ZStack {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 16))
                            .foregroundColor(glyphTextMuted)
                        Image(systemName: "bag")
                            .font(.system(size: 16))
                            .foregroundColor(fallbackAccentColor)
                    }
                } else {
                    ZStack {
                        Image(systemName: fallbackSymbol)
                            .font(.system(size: 16))
                            .foregroundColor(glyphTextMuted)
                        
                        if fallbackAccentBottom {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(fallbackAccentColor)
                                    .frame(width: 5, height: 2.5)
                                    .padding(.bottom, 11)
                            }
                        } else {
                            Circle()
                                .fill(fallbackAccentColor)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
        .frame(width: 38, height: 38)
    }
}

// MARK: - Primary Navigation Icon Container

struct PrimaryIconContainer: View {
    let name: String
    let isRobot: Bool

    var body: some View {
        if let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
        } else {
            if isRobot {
                ModernRobotIcon()
            } else {
                ModernGridIcon()
            }
        }
    }
}
