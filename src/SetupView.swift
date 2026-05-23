import SwiftUI

struct SetupView: View {
    let calendarManager: CalendarManager
    let settingsManager: SettingsManager
    let onTestFlight: () -> Void
    
    @State private var calendarStatus: String = "Checking..."
    @State private var isAuthorized: Bool = false
    @State private var selectedColor: String = "white"
    @State private var selectedSize: String = "medium"
    @State private var selectedSpeed: String = "medium"
    @State private var selectedBg: String = "dark"
    @State private var selectedText: String = "white"
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            VStack(spacing: 3) {
                Text("🛫 Flight Notifier Setup")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Calendar Meeting Overlay")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 6)
            
            // Permissions Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("System Permissions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Text("Calendar Access:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(calendarStatus)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(isAuthorized ? .green : .orange)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Flight Customization Panel
            VStack(alignment: .leading, spacing: 10) {
                Text("Flight Customization")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                // Color selector
                HStack {
                    Text("Airplane Color:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(["white", "blue", "amber", "green"], id: \.self) { colorName in
                            Button(action: {
                                selectedColor = colorName
                                settingsManager.setAirplaneColor(colorName)
                            }) {
                                Circle()
                                    .fill(colorValue(for: colorName))
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == colorName ? 2.5 : 0)
                                    )
                                    .shadow(color: colorValue(for: colorName).opacity(0.3), radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Size selector
                HStack {
                    Text("Notification Width:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(["small", "medium", "large"], id: \.self) { sizeName in
                            Button(action: {
                                selectedSize = sizeName
                                settingsManager.setBannerSize(sizeName)
                            }) {
                                Text(sizeName.capitalized)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedSize == sizeName ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedSize == sizeName ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Speed selector
                HStack {
                    Text("Flight Speed:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(["slow", "medium", "fast"], id: \.self) { speedName in
                            Button(action: {
                                selectedSpeed = speedName
                                settingsManager.setFlightSpeed(speedName)
                            }) {
                                Text(speedName.capitalized)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedSpeed == speedName ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedSpeed == speedName ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Card Background selector (Solid options)
                HStack {
                    Text("Card Background:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(["dark", "light", "blue", "black"], id: \.self) { bgName in
                            Button(action: {
                                selectedBg = bgName
                                settingsManager.setCardBackground(bgName)
                            }) {
                                Text(bgName.uppercased())
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(selectedBg == bgName ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedBg == bgName ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.05))
                
                // Text Color selector
                HStack {
                    Text("Text Color:")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(["white", "black", "yellow", "amber"], id: \.self) { textColorName in
                            Button(action: {
                                selectedText = textColorName
                                settingsManager.setTextColor(textColorName)
                            }) {
                                Text(textColorName.uppercased())
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(selectedText == textColorName ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(selectedText == textColorName ? Color.amber : Color.white.opacity(0.06))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Test Button
            Button(action: onTestFlight) {
                HStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.system(size: 12, weight: .bold))
                    Text("Test Flight Animation Now")
                        .font(.system(size: 11.5, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.amber)
                .cornerRadius(8)
                .shadow(color: Color.amber.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            
            // Help description
            Text("Click on the 'Join' button on the banner as it flies to directly launch your Zoom/Meet link. You can also click 'X' to dismiss it instantly.")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .padding(14)
        .frame(width: 400, height: 540)
        .background(Color(red: 25/255, green: 25/255, blue: 35/255))
        .onAppear {
            selectedColor = settingsManager.airplaneColor()
            selectedSize = settingsManager.bannerSize()
            selectedSpeed = settingsManager.flightSpeed()
            selectedBg = settingsManager.cardBackground()
            selectedText = settingsManager.textColor()
            checkPermission()
        }
    }
    
    func colorValue(for name: String) -> Color {
        switch name {
        case "blue": return Color(red: 0/255, green: 150/255, blue: 255/255)
        case "amber": return Color.amber
        case "green": return Color(red: 46/255, green: 204/255, blue: 113/255)
        default: return .white
        }
    }
    
    func checkPermission() {
        calendarManager.fetchUpcomingEvents { events in
            DispatchQueue.main.async {
                isAuthorized = true
                calendarStatus = "Granted (via Python)"
            }
        }
    }
    
    func requestPermission() {
        checkPermission()
    }
}
