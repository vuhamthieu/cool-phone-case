import SwiftUI
import WebKit

enum ActiveScreen {
    case home
    case faces
    case videoStream
    case tiles
    case settings
    case tips
    case store
}

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    @State private var activeScreen: ActiveScreen = .home
    
    // Core customization states
    @State private var selectedClockStyle = 1 // 1: Analog default
    @State private var selectedEmote = 0      // 0: Idle, 1: What, 2: Judging, 3: Happy, 4: Angry
    @State private var lastSyncedTimeText = "Never"
    
    // Persistent streaming manager
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var udpStreamer = UDPStreamer()
    @State private var isCameraStreaming = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Group {
                        switch activeScreen {
                        case .home:
                            HomeView(activeScreen: $activeScreen, selectedClockStyle: $selectedClockStyle, selectedEmote: $selectedEmote, lastSyncedTimeText: $lastSyncedTimeText)
                        case .faces:
                            FacesView(activeScreen: $activeScreen, selectedClockStyle: $selectedClockStyle, selectedEmote: $selectedEmote)
                        case .videoStream:
                            CameraView(activeScreen: $activeScreen, isCameraStreaming: $isCameraStreaming, cameraManager: cameraManager, udpStreamer: udpStreamer)
                        case .tiles:
                            TilesView(activeScreen: $activeScreen)
                        case .settings:
                            SettingsView(activeScreen: $activeScreen)
                        case .tips:
                            TipsView(activeScreen: $activeScreen)
                        case .store:
                            StoreView(activeScreen: $activeScreen)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: isCameraStreaming) { streaming in
            if streaming {
                cameraManager.onFrameCaptured = { pixelBuffer in
                    udpStreamer.streamFrame(pixelBuffer)
                }
                udpStreamer.start()
                cameraManager.start()
            } else {
                cameraManager.stop()
                udpStreamer.stop()
            }
        }
    }
}

// MARK: - Tab Views

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmote: Int
    @Binding var lastSyncedTimeText: String
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Bar
                HStack(spacing: 0) {
                    Text("OVER")
                        .foregroundColor(.white)
                    Text("B")
                        .foregroundColor(.red)
                    Text("YTE")
                        .foregroundColor(.white)
                }
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Status description
                HStack {
                    Text(bleManager.isConnected ? "CONNECTED" : "DISCONNECTED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(bleManager.isConnected ? .blue : .red)
                    Spacer()
                }
                
                // CONNECT/DISCONNECT button
                HStack {
                    Button(action: {
                        if bleManager.isConnected {
                            bleManager.disconnect()
                        } else {
                            bleManager.startScanning()
                        }
                    }) {
                        Text(bleManager.isConnected ? "DISCONNECT" : "CONNECT")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 32)
                            .background(bleManager.isConnected ? Color.red : Color(red: 31/255, green: 105/255, blue: 255/255))
                            .border(Color.white, width: 2)
                    }
                    Spacer()
                }
                
                // Discovered list if searching and not connected
                if !bleManager.isConnected && !bleManager.discoveredPeripherals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DISCOVERED DEVIATION:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
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
                                .border(Color.white.opacity(0.3), width: 1.5)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                
                // Options Box 1: Faces, Video Stream, Tiles
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .faces
                        }
                    }) {
                        VStack(spacing: 12) {
                            RobotFaceIcon()
                            Text("FACES")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .videoStream
                        }
                    }) {
                        VStack(spacing: 12) {
                            CameraIcon()
                            Text("VIDEO STREAM")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .tiles
                        }
                    }) {
                        VStack(spacing: 12) {
                            TilesIcon()
                            Text("TILES")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 20)
                .background(Color.black)
                .border(Color.white, width: 2)
                
                // Options Box 2: Setting, Tips and User Guide, Store
                VStack(spacing: 0) {
                    // Setting
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .settings
                        }
                    }) {
                        HStack(spacing: 16) {
                            GearIcon()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SETTING")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("NOTIFICATIONS • DISPLAY • HEALTH")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 2)
                    
                    // Tips and User Guide
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .tips
                        }
                    }) {
                        HStack(spacing: 16) {
                            LightbulbIcon()
                            Text("TIPS AND USER GUIDE")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 2)
                    
                    // Store
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .store
                        }
                    }) {
                        HStack(spacing: 16) {
                            BagIcon()
                            Text("STORE")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                }
                .background(Color.black)
                .border(Color.white, width: 2)
                
                Spacer(minLength: 24)
                
                BottomBrandingIcon()
            }
            .padding(.bottom, 8)
        }
    }
}

