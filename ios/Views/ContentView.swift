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
                                    .frame(width: 10, height: 10)
                                    .shadow(color: bleManager.isConnected ? .white : .red, radius: 4)
                                
                                Text(bleManager.connectionStatusText.uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if bleManager.isConnected {
                                    Button(action: {
                                        bleManager.disconnect()
                                    }) {
                                        Text("DISCONNECT")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.red, lineWidth: 1.5)
                                            )
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
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color.white, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                            
                            // Discovered devices list when searching
                            if !bleManager.isConnected && !bleManager.discoveredPeripherals.isEmpty {
                                Divider().background(Color.white.opacity(0.3))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("DISCOVERED DEVICES:")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    
                                    ForEach(bleManager.discoveredPeripherals, id: \.identifier) { device in
                                        Button(action: {
                                            bleManager.connect(to: device)
                                        }) {
                                            HStack {
                                                Image(systemName: "candybarphone")
                                                    .foregroundColor(.white)
                                                Text((device.name ?? "UNKNOWN DEVICE").uppercased())
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.white)
                                            }
                                            .padding(10)
                                            .background(Color.white.opacity(0.08))
                                            .overlay(
                                                Rectangle()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.black)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        
                        // --- MODE SELECTOR CARD ---
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SELECT MAIN MODE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Picker("System Mode", selection: $selectedMode) {
                                Text("Clock").tag(0)
                                Text("Mochi").tag(1)
                                Text("Camera").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedMode) { newValue in
                                bleManager.sendMode(UInt8(newValue))
                            }
                            .disabled(!bleManager.isConnected)
                            
                            if !bleManager.isConnected {
                                Text("Connect to your Mochi case via Bluetooth to switch modes.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(18)
                        .background(Color.black)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        
                        // --- ACTIONS / UTILITIES ---
                        if selectedMode == 0 && bleManager.isConnected {
                            // Clock Face controls
                            VStack(spacing: 16) {
                                Button(action: {
                                    bleManager.syncTime()
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .medium
                                    lastSyncedTimeText = formatter.string(from: Date())
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.2.circlepath")
                                        Text("SYNC TIME WITH IPHONE")
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )
                                }
                                
                                HStack {
                                    Text("LAST SYNCED:")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(lastSyncedTimeText.uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(18)
                            .background(Color.black)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                        } else if selectedMode == 1 && bleManager.isConnected {
                            // Mochi information
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "face.smiling")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                    Text("MOCHI EMOTION GUIDE")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Interact with the Capacitive Touch Sensor on the phone case to play animations:")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Idle: Default Face", systemName: "dot.circle").foregroundColor(.white)
                                    Label("1 Tap: What Face (2s)", systemName: "dot.circle").foregroundColor(.white)
                                    Label("2 Taps: Judging Face (2.5s)", systemName: "dot.circle").foregroundColor(.white)
                                    Label("Rub/Hold: Happy Face", systemName: "dot.circle").foregroundColor(.white)
                                    Label("Rub > 15s: Angry Face", systemName: "dot.circle").foregroundColor(.white)
                                }
                                .font(.system(size: 12, design: .monospaced))
                                .padding(.top, 4)
                            }
                            .padding(18)
                            .background(Color.black)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 1.5)
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
