import SwiftUI
import WebKit

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var selectedTab = 0 // 0: Home, 1: Faces, 2: Camera
    
    // Core customization states
    @State private var selectedClockStyle = 0 // 0: Retro, 1: Analog, 2: Binary
    @State private var selectedEmote = 0      // 0: Idle, 1: What, 2: Judging, 3: Happy, 4: Angry
    @State private var selectedFilter = 0     // 0: Normal, 1: Mono, 2: Negative, 3: Posterize
    @State private var lastSyncedTimeText = "Never"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top main content view (fills all available space)
                    Group {
                        if selectedTab == 0 {
                            HomeView(selectedClockStyle: $selectedClockStyle, selectedEmote: $selectedEmote, lastSyncedTimeText: $lastSyncedTimeText)
                        } else if selectedTab == 1 {
                            FacesView(selectedClockStyle: $selectedClockStyle, selectedEmote: $selectedEmote)
                        } else if selectedTab == 2 {
                            CameraView(selectedFilter: $selectedFilter)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 0)
                    
                    // Bottom tab bar explicitly pinned outside the scrollable views
                    CustomTabBar(selectedTab: $selectedTab)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Tab Views

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmote: Int
    @Binding var lastSyncedTimeText: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    Text("OVERBYTE")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                }
                .padding(.top, 16)
                
                // Preview OLED Frame
                VStack(alignment: .leading, spacing: 10) {
                    Text("PREVIEW OLED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                            .frame(height: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.02))
                            )
                        
                        PreviewViewfinder()
                            .opacity(0.6)
                        
                        // Default preview show idle face
                        GifImageView(gifName: "default", fallbackSystemName: "face.smiling")
                            .frame(width: 140, height: 110)
                    }
                }
                
                // Device Status Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("DEVICE STATUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Circle()
                                .fill(bleManager.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(bleManager.connectionStatusText.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if bleManager.isConnected {
                                HStack(spacing: 6) {
                                    Image(systemName: bleManager.batteryLevel > 30 ? "battery.100" : "battery.25")
                                        .foregroundColor(bleManager.batteryLevel > 30 ? .green : .red)
                                    Text("\(bleManager.batteryLevel)%")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        if bleManager.isConnected {
                            Button(action: {
                                bleManager.disconnect()
                            }) {
                                Text("DISCONNECT DEVICE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red, lineWidth: 1)
                                    )
                            }
                        } else {
                            Button(action: {
                                bleManager.startScanning()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("SCAN FOR DEVICE")
                                }
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                
                // Discovered list
                if !bleManager.isConnected && !bleManager.discoveredPeripherals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISCOVERED DEVIATION:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        ForEach(bleManager.discoveredPeripherals, id: \.identifier) { device in
                            Button(action: {
                                bleManager.connect(to: device)
                            }) {
                                HStack {
                                    Image(systemName: "candybarphone")
                                    Text((device.name ?? "UNKNOWN DEVICE").uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                // Utilities Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("UTILITIES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            if bleManager.isConnected {
                                bleManager.syncTime()
                                let formatter = DateFormatter()
                                formatter.timeStyle = .medium
                                lastSyncedTimeText = formatter.string(from: Date())
                            }
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.2.circlepath")
                                Text("SYNC TIME WITH IPHONE")
                                Spacer()
                                Text(lastSyncedTimeText)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .disabled(!bleManager.isConnected)
                        .opacity(bleManager.isConnected ? 1.0 : 0.5)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmote: Int
    @State private var previewingFace = true // True = Clock Face, False = Emote
    
    @State private var timeString = "10:34"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    Text("OVERBYTE")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                }
                .padding(.top, 16)
                
                // Live preview frame
                VStack(alignment: .leading, spacing: 10) {
                    Text("LIVE OLED PREVIEW")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                            .frame(height: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.02))
                            )
                        
                        PreviewViewfinder()
                            .opacity(0.6)
                        
                        if previewingFace {
                            ClockPreviewContainer(style: selectedClockStyle, timeString: timeString)
                        } else {
                            EmotePreviewContainer(emotionIndex: selectedEmote)
                        }
                    }
                }
                
                // Clock faces select
                VStack(alignment: .leading, spacing: 10) {
                    Text("CLOCK STYLE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CarouselCard(title: "Retro", isSelected: previewingFace && selectedClockStyle == 0, gifName: "retro_clock", fallbackIcon: "clock") {
                                previewingFace = true
                                selectedClockStyle = 0
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                            
                            CarouselCard(title: "Analog", isSelected: previewingFace && selectedClockStyle == 1, gifName: "analog_clock", fallbackIcon: "clock") {
                                previewingFace = true
                                selectedClockStyle = 1
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                            
                            CarouselCard(title: "Binary", isSelected: previewingFace && selectedClockStyle == 2, gifName: "binary_clock", fallbackIcon: "clock") {
                                previewingFace = true
                                selectedClockStyle = 2
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Emote select
                VStack(alignment: .leading, spacing: 10) {
                    Text("EMOTE SELECT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CarouselCard(title: "Idle", isSelected: !previewingFace && selectedEmote == 0, gifName: "default", fallbackIcon: "face.smiling") {
                                previewingFace = false
                                selectedEmote = 0
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            
                            CarouselCard(title: "What", isSelected: !previewingFace && selectedEmote == 1, gifName: "what", fallbackIcon: "questionmark.circle") {
                                previewingFace = false
                                selectedEmote = 1
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            
                            CarouselCard(title: "Judging", isSelected: !previewingFace && selectedEmote == 2, gifName: "juding", fallbackIcon: "eye") {
                                previewingFace = false
                                selectedEmote = 2
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            
                            CarouselCard(title: "Happy", isSelected: !previewingFace && selectedEmote == 3, gifName: "happy", fallbackIcon: "face.smiling.fill") {
                                previewingFace = false
                                selectedEmote = 3
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            
                            CarouselCard(title: "Angry", isSelected: !previewingFace && selectedEmote == 4, gifName: "angry", fallbackIcon: "bolt.circle") {
                                previewingFace = false
                                selectedEmote = 4
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .onReceive(timer) { _ in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            timeString = formatter.string(from: Date())
        }
        .onAppear {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            timeString = formatter.string(from: Date())
        }
    }
}

struct CameraView: View {
    @Binding var selectedFilter: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Bar
            HStack {
                Text("OVERBYTE")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(2)
                Spacer()
            }
            .padding(.top, 16)
            
            Text("CAMERA STREAM")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .tracking(1)
                .padding(.horizontal, 4)
            
            CameraStreamView()
                .padding(8)
                .background(Color.black)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 1)
                )
            
            Spacer()
        }
    }
}

// MARK: - Subviews & Supporting Views

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

struct ClockPreviewContainer: View {
    let style: Int
    let timeString: String
    
    var body: some View {
        ZStack {
            GifImageView(gifName: gifName, fallbackSystemName: "clock")
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

struct EmotePreviewContainer: View {
    let emotionIndex: Int
    
    var body: some View {
        VStack(spacing: 6) {
            GifImageView(gifName: emoteGifName, fallbackSystemName: "face.smiling")
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

struct CarouselCard: View {
    let title: String
    let isSelected: Bool
    let gifName: String
    let fallbackIcon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.01))
                        )
                    
                    GifImageView(gifName: gifName, fallbackSystemName: fallbackIcon)
                        .frame(width: 80, height: 80)
                }
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
    }
}

// MARK: - Custom Bottom Navigation Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 12) {
            TabButton(title: "Home", tabIndex: 0, selectedTab: $selectedTab)
            TabButton(title: "Faces", tabIndex: 1, selectedTab: $selectedTab)
            TabButton(title: "Camera", tabIndex: 2, selectedTab: $selectedTab)
        }
        .padding(.top, 8)
        .background(Color.black)
    }
}

struct TabButton: View {
    let title: String
    let tabIndex: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.12)) {
                selectedTab = tabIndex
            }
        }) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(selectedTab == tabIndex ? .black : .white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selectedTab == tabIndex ? Color.white : Color.black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 1)
                )
        }
    }
}

// MARK: - WKWebView GIF Loop Engine with SVG/Native Fallbacks

struct GifImageView: View {
    let gifName: String
    let fallbackSystemName: String
    
    var body: some View {
        if let _ = Bundle.main.url(forResource: gifName, withExtension: "gif") {
            WebViewGifRepresentable(gifName: gifName)
        } else {
            // Elegant, iOS 15 compatible placeholder for missing local files
            VStack(spacing: 8) {
                Image(systemName: fallbackSystemName)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("MISSING:\n\(gifName.uppercased()).GIF")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct WebViewGifRepresentable: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.isUserInteractionEnabled = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
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
                html, body {
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    background-color: black;
                }
                img {
                    max-width: 100%;
                    max-height: 100%;
                    object-fit: contain;
                    image-rendering: pixelated;
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
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {}
}
