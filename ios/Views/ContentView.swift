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
                                PrimaryIconContainer(name: "icon_faces", isRobot: true)
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
                                PrimaryIconContainer(name: "icon_tiles", isRobot: false)
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
                        icon: AnyView(CustomIconContainer(name: "icon_setting", fallbackSymbol: "gearshape.fill", fallbackAccentColor: .red)),
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
                        icon: AnyView(CustomIconContainer(name: "icon_tips", fallbackSymbol: "lightbulb.fill", fallbackAccentColor: .red, fallbackAccentBottom: true)),
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
                        icon: AnyView(CustomIconContainer(name: "icon_store", fallbackSymbol: "bag.fill", fallbackAccentColor: .red, fallbackIsBag: true)),
                        title: "STORE"
                    ) {
                        activeScreen = .store
                    }
                }
                .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                .cornerRadius(24)
                .padding(.horizontal, 16)
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

// MARK: - Faces View (Premium Scrollable Watch Face Layout)

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
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(pixelWhite)
                        Text("FACES")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(pixelWhite)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // 1. The Top OLED Circular Preview Box + Attributes Description
                    HStack(spacing: 20) {
                        // Left Side: Circular Watch Face Preview
                        ZStack {
                            Circle()
                                .fill(pixelBlack)
                                .frame(width: 140, height: 140)
                                .overlay(Circle().stroke(pixelWhite.opacity(0.2), lineWidth: 2))

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
                            .frame(width: 100, height: 50)
                            .clipped()
                        }

                        // Right Side: Title + Description + Carousel Indicator
                        VStack(alignment: .leading, spacing: 8) {
                            Text(previewTitle)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(pixelWhite)
                                .lineLimit(2)

                            Text(previewAttributes)
                                .font(.system(size: 12))
                                .foregroundColor(pixelGray)

                            // Carousel Dot indicators (. . .)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(activeIndicatorIndex == 0 ? pixelRed : pixelGray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(activeIndicatorIndex == 1 ? pixelRed : pixelGray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(activeIndicatorIndex == 2 ? pixelRed : pixelGray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                            }
                            .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // 2. The Clock Selection Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("CLOCK")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                bleManager.syncTime()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("SYNC TIME")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(pixelWhite)
                                .cornerRadius(12)
                            }
                            .disabled(!bleManager.isConnected)
                            .opacity(bleManager.isConnected ? 1.0 : 0.4)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(clockFaces, id: \.style) { face in
                                    Button {
                                        selectedClockStyle = face.style
                                        activePreview = .clock(face.style)
                                        if bleManager.isConnected { bleManager.sendMode(0) }
                                    } label: {
                                        VStack(spacing: 10) {
                                            // Circular clock preview
                                            ZStack {
                                                Circle()
                                                    .fill(pixelBlack)
                                                    .frame(width: 84, height: 84)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                selectedClockStyle == face.style ? pixelRed : pixelWhite.opacity(0.15),
                                                                lineWidth: selectedClockStyle == face.style ? 2 : 1
                                                            )
                                                    )
                                                
                                                OLEDClockPreview(style: face.style)
                                                    .frame(width: 64, height: 32)
                                                    .clipped()
                                            }

                                            Text(face.label)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(selectedClockStyle == face.style ? pixelRed : pixelGray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        // Card Indicator Dots
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Circle().fill(activePreview == .clock(0) ? pixelRed : pixelGray.opacity(0.3)).frame(width: 6, height: 6)
                                Circle().fill(activePreview == .clock(1) ? pixelRed : pixelGray.opacity(0.3)).frame(width: 6, height: 6)
                                Circle().fill(activePreview == .clock(2) ? pixelRed : pixelGray.opacity(0.3)).frame(width: 6, height: 6)
                            }
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)

                    // 3. The Emote Selection Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EMOTE")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(emoteFaces.enumerated()), id: \.offset) { idx, face in
                                    Button {
                                        selectedEmoteIndex = idx
                                        activePreview = .emote(idx)
                                        if bleManager.isConnected { bleManager.sendMode(1) }
                                    } label: {
                                        VStack(spacing: 10) {
                                            // Circular emote preview
                                            ZStack {
                                                Circle()
                                                    .fill(pixelBlack)
                                                    .frame(width: 84, height: 84)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(
                                                                selectedEmoteIndex == idx ? pixelRed : pixelWhite.opacity(0.15),
                                                                lineWidth: selectedEmoteIndex == idx ? 2 : 1
                                                            )
                                                    )

                                                GifImageView(name: face.gif)
                                                    .frame(width: 64, height: 64)
                                                    .clipShape(Circle())
                                            }

                                            Text(face.label)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(selectedEmoteIndex == idx ? pixelRed : pixelGray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        // Card Indicator Dots
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(0..<emoteFaces.count, id: \.self) { idx in
                                    Circle()
                                        .fill(activePreview == .emote(idx) ? pixelRed : pixelGray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)

                    // 4. The Activity Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("ACTIVITY")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
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
                                Text("SYNC TO OLED")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(pixelWhite)
                                    .cornerRadius(12)
                            }
                        }

                        if !healthKit.isAuthorized {
                            Button {
                                healthKit.requestAuthorization { _ in }
                            } label: {
                                Text("GRANT HEALTHKIT ACCESS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(pixelRed)
                                    .cornerRadius(12)
                            }
                        }

                        VStack(spacing: 0) {
                            ActivityRow(icon: "figure.walk", assetName: "icon_steps", label: "STEPS", value: "\(healthKit.stepCount)", unit: "STEPS", accent: pixelBlue)
                            Divider().background(Color.white.opacity(0.1))
                            ActivityRow(icon: "heart.fill", assetName: "icon_heartrate", label: "HEART RATE", value: "\(healthKit.heartRate)", unit: "BPM", accent: pixelRed)
                            Divider().background(Color.white.opacity(0.1))
                            ActivityRow(icon: "flame.fill", assetName: "icon_calories", label: "CALORIES", value: "\(healthKit.activeCalories)", unit: "KCAL", accent: pixelRed)
                            Divider().background(Color.white.opacity(0.1))
                            ActivityRow(icon: "battery.100", assetName: "icon_battery", label: "BATTERY", value: "\(bleManager.batteryLevel)%", unit: "CASE", accent: pixelBlue)
                        }
                        .background(pixelBlack)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .padding(20)
                    .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                    .cornerRadius(24)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(pixelBlack)
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
                    .frame(width: 24, height: 24)
                    .frame(width: 28)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(accent)
                    .frame(width: 28)
            }

            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(pixelGray)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(pixelWhite)
            Text(unit)
                .font(.system(size: 12))
                .foregroundColor(pixelGray)
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
                Text(fmt("HH:mm"))
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(pixelWhite)
                Text(fmt(":ss"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelWhite)
            }
            HStack {
                Text("BLE OK")
                    .font(.system(size: 6, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelGray)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }

    @ViewBuilder private var digitalDate: some View {
        VStack(spacing: 6) {
            Text(fmt("HH:mm:ss"))
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(pixelWhite)
            Text(fmt("EEEE, MMM dd"))
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(pixelWhite)
        }
    }

    @ViewBuilder private var analogFace: some View {
        HStack(spacing: 10) {
            PixelAnalogDial(date: now, size: 90)
            VStack(alignment: .leading, spacing: 4) {
                Text(fmt("HH:mm"))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelWhite)
                Text(fmt(":ss"))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelGray)
                Text(fmt("dd/MM"))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelWhite)
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
        case 2: return pixelRed
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
            Text(val)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(pixelWhite)
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
                Text("NO GIF")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(pixelGray)
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
                .fill(Color(white: 0.15))
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
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Image(systemName: "bag")
                            .font(.system(size: 18))
                            .foregroundColor(fallbackAccentColor)
                    }
                } else {
                    ZStack {
                        Image(systemName: fallbackSymbol)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        if fallbackAccentBottom {
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(fallbackAccentColor)
                                    .frame(width: 6, height: 3)
                                    .padding(.bottom, 10)
                            }
                        } else {
                            Circle()
                                .fill(fallbackAccentColor)
                                .frame(width: 5, height: 5)
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
                .frame(width: 42, height: 42)
        } else {
            if isRobot {
                ModernRobotIcon()
            } else {
                ModernGridIcon()
            }
        }
    }
}
