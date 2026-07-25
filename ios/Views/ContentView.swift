import SwiftUI
import WebKit

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    // Core modes: 0: Clock, 1: Emote, 2: Camera
    @State private var selectedMode = 0
    @State private var lastSyncedTimeText = "Never"
    
    // Sub-states for preview customization
    @State private var selectedClockStyle = 0 // 0: Retro, 1: Analog, 2: Binary
    @State private var selectedEmote = 0      // 0: Idle, 1: What, 2: Judging, 3: Happy, 4: Angry
    @State private var selectedFilter = 0     // 0: Normal, 1: Mono, 2: Negative, 3: Posterize
    
    @State private var timeString = "10:34"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // --- HEADER BAR ---
                        HStack {
                            Text("OVERBYTE")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(bleManager.isConnected ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text(bleManager.isConnected ? "● BLE" : "○ BLE")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(bleManager.isConnected ? .white : .gray)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 4)
                        
                        // --- PREVIEW SECTION ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PREVIEW")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .tracking(1)
                                .padding(.horizontal, 4)
                            
                            ZStack {
                                // OLED simulated screen
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.02))
                                    .frame(height: 160)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                    )
                                
                                // Viewfinder bracket decoration
                                PreviewViewfinder()
                                    .opacity(0.6)
                                
                                // Dynamic preview based on mode
                                if selectedMode == 0 {
                                    ClockPreviewView(style: selectedClockStyle, timeString: timeString)
                                } else if selectedMode == 1 {
                                    EmotePreviewView(emotionIndex: selectedEmote)
                                } else if selectedMode == 2 {
                                    CameraPreviewView(filterIndex: selectedFilter)
                                }
                            }
                            .frame(height: 160)
                        }
                        
                        // --- WIDGETS GRID ---
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WIDGETS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .tracking(1)
                                .padding(.horizontal, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                // Mode selector widgets (Clock, Emote, Camera)
                                WidgetButton(title: "Clock", iconName: "clock", isActive: bleManager.isConnected && selectedMode == 0) {
                                    if bleManager.isConnected {
                                        selectedMode = 0
                                        bleManager.sendMode(0)
                                    }
                                }
                                
                                WidgetButton(title: "Emote", iconName: "face.smiling", isActive: bleManager.isConnected && selectedMode == 1) {
                                    if bleManager.isConnected {
                                        selectedMode = 1
                                        bleManager.sendMode(1)
                                    }
                                }
                                
                                WidgetButton(title: "Camera", iconName: "camera", isActive: bleManager.isConnected && selectedMode == 2) {
                                    if bleManager.isConnected {
                                        selectedMode = 2
                                        bleManager.sendMode(2)
                                    }
                                }
                                
                                // Utility widgets (Sync, Battery, OTA)
                                WidgetButton(title: "Sync Time", iconName: "clock.arrow.2.circlepath", isActive: false) {
                                    if bleManager.isConnected {
                                        bleManager.syncTime()
                                        let formatter = DateFormatter()
                                        formatter.timeStyle = .medium
                                        lastSyncedTimeText = formatter.string(from: Date())
                                    }
                                }
                                
                                WidgetButton(title: "Battery (\(bleManager.batteryLevel)%)", iconName: bleManager.batteryLevel > 30 ? "battery.100" : "battery.25", isActive: false) {
                                    // Static info widget
                                }
                                
                                WidgetButton(title: "OTA Update", iconName: "arrow.up.doc", isActive: false) {
                                    // Status info
                                }
                                
                                // Decorative widgets (Snake, Compass, Light)
                                WidgetButton(title: "Snake", iconName: "play", isActive: false) {}
                                WidgetButton(title: "Compass", iconName: "compass.drawing", isActive: false) {}
                                WidgetButton(title: "Light", iconName: "sun.max", isActive: false) {}
                            }
                        }
                        
                        // --- BACKGROUND / EXTRA SETTINGS SECTION ---
                        VStack(alignment: .leading, spacing: 12) {
                            if selectedMode == 0 {
                                Text("CLOCK STYLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    CapsuleSettingButton(title: "Retro Digital", isSelected: selectedClockStyle == 0) {
                                        selectedClockStyle = 0
                                    }
                                    CapsuleSettingButton(title: "Analog Face", isSelected: selectedClockStyle == 1) {
                                        selectedClockStyle = 1
                                    }
                                    CapsuleSettingButton(title: "Binary Face", isSelected: selectedClockStyle == 2) {
                                        selectedClockStyle = 2
                                    }
                                }
                            } else if selectedMode == 1 {
                                Text("EMOTE SELECT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    CapsuleSettingButton(title: "Idle Face", isSelected: selectedEmote == 0) {
                                        selectedEmote = 0
                                    }
                                    CapsuleSettingButton(title: "What Face", isSelected: selectedEmote == 1) {
                                        selectedEmote = 1
                                    }
                                    CapsuleSettingButton(title: "Judging", isSelected: selectedEmote == 2) {
                                        selectedEmote = 2
                                    }
                                    CapsuleSettingButton(title: "Happy Face", isSelected: selectedEmote == 3) {
                                        selectedEmote = 3
                                    }
                                    CapsuleSettingButton(title: "Angry Face", isSelected: selectedEmote == 4) {
                                        selectedEmote = 4
                                    }
                                }
                            } else if selectedMode == 2 {
                                Text("STREAM FILTER")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .tracking(1)
                                    .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                    CapsuleSettingButton(title: "Normal", isSelected: selectedFilter == 0) {
                                        selectedFilter = 0
                                    }
                                    CapsuleSettingButton(title: "Monochrome", isSelected: selectedFilter == 1) {
                                        selectedFilter = 1
                                    }
                                    CapsuleSettingButton(title: "Negative", isSelected: selectedFilter == 2) {
                                        selectedFilter = 2
                                    }
                                    CapsuleSettingButton(title: "Posterize", isSelected: selectedFilter == 3) {
                                        selectedFilter = 3
                                    }
                                }
                            }
                        }
                        
                        // Device scan controls for disconnected state
                        if !bleManager.isConnected {
                            VStack(spacing: 12) {
                                Image(systemName: "bolt.horizontal.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.red)
                                Text("DEVICE DISCONNECTED")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Please connect to your OVERBYTE case via Bluetooth to access controls.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 40)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.01))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                timeString = formatter.string(from: Date())
            }
        }
    }
}