struct FacesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen
    @Binding var selectedClockStyle: Int
    @Binding var selectedEmote: Int
    
    // Category tabs: 0 = CLOCK, 1 = EMOTE, 2 = ACTIVITY
    @State private var selectedFaceCategory = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Bar with Back Button
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .home
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("FACES")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                
                // Live OLED Preview Frame (Aspect ratio 2:1, strict 8-bit black & white)
                ZStack {
                    Color.black
                    
                    // Viewfinder corners
                    PreviewViewfinder()
                    
                    if selectedFaceCategory == 0 {
                        OledClockPreviewView(style: selectedClockStyle, isConnected: bleManager.isConnected)
                    } else if selectedFaceCategory == 1 {
                        EmotePreviewContainer(emotionIndex: selectedEmote)
                    } else if selectedFaceCategory == 2 {
                        OledActivityPreviewView(batteryLevel: bleManager.batteryLevel)
                    }
                }
                .frame(height: 180)
                .border(Color.white, width: 2)
                .padding(.top, 8)
                
                // Category tabs (CLOCK, EMOTE, ACTIVITY) - 8-bit selection bar
                HStack(spacing: 0) {
                    Button(action: { selectedFaceCategory = 0 }) {
                        Text("CLOCK")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedFaceCategory == 0 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedFaceCategory == 0 ? Color.white : Color.black)
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                    
                    Button(action: { selectedFaceCategory = 1 }) {
                        Text("EMOTE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedFaceCategory == 1 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedFaceCategory == 1 ? Color.white : Color.black)
                    }
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2)
                    
                    Button(action: { selectedFaceCategory = 2 }) {
                        Text("ACTIVITY")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(selectedFaceCategory == 2 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedFaceCategory == 2 ? Color.white : Color.black)
                    }
                }
                .border(Color.white, width: 2)
                .padding(.top, 16)
                
                // Sub-items based on Category selection
                Group {
                    if selectedFaceCategory == 0 {
                        // Clock Styles
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { styleIdx in
                                Button(action: {
                                    selectedClockStyle = styleIdx
                                    if bleManager.isConnected {
                                        bleManager.sendMode(0)
                                    }
                                }) {
                                    HStack {
                                        Text(clockStyleName(styleIdx))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedClockStyle == styleIdx {
                                            Text("[ SELECTED ]")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .border(selectedClockStyle == styleIdx ? Color.white : Color.white.opacity(0.15), width: 1.5)
                                }
                            }
                        }
                    } else if selectedFaceCategory == 1 {
                        // Emote Styles
                        VStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { emoteIdx in
                                Button(action: {
                                    selectedEmote = emoteIdx
                                    if bleManager.isConnected {
                                        bleManager.sendMode(1)
                                    }
                                }) {
                                    HStack {
                                        Text(emoteName(emoteIdx))
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedEmote == emoteIdx {
                                            Text("[ ACTIVE ]")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .border(selectedEmote == emoteIdx ? Color.white : Color.white.opacity(0.15), width: 1.5)
                                }
                            }
                        }
                    } else if selectedFaceCategory == 2 {
                        // Activity summary & Sync
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("APPLE HEALTH SYNC STATUS")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text("Activity steps and heart rate synced to watch face.")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .border(Color.white.opacity(0.15), width: 1.5)
                            
                            Button(action: {
                                if bleManager.isConnected {
                                    bleManager.syncTime()
                                }
                            }) {
                                Text("FORCE SYNC")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .border(Color.white, width: 2)
                            }
                        }
                    }
                }
                .padding(.top, 16)
                
                Spacer(minLength: 24)
                
                BottomBrandingIcon()
            }
            .padding(.bottom, 8)
        }
    }
    
    private func clockStyleName(_ index: Int) -> String {
        switch index {
        case 0: return "BIG DIGITAL"
        case 1: return "DIGITAL DATE"
        case 2: return "ANALOG CLOCK"
        default: return "CLOCK"
        }
    }
    
    private func emoteName(_ index: Int) -> String {
        switch index {
        case 0: return "IDLE FACE"
        case 1: return "WHAT FACE"
        case 2: return "JUDGING FACE"
        case 3: return "HAPPY FACE"
        case 4: return "ANGRY FACE"
        default: return "EMOTE"
        }
    }
}

