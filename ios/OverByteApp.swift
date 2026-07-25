import SwiftUI

@main
struct OverByteApp: App {
    // Keep BLE Manager alive for the lifecycle of the app
    @StateObject private var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
                .preferredColorScheme(.dark)
        }
    }
}
