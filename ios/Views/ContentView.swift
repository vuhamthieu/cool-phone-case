import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    // Track local segmented control index
    @State private var selectedMode = 0
    @State private var lastSyncedTimeText = "Never"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // --- HEADER BAR ---
                        VStack(spacing: 4) {
                            Text("MOCHI SECOND SCREEN")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("CASE DASHBOARD")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)
                        
                        // --- CONNECTION CARD ---
                        VStack(spacing: 16) {
                            HStack {
                                Circle()
                                    .fill(bleManager.isConnected ? Color.white : Color.red)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: bleManager.isConnected ? .white : .red, radius: 4)
                                
                                Text(bleManager.connectionStatusText.uppercased())
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if bleManager.isConnected {
                                    HStack(spacing: 12) {
                                        BatteryIndicatorView(level: bleManager.batteryLevel)
                                        
                                        Button(action: {
                                            bleManager.disconnect()
                                        }) {
                                            Text("DISCONNECT")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(.red)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                                )
                                        }
                                    }
                                } else {
                                    Button(action: {
                                        bleManager.startScanning()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("SCAN")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Discovered devices list when searching
                            if !bleManager.isConnected && !bleManager.discoveredPeripherals.isEmpty {
                                Divider().background(Color.gray.opacity(0.3))
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("DISCOVERED DEVICES:")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    
                                    ForEach(bleManager.discoveredPeripherals, id: \.identifier) { device in
                                        Button(action: {
                                            bleManager.connect(to: device)
                                        }) {
                                            HStack {
                                                Image(systemName: "candybarphone")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 14))
                                                Text((device.name ?? "UNKNOWN DEVICE").uppercased())
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 12))
                                            }
                                            .padding(12)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                        )
                        
                        // --- MODE SELECTOR CARD (MODERNIZED) ---
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SELECT MAIN MODE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            ModernSegmentedControl(
                                selectedIndex: $selectedMode,
                                options: ["Clock", "Mochi", "Camera"],
                                isEnabled: bleManager.isConnected,
                                onChange: { newValue in
                                    bleManager.sendMode(UInt8(newValue))
                                }
                            )
                            
                            if !bleManager.isConnected {
                                Text("Connect to your Mochi case via Bluetooth to switch modes.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                        )
                        
                        // --- ACTIONS / UTILITIES ---
                        if selectedMode == 0 && bleManager.isConnected {
                            // Clock Face controls
                            VStack(alignment: .leading, spacing: 16) {
                                Text("MY WATCH FACES")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        WatchFaceCard(name: "Retro Digital", symbol: "clock")
                                        WatchFaceCard(name: "Analog", symbol: "dial.low")
                                        WatchFaceCard(name: "Binary", symbol: "timer")
                                    }
                                    .padding(.vertical, 4)
                                }
                                
                                Button(action: {
                                    bleManager.syncTime()
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .medium
                                    lastSyncedTimeText = formatter.string(from: Date())
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                        Text("SYNC TIME WITH IPHONE")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                                }
                                
                                HStack {
                                    Spacer()
                                    Text("LAST SYNCED:")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(lastSyncedTimeText.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                            )
                        } else if selectedMode == 1 && bleManager.isConnected {
                            // Mochi Visual Emotion Grid
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("MOCHI EMOTION GUIDE")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text("Interact with the capacitive touch sensor on the case to trigger these expressions:")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 4)
                                
                                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                    MochiEmotionCard(name: "Idle", symbol: "face.smiling", gesture: "Default Face")
                                    MochiEmotionCard(name: "What", symbol: "questionmark.circle", gesture: "1 Tap")
                                    MochiEmotionCard(name: "Judging", symbol: "eye.circle", gesture: "2+ Taps")
                                    MochiEmotionCard(name: "Happy", symbol: "face.smiling.fill", gesture: "Rub/Hold")
                                    MochiEmotionCard(name: "Angry", symbol: "flame.fill", gesture: "Rub > 15s")
                                }
                            }
                            .padding(18)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                            )
                        } else if selectedMode == 2 && bleManager.isConnected {
                            // Camera Streaming View!
                            CameraStreamView()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ModernSegmentedControl: View {
    @Binding var selectedIndex: Int
    let options: [String]
    let isEnabled: Bool
    let onChange: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: {
                    if isEnabled {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                        onChange(index)
                    }
                }) {
                    Text(options[index].uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(selectedIndex == index ? .black : (isEnabled ? .white : .gray))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedIndex == index {
                                    Color.white
                                        .cornerRadius(8)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}

struct WatchFaceCard: View {
    let name: String
    let symbol: String
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: symbol)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            Text(name.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(width: 100)
    }
}

struct MochiEmotionCard: View {
    let name: String
    let symbol: String
    let gesture: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(name.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(gesture.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct BatteryIndicatorView: View {
    let level: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(batteryColor)
                .scaleEffect(level <= 30 && isPulsing ? 1.15 : 1.0)
                .opacity(level <= 30 && isPulsing ? 0.4 : 1.0)
            
            Text("\(level)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(batteryColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(batteryColor, lineWidth: 1)
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