// MARK: - u8g2 OLED style rendering views

struct OledClockPreviewView: View {
    let style: Int
    let isConnected: Bool
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black
            
            switch style {
            case 0: // CLOCK_BIG_DIGITAL
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(timeString(from: currentDate, format: "HH:mm"))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(timeString(from: currentDate, format: ":ss"))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text(isConnected ? "BLE OK" : "NO SYNC")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                
            case 1: // CLOCK_DIGITAL_DATE
                VStack(spacing: 6) {
                    Text(timeString(from: currentDate, format: "HH:mm:ss"))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(dateString(from: currentDate, format: "EEEE, MMM dd"))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
                
            case 2: // CLOCK_ANALOG
                HStack(spacing: 16) {
                    // Analog clock face on the left
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 52, height: 52)
                        
                        // Center dot
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3, height: 3)
                        
                        // Hands
                        AnalogClockHands(date: currentDate)
                    }
                    .frame(width: 52, height: 52)
                    
                    // Digital clock read on the right
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(timeString(from: currentDate, format: "HH:mm"))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text(timeString(from: currentDate, format: ":ss"))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Text(dateString(from: currentDate, format: "dd/MM"))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            default:
                EmptyView()
            }
        }
        .onReceive(timer) { input in
            currentDate = input
        }
    }
    
    private func timeString(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    private func dateString(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

struct AnalogClockHands: View {
    let date: Date
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            let hour = CGFloat(components.hour ?? 0)
            let minute = CGFloat(components.minute ?? 0)
            let second = CGFloat(components.second ?? 0)
            
            let hourAngle = (hour * 30.0) + (minute * 0.5)
            let minuteAngle = (minute * 6.0) + (second * 0.1)
            let secondAngle = second * 6.0
            
            ZStack {
                // Hour hand
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2.5, height: radius * 0.5)
                    .offset(y: -radius * 0.25)
                    .rotationEffect(.degrees(hourAngle))
                    .position(center)
                
                // Minute hand
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1.5, height: radius * 0.75)
                    .offset(y: -radius * 0.375)
                    .rotationEffect(.degrees(minuteAngle))
                    .position(center)
                
                // Second hand
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 1.5, height: radius * 0.85)
                    .offset(y: -radius * 0.425)
                    .rotationEffect(.degrees(secondAngle))
                    .position(center)
            }
        }
    }
}

struct OledActivityPreviewView: View {
    let batteryLevel: Int
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "battery.100")
                        .foregroundColor(.blue)
                        .font(.system(size: 12))
                    Text("BATTERY: \(batteryLevel)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text("STEPS: 8,432")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text("HEART RATE: 72 BPM")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
    }
}

struct CameraView: View {
    @Binding var activeScreen: ActiveScreen
    @Binding var isCameraStreaming: Bool
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var udpStreamer: UDPStreamer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Bar with Back Button
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeScreen = .home
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                        Text("CAMERA STREAM")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.top, 16)
            
            // Camera Stream preview frame
            ZStack {
                if isCameraStreaming {
                    CameraStreamView(cameraManager: cameraManager, udpStreamer: udpStreamer)
                        .padding(8)
                        .background(Color.black)
                        .border(Color.white, width: 2)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "video.slash.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("STREAM IS OFF")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .padding(.vertical, 32)
                    .background(Color.black)
                    .border(Color.white, width: 2)
                }
            }
            
            // Toggle stream ON/OFF button
            Button(action: {
                withAnimation {
                    isCameraStreaming.toggle()
                }
            }) {
                Text(isCameraStreaming ? "TURN OFF STREAM" : "TURN ON STREAM")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(isCameraStreaming ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCameraStreaming ? Color.white : Color.black)
                    .border(Color.white, width: 2)
            }
            .padding(.top, 16)
            
            Spacer()
            
            HStack {
                Spacer()
                BottomBrandingIcon()
                Spacer()
            }
        }
        .padding(.bottom, 8)
    }
}

