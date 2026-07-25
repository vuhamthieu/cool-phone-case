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
                    .tracking(1)
                
                Text(secondString)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 1.5)
            )
            
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
                    .fill(Color.white)
                    .frame(width: 1, height: radius * 0.85)
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
                    
                    if title == "Retro" {
                        RetroClockPreviewView()
                            .frame(width: 70, height: 70)
                            .scaleEffect(0.8)
                    } else if title == "Analog" {
                        AnalogClockPreviewView()
                            .frame(width: 70, height: 70)
                    } else if title == "Binary" {
                        BinaryClockPreviewView()
                            .frame(width: 70, height: 70)
                            .scaleEffect(0.8)
                    } else {
                        GifImageView(gifName: gifName, fallbackSystemName: fallbackIcon)
                            .frame(width: 80, height: 80)
                    }
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
