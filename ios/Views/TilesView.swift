import SwiftUI

struct TilesView: View {
    @EnvironmentObject var bleManager: BLEManager
    @Binding var activeScreen: ActiveScreen

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    activeScreen = .home
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        PixelText("TILES", size: 14, color: .white)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // SMART FEATURES SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        PixelText("SMART FEATURES", size: 9, color: Color(white: 0.5))
                            .padding(.horizontal, 4)

                        VStack(spacing: 0) {
                            // Notifications Row
                            ToggleRow(
                                title: "NOTIFICATIONS",
                                subtitle: "Show incoming alerts on case",
                                iconName: "bell.fill",
                                isOn: Binding(
                                    get: { bleManager.isNotificationEnabled },
                                    set: { newValue in
                                        bleManager.isNotificationEnabled = newValue
                                        bleManager.sendSettings()
                                    }
                                )
                            )
                            
                            Divider().background(Color.white.opacity(0.05))

                            // Media Control Row
                            ToggleRow(
                                title: "MEDIA CONTROL",
                                subtitle: "Control music playback",
                                iconName: "play.circle.fill",
                                isOn: Binding(
                                    get: { bleManager.isMediaControlEnabled },
                                    set: { newValue in
                                        bleManager.isMediaControlEnabled = newValue
                                        bleManager.sendSettings()
                                    }
                                )
                            )
                        }
                        .background(Color(white: 0.07))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// Custom Toggle Row for Samsung Wearable style
struct ToggleRow: View {
    let title: String
    let subtitle: String
    let iconName: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 18) {
            // Large Icon without circle background
            Image(systemName: iconName)
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("PressStart2P-Regular", size: 9))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(subtitle)
                    .font(.custom("PressStart2P-Regular", size: 7))
                    .foregroundColor(Color(white: 0.5))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer(minLength: 0)
            
            // Toggle Switch
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}