struct TilesView: View {
    @Binding var activeScreen: ActiveScreen
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .home
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("TILES")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                
                // Tiles Content
                VStack(spacing: 16) {
                    Text("ACTIVE TILES")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // A grid of active widgets
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        TileCard(title: "ACTIVITY", icon: "figure.walk", description: "8,432 STEPS")
                        TileCard(title: "WEATHER", icon: "cloud.sun.fill", description: "72°F SUNNY")
                        TileCard(title: "CALENDAR", icon: "calendar", description: "3 EVENTS")
                        TileCard(title: "BATTERY", icon: "battery.100", description: "85% SECURE")
                    }
                }
                .padding(16)
                .background(Color.black)
                .border(Color.white, width: 2)
                
                Spacer(minLength: 24)
                
                HStack {
                    Spacer()
                    BottomBrandingIcon()
                    Spacer()
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct TileCard: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(description)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.04))
        .border(Color.white.opacity(0.3), width: 1.5)
    }
}

struct SettingsView: View {
    @Binding var activeScreen: ActiveScreen
    @State private var notificationsEnabled = true
    @State private var brightnessValue: Double = 0.8
    @State private var healthSyncEnabled = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .home
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("SETTINGS")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                
                VStack(spacing: 20) {
                    // Notifications
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NOTIFICATIONS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Push case alerts to screen")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 31/255, green: 105/255, blue: 255/255)))
                            .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1.5)
                    
                    // Display Brightness
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("DISPLAY BRIGHTNESS")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(brightnessValue * 100))%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Slider(value: $brightnessValue)
                            .accentColor(Color(red: 31/255, green: 105/255, blue: 255/255))
                    }
                    .padding(.vertical, 8)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1.5)
                    
                    // Health Sync
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("APPLE HEALTH SYNC")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Send daily metrics to case")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Toggle("", isOn: $healthSyncEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 31/255, green: 105/255, blue: 255/255)))
                            .labelsHidden()
                    }
                    .padding(.vertical, 8)
                }
                .padding(16)
                .background(Color.black)
                .border(Color.white, width: 2)
                
                Spacer(minLength: 24)
                
                HStack {
                    Spacer()
                    BottomBrandingIcon()
                    Spacer()
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct TipsView: View {
    @Binding var activeScreen: ActiveScreen
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .home
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("TIPS & USER GUIDE")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("QUICK GUIDE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    TipRow(number: "01", text: "Turn on Bluetooth on your iPhone before starting scanning.")
                    TipRow(number: "02", text: "Touch the Capacitive Sensor on the case back to cycle active layouts.")
                    TipRow(number: "03", text: "Connect to SSID 'OverByte_AP' to start UDP Video Camera stream.")
                    TipRow(number: "04", text: "Tap the watch faces in the Faces menu to sync the layout over BLE instantly.")
                }
                .padding(16)
                .background(Color.black)
                .border(Color.white, width: 2)
                
                Spacer(minLength: 24)
                
                HStack {
                    Spacer()
                    BottomBrandingIcon()
                    Spacer()
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct TipRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 31/255, green: 105/255, blue: 255/255))
                .padding(6)
                .background(Color.white.opacity(0.08))
                .border(Color.white.opacity(0.3), width: 1)
            
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
    }
}

struct StoreView: View {
    @Binding var activeScreen: ActiveScreen
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeScreen = .home
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("STORE")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                
                VStack(spacing: 16) {
                    Text("OFFICIAL MERCHANDISE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    StoreItemCard(name: "OVERBYTE PHONE CASE", price: "$49.99", imageSystemName: "candybarphone")
                    StoreItemCard(name: "REPLACEMENT ACCENT BUTTONS", price: "$9.99", imageSystemName: "circle.grid.2x1.fill")
                    StoreItemCard(name: "GLOW IN THE DARK DECALS", price: "$14.99", imageSystemName: "sparkles")
                }
                .padding(16)
                .background(Color.black)
                .border(Color.white, width: 2)
                
                Spacer(minLength: 24)
                
                HStack {
                    Spacer()
                    BottomBrandingIcon()
                    Spacer()
                }
            }
            .padding(.bottom, 8)
        }
    }
}

struct StoreItemCard: View {
    let name: String
    let price: String
    let imageSystemName: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: imageSystemName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08))
                .border(Color.white.opacity(0.3), width: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(price)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 31/255, green: 105/255, blue: 255/255))
            }
            
            Spacer()
            
            Text("BUY")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(Color.white)
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .border(Color.white.opacity(0.12), width: 1)
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
            if style == 0 {
                RetroClockPreviewView()
                    .frame(width: 140, height: 100)
            } else if style == 1 {
                AnalogClockPreviewView()
                    .frame(width: 140, height: 100)
            } else if style == 2 {
                BinaryClockPreviewView()
                    .frame(width: 140, height: 100)
            }
        }
    }
}

