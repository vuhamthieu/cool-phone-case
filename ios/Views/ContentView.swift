import SwiftUI
import WebKit

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    // Tab index: 0: Home, 1: Faces, 2: Camera
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main View Content Switcher
                    Group {
                        if selectedTab == 0 {
                            HomeView()
                        } else if selectedTab == 1 {
                            FacesView()
                        } else if selectedTab == 2 {
                            CameraView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    
                    // Custom Bottom Tab Bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Tab Views

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top title: 'OverByte'
                HStack {
                    Text("OVERBYTE")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                }
                .padding(.top, 16)
                
                // Middle: Bounding box acting as the 'Preview OLED faces' area
                VStack(alignment: .leading, spacing: 10) {
                    Text("PREVIEW OLED FACES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                            .frame(height: 180)
                            .background(Color(white: 0.02))
                            .cornerRadius(16)
                        
                        PreviewViewframe()
                            .opacity(0.6)
                        
                        GifImageView(gifName: "default")
                            .frame(width: 140, height: 110)
                    }
                }
                
                // Below Preview: BatteryIndicatorView
                VStack(alignment: .leading, spacing: 10) {
                    Text("BATTERY STATUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    BatteryIndicatorView(level: bleManager.batteryLevel)
                }
                
                // Bottom area: Connection/Scan button card
                VStack(alignment: .leading, spacing: 10) {
                    Text("CONNECTION")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(bleManager.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(bleManager.connectionStatusText.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
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
                                    Text("SCAN DEVICE")
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
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Discovered Devices list
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
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    @State private var previewingFace = true
    @State private var selectedFaceIndex = 0
    @State private var selectedEmoteIndex = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top title: 'OverByte'
                HStack {
                    Text("OVERBYTE")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                }
                .padding(.top, 16)
                
                // Preview bounding box
                VStack(alignment: .leading, spacing: 10) {
                    Text("PREVIEW")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white, lineWidth: 1)
                            .frame(height: 180)
                            .background(Color(white: 0.02))
                            .cornerRadius(16)
                        
                        PreviewViewframe()
                            .opacity(0.6)
                        
                        if previewingFace {
                            ClockPreviewView(style: selectedFaceIndex)
                        } else {
                            EmotePreviewView(emotionIndex: selectedEmoteIndex)
                        }
                    }
                }
                
                // CLOCK carousel
                VStack(alignment: .leading, spacing: 10) {
                    Text("CLOCK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            CarouselCard(title: "Retro", isSelected: previewingFace && selectedFaceIndex == 0, gifName: "retro_clock") {
                                previewingFace = true
                                selectedFaceIndex = 0
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                            CarouselCard(title: "Analog", isSelected: previewingFace && selectedFaceIndex == 1, gifName: "analog_clock") {
                                previewingFace = true
                                selectedFaceIndex = 1
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                            CarouselCard(title: "Binary", isSelected: previewingFace && selectedFaceIndex == 2, gifName: "binary_clock") {
                                previewingFace = true
                                selectedFaceIndex = 2
                                if bleManager.isConnected {
                                    bleManager.sendMode(0)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // EMOTE carousel
                VStack(alignment: .leading, spacing: 10) {
                    Text("EMOTE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                        .padding(.horizontal, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            CarouselCard(title: "Idle", isSelected: !previewingFace && selectedEmoteIndex == 0, gifName: "default") {
                                previewingFace = false
                                selectedEmoteIndex = 0
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            CarouselCard(title: "What", isSelected: !previewingFace && selectedEmoteIndex == 1, gifName: "what") {
                                previewingFace = false
                                selectedEmoteIndex = 1
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            CarouselCard(title: "Judging", isSelected: !previewingFace && selectedEmoteIndex == 2, gifName: "juding") {
                                previewingFace = false
                                selectedEmoteIndex = 2
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            CarouselCard(title: "Happy", isSelected: !previewingFace && selectedEmoteIndex == 3, gifName: "happy") {
                                previewingFace = false
                                selectedEmoteIndex = 3
                                if bleManager.isConnected {
                                    bleManager.sendMode(1)
                                }
                            }
                            CarouselCard(title: "Angry", isSelected: !previewingFace && selectedEmoteIndex == 4, gifName: "angry") {
                                previewingFace = false
                                selectedEmoteIndex = 4
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
    }
}

struct CameraView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top title
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

// MARK: - Reusable UI Components

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 12) {
            TabButton(title: "home", tabIndex: 0, selectedTab: $selectedTab)
            TabButton(title: "faces", tabIndex: 1, selectedTab: $selectedTab)
            TabButton(title: "camera", tabIndex: 2, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)
    }
}

struct TabButton: View {
    let title: String
    let tabIndex: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tabIndex
            }
        }) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(selectedTab == tabIndex ? .black : .white)
                .padding(.vertical, 10)
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

struct CarouselCard: View {
    let title: String
    let isSelected: Bool
    let gifName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .background(Color.white.opacity(0.01))
                        .cornerRadius(12)
                    
                    GifImageView(gifName: gifName)
                        .frame(width: 80, height: 80)
                }
                
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
    }
}

struct PreviewViewframe: View {
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
    @State private var timeString = "10:34"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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

struct BatteryIndicatorView: View {
    let level: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: batteryIconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(batteryColor)
                .scaleEffect(level <= 30 && isPulsing ? 1.15 : 1.0)
                .opacity(level <= 30 && isPulsing ? 0.4 : 1.0)
            
            Text("\(level)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(batteryColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(batteryColor.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            if level <= 30 {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: level) { newLevel in
            if newLevel <= 30 {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation {
                    isPulsing = false
                }
            }
        }
    }
    
    private var batteryIconName: String {
        if level > 80 {
            return "battery.100"
        } else if level > 30 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
    
    private var batteryColor: Color {
        if level > 80 {
            return .green
        } else if level > 30 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - WKWebView GIF Engine (No Third Party Dependency)

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