// MARK: - Subviews

struct PreviewViewfinder: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                let len: CGFloat = 8
                let pad: CGFloat = 8
                
                // Top Left
                path.move(to: CGPoint(x: pad, y: pad + len))
                path.addLine(to: CGPoint(x: pad, y: pad))
                path.addLine(to: CGPoint(x: pad + len, y: pad))
                
                // Top Right
                path.move(to: CGPoint(x: w - pad - len, y: pad))
                path.addLine(to: CGPoint(x: w - pad, y: pad))
                path.addLine(to: CGPoint(x: w - pad, y: pad + len))
                
                // Bottom Left
                path.move(to: CGPoint(x: pad, y: h - pad - len))
                path.addLine(to: CGPoint(x: pad, y: h - pad))
                path.addLine(to: CGPoint(x: pad + len, y: h - pad))
                
                // Bottom Right
                path.move(to: CGPoint(x: w - pad - len, y: h - pad))
                path.addLine(to: CGPoint(x: w - pad, y: h - pad))
                path.addLine(to: CGPoint(x: w - pad, y: h - pad - len))
            }
            .stroke(Color.white.opacity(0.7), lineWidth: 1.5)
        }
    }
}

struct ClockPreviewView: View {
    let style: Int
    let timeString: String
    
    var body: some View {
        ZStack {
            GifImageView(gifName: gifName)
                .frame(width: 140, height: 100)
            
            if style == 0 {
                // Retro Digital Dot-Matrix Simulated overlay
                Text(timeString)
                    .font(.system(size: 38, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
                    .shadow(color: .black, radius: 4)
            }
        }
    }
    
    private var gifName: String {
        switch style {
        case 0: return "retro_clock"
        case 1: return "analog_clock"
        case 2: return "binary_clock"
        default: return "retro_clock"
        }
    }
}

struct EmotePreviewView: View {
    let emotionIndex: Int
    
    var body: some View {
        VStack(spacing: 6) {
            GifImageView(gifName: emoteGifName)
                .frame(width: 120, height: 100)
            
            Text(emoteName.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
    
    private var emoteGifName: String {
        switch emotionIndex {
        case 0: return "default"
        case 1: return "what"
        case 2: return "juding"
        case 3: return "happy"
        case 4: return "angry"
        default: return "default"
        }
    }
    
    private var emoteName: String {
        switch emotionIndex {
        case 0: return "Idle"
        case 1: return "What"
        case 2: return "Judging"
        case 3: return "Happy"
        case 4: return "Angry"
        default: return "Idle"
        }
    }
}

struct CameraPreviewView: View {
    let filterIndex: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Color.black
                    .frame(width: 80, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white, lineWidth: 1)
                    )
                
                Image(systemName: "camera.shutter.button")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Text(filterName.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
    
    private var filterName: String {
        switch filterIndex {
        case 0: return "Filter: Normal"
        case 1: return "Filter: Mono"
        case 2: return "Filter: Negative"
        case 3: return "Filter: Posterize"
        default: return "Filter: Normal"
        }
    }
}

struct WidgetButton: View {
    let title: String
    let iconName: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .white : .gray)
                    .frame(height: 24)
                
                VStack(spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? .white : .gray)
                        .tracking(1)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    
                    if isActive {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 4, height: 4)
                    } else {
                        Spacer()
                            .frame(height: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.white.opacity(0.01))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.white : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

struct CapsuleSettingButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 4, height: 4)
                    )
                
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.black)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.12), lineWidth: 1)
            )
        }
    }
}

struct GifImageView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.opaque = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif") {
            do {
                let data = try Data(contentsOf: url)
                let html = """
                <html>
                <head>
                <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    overflow: hidden;
                }
                img {
                    max-width: 100%;
                    max-height: 100%;
                    object-fit: contain;
                    image-rendering: pixelated;
                    image-rendering: crisp-edges;
                }
                </style>
                </head>
                <body>
                <img src="data:image/gif;base64,\(data.base64EncodedString())" />
                </body>
                </html>
                """
                uiView.loadHTMLString(html, baseURL: nil)
            } catch {
                print("Error loading GIF data: \(error)")
            }
        } else {
            let html = """
            <html>
            <head>
            <style>
            body {
                margin: 0;
                padding: 0;
                background-color: transparent;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                overflow: hidden;
                color: #888888;
                font-family: monospace;
                font-size: 8px;
                border: 1px dashed #333333;
                text-align: center;
            }
            </style>
            </head>
            <body>
            MISSING:<br>\(gifName.uppercased()).GIF
            </body>
            </html>
            """
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {}
}