struct RetroClockPreviewView: View {
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 6) {
            let timeString = timeString(from: currentDate)
            let secondString = secondString(from: currentDate)
            
            // Styled matrix digital readout
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(secondString)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .border(Color.white, width: 1.5)
            
            HStack {
                Text("SYS_OK")
                Spacer()
                Text("SYNCED")
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
            .frame(width: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onReceive(timer) { input in
            currentDate = input
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func secondString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter.string(from: date)
    }
}

struct AnalogClockPreviewView: View {
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 * 0.85
            
            ZStack {
                Color.black
                
                // Clock Face border
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                
                // Center Dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .position(center)
                
                // Tick Marks
                Path { path in
                    let tickLen: CGFloat = 4
                    // 12 o'clock
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y - radius + tickLen))
                    
                    // 6 o'clock
                    path.move(to: CGPoint(x: center.x, y: center.y + radius))
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius - tickLen))
                    
                    // 3 o'clock
                    path.move(to: CGPoint(x: center.x + radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x + radius - tickLen, y: center.y))
                    
                    // 9 o'clock
                    path.move(to: CGPoint(x: center.x - radius, y: center.y))
                    path.addLine(to: CGPoint(x: center.x - radius + tickLen, y: center.y))
                }
                .stroke(Color.white, lineWidth: 1.5)
                
                // Hands calculations
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
                let hour = CGFloat(components.hour ?? 0)
                let minute = CGFloat(components.minute ?? 0)
                let second = CGFloat(components.second ?? 0)
                
                let hourAngle = (hour * 30.0) + (minute * 0.5)
                let minuteAngle = (minute * 6.0) + (second * 0.1)
                let secondAngle = second * 6.0
                
                // Hour Hand
                Capsule()
                    .fill(Color.white)
                    .frame(width: 3, height: radius * 0.5)
                    .offset(y: -radius * 0.25)
                    .rotationEffect(.degrees(hourAngle))
                    .position(center)
                
                // Minute Hand
                Capsule()
                    .fill(Color.white)
                    .frame(width: 2, height: radius * 0.75)
                    .offset(y: -radius * 0.375)
                    .rotationEffect(.degrees(minuteAngle))
                    .position(center)
                
                // Second Hand
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 1.5, height: radius * 0.85)
                    .offset(y: -radius * 0.425)
                    .rotationEffect(.degrees(secondAngle))
                    .position(center)
            }
        }
        .background(Color.black)
        .onReceive(timer) { input in
            currentDate = input
        }
    }
}

struct BinaryClockPreviewView: View {
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let spacingX = w / 7
            let spacingY = h / 6
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: currentDate)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let second = components.second ?? 0
            
            let hrTens = hour / 10
            let hrOnes = hour % 10
            let minTens = minute / 10
            let minOnes = minute % 10
            let secTens = second / 10
            let secOnes = second % 10
            
            HStack(spacing: spacingX * 0.8) {
                Spacer(minLength: 0)
                BinaryColumn(val: hrTens, rows: 2, spacing: spacingY * 0.7)
                BinaryColumn(val: hrOnes, rows: 4, spacing: spacingY * 0.7)
                BinaryColumn(val: minTens, rows: 3, spacing: spacingY * 0.7)
                BinaryColumn(val: minOnes, rows: 4, spacing: spacingY * 0.7)
                BinaryColumn(val: secTens, rows: 3, spacing: spacingY * 0.7)
                BinaryColumn(val: secOnes, rows: 4, spacing: spacingY * 0.7)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .background(Color.black)
        .onReceive(timer) { input in
            currentDate = input
        }
    }
}

struct BinaryColumn: View {
    let val: Int
    let rows: Int
    let spacing: CGFloat
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach((0..<rows).reversed(), id: \.self) { row in
                let bit = (val >> row) & 1
                Circle()
                    .stroke(Color.white, lineWidth: 1)
                    .background(Circle().fill(bit == 1 ? Color.white : Color.clear))
                    .frame(width: 6, height: 6)
            }
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

// MARK: - Pixel Art Icons

struct RobotFaceIcon: View {
    var body: some View {
        VStack(spacing: 2) {
            // Antenna
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 8)
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .offset(y: -4)
            }
            // Head
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black))
                    .frame(width: 32, height: 26)
                
                // Eyes
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
}

