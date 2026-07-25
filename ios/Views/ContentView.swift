import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bleManager: BLEManager
    
    // Track local segmented control index (0: Clock, 1: Emote, 2: Camera)
    @State private var selectedMode = 0
    @State private var lastSyncedTimeText = "Never"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        // --- HEADER / HERO SECTION ---
                        VStack(spacing: 12) {
                            Text("OVERBYTE")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            // Connection status pill & battery level pill
                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(bleManager.isConnected ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                    Text(bleManager.connectionStatusText.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(bleManager.isConnected ? .green : .red)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(bleManager.isConnected ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1)
                                )
                                
                                if bleManager.isConnected {
                                    BatteryIndicatorView(level: bleManager.batteryLevel)
                                }
                            }
                            
                            // Disconnect/Scan capsule button
                            if bleManager.isConnected {
                                Button(action: {
                                    bleManager.disconnect()
                                }) {
                                    Text("DISCONNECT")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 10)
                                        .background(Color.black)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.red, lineWidth: 1)
                                        )
                                }
                                .padding(.top, 4)
                            } else {
                                Button(action: {
                                    bleManager.startScanning()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("SCAN DEVICE")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Color.black)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 16)
                        
                        // --- DISCOVERED DEVICES LIST (SCANNING) ---
                        if !bleManager.isConnected && !bleManager.discoveredPeripherals.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DISCOVERED DEVICES")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                
                                VStack(spacing: 8) {
                                    ForEach(bleManager.discoveredPeripherals, id: \.identifier) { device in
                                        Button(action: {
                                            bleManager.connect(to: device)
                                        }) {
                                            HStack {
                                                Image(systemName: "candybarphone")
                                                    .foregroundColor(.white)
                                                Text((device.name ?? "UNKNOWN DEVICE").uppercased())
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                            }
                                            .padding(14)
                                            .background(Color.white.opacity(0.02))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(18)
                            .background(Color.black)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white, lineWidth: 1)
                            )
                        }
                        
                        // --- MODE NAVIGATION ---
                        HStack(spacing: 12) {
                            ModePillButton(title: "Clock", index: 0, selectedIndex: $selectedMode, isEnabled: bleManager.isConnected) {
                                bleManager.sendMode(0)
                            }
                            ModePillButton(title: "Emote", index: 1, selectedIndex: $selectedMode, isEnabled: bleManager.isConnected) {
                                bleManager.sendMode(1)
                            }
                            ModePillButton(title: "Camera", index: 2, selectedIndex: $selectedMode, isEnabled: bleManager.isConnected) {
                                bleManager.sendMode(2)
                            }
                        }
                        .padding(.horizontal, 12)
                        .opacity(bleManager.isConnected ? 1.0 : 0.5)
                        
                        // --- ACTIONS / UTILITIES (BY ACTIVE MODE) ---
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
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        } else {
                            if selectedMode == 0 {
                                // CLOCK SECTION
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("WATCH FACES")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            WatchFaceCard(name: "Retro", imageName: "placeholder")
                                            WatchFaceCard(name: "Binary", imageName: "placeholder")
                                            WatchFaceCard(name: "Analog", imageName: "placeholder")
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 4)
                                    }
                                    
                                    // Sync Time Card
                                    Button(action: {
                                        bleManager.syncTime()
                                        let formatter = DateFormatter()
                                        formatter.timeStyle = .medium
                                        lastSyncedTimeText = formatter.string(from: Date())
                                    }) {
                                        VStack(spacing: 10) {
                                            HStack {
                                                Image(systemName: "clock.arrow.2.circlepath")
                                                    .font(.system(size: 16))
                                                Text("SYNC TIME WITH IPHONE")
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            }
                                            .foregroundColor(.white)
                                            
                                            HStack {
                                                Text("LAST SYNCED:")
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(.gray)
                                                Text(lastSyncedTimeText.uppercased())
                                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(Color.black)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                    }
                                }
                            } else if selectedMode == 1 {
                                // EMOTE SECTION
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("EMOTE GALLERY")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            EmoteCard(name: "Idle", imageName: "placeholder", gesture: "Default Face")
                                            EmoteCard(name: "What", imageName: "placeholder", gesture: "1 Tap")
                                            EmoteCard(name: "Judging", imageName: "placeholder", gesture: "2+ Taps")
                                            EmoteCard(name: "Happy", imageName: "placeholder", gesture: "Rub/Hold")
                                            EmoteCard(name: "Angry", imageName: "placeholder", gesture: "Rub > 15s")
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 4)
                                    }
                                }
                            } else if selectedMode == 2 {
                                // CAMERA STREAM SECTION
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("CAMERA STREAM")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                    
                                    CameraStreamView()
                                        .padding(8)
                                        .background(Color.black)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ModePillButton: View {
    let title: String
    let index: Int
    @Binding var selectedIndex: Int
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedIndex = index
                }
                action()
            }
        }) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(selectedIndex == index ? .black : .white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(selectedIndex == index ? Color.white : Color.black)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedIndex == index ? Color.clear : Color.white, lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
    }
}

struct WatchFaceCard: View {
    let name: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                
                Image(imageName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
            }
            
            Text(name.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

struct EmoteCard: View {
    let name: String
    let imageName: String
    let gesture: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: 140, height: 140)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                
                Image(imageName)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(gesture.uppercased())
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct BatteryIndicatorView: View {
    let level: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(batteryColor)
                .scaleEffect(level <= 30 && isPulsing ? 1.15 : 1.0)
                .opacity(level <= 30 && isPulsing ? 0.4 : 1.0)
            
            Text("\(level)%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(batteryColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(batteryColor.opacity(0.4), lineWidth: 1)
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
