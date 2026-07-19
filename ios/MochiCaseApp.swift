import SwiftUI

@main
struct MochiCaseApp: App {
    // Keep BLE Manager alive for the lifecycle of the app
    @StateObject private var bleManager = BLEManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bleManager)
                .preferredColorScheme(.dark) // Dark mode fits the premium Mochi case theme
        }
    }
}