struct CameraIcon: View {
    var body: some View {
        HStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white, lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.black))
                    .frame(width: 30, height: 20)
                
                // Red dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            }
            
            // Lens piece
            Path { path in
                path.move(to: CGPoint(x: 0, y: 3))
                path.addLine(to: CGPoint(x: 6, y: 0))
                path.addLine(to: CGPoint(x: 6, y: 12))
                path.addLine(to: CGPoint(x: 0, y: 9))
                path.closeSubpath()
            }
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 6, height: 12)
        }
        .frame(height: 26)
    }
}

struct TilesIcon: View {
    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.8)
                    .frame(width: 9, height: 9)
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.8)
                    .frame(width: 9, height: 9)
            }
            HStack(spacing: 3) {
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.8)
                    .frame(width: 9, height: 9)
                Rectangle()
                    .stroke(Color.white, lineWidth: 1.8)
                    .frame(width: 9, height: 9)
            }
        }
        .frame(height: 26)
    }
}

struct GearIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 20, height: 20)
            
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 3.5, height: 5)
                    .offset(y: -10)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .frame(width: 26, height: 26)
    }
}

struct LightbulbIcon: View {
    var body: some View {
        VStack(spacing: 1) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 16, height: 16)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
            }
            Rectangle()
                .fill(Color.white)
                .frame(width: 8, height: 3)
            Rectangle()
                .fill(Color.red)
                .frame(width: 4, height: 2)
        }
        .frame(width: 26, height: 26)
    }
}

struct BagIcon: View {
    var body: some View {
        VStack(spacing: 0) {
            Path { path in
                path.addArc(center: CGPoint(x: 8, y: 6), radius: 5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            }
            .stroke(Color.red, lineWidth: 1.8)
            .frame(width: 16, height: 6)
            
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.white, lineWidth: 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.black))
                .frame(width: 20, height: 16)
        }
        .frame(width: 26, height: 26)
    }
}

struct BottomBrandingIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 50, height: 50)
            
            VStack(spacing: 3) {
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(Color(red: 31/255, green: 105/255, blue: 255/255))
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color(red: 31/255, green: 105/255, blue: 255/255))
                        .frame(width: 8, height: 8)
                }
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(Color(red: 31/255, green: 105/255, blue: 255/255))
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color(red: 31/255, green: 105/255, blue: 255/255))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Circular Previews

struct CircularClassicPreview: View {
    let index: Int
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 2)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(Color.white.opacity(0.02)))
                
                if index == 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 64, height: 64)
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 14, height: 14)
                            .offset(y: -10)
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 14, height: 14)
                            .offset(x: -10, y: 8)
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 14, height: 14)
                            .offset(x: 10, y: 8)
                    }
                } else if index == 1 {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 64, height: 64)
                        Text("N")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.red)
                            .offset(y: -22)
                        Text("S")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: 22)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 16, y: 40))
                            path.addLine(to: CGPoint(x: 32, y: 18))
                            path.addLine(to: CGPoint(x: 48, y: 40))
                            path.closeSubpath()
                        }
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .frame(width: 64, height: 64)
                        
                        ForEach(0..<12, id: \.self) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 1, height: 3)
                                .offset(y: -28)
                                .rotationEffect(.degrees(Double(i) * 30))
                        }
                        
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 1.5, height: 20)
                            .offset(y: -10)
                            .rotationEffect(.degrees(290))
                    }
                }
            }
            
            Text(classicName.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
    
    private var classicName: String {
        switch index {
        case 0: return "Chrono"
        case 1: return "Compass"
        case 2: return "Minimalist"
        default: return ""
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
            .border(Color.white.opacity(0.1), width: 1)
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
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif") {
            let html = "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'><style>html, body { margin: 0; padding: 0; width: 100vw; height: 100vh; overflow: hidden; display: flex; justify-content: center; align-items: center; background-color: black; } img { max-width: 100%; max-height: 100%; object-fit: contain; }</style></head><body><img src='\(url.absoluteString)'></body></html>"
            uiView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {}
}
