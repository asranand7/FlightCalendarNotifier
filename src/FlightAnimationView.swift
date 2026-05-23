import SwiftUI

struct FlightAnimationView: View {
    let eventTitle: String
    let minutesRemaining: Int
    let screenWidth: CGFloat
    let bannerWidth: CGFloat
    let bannerHeight: CGFloat
    let flightSpeedName: String
    let cardBgName: String
    let fontColorName: String
    
    // Calendar event metadata
    let startDate: Date?
    let endDate: Date?
    let platform: String?
    let meetingUrl: String?
    
    let animationThemeName: String

    let onClose: () -> Void
    let onHoverEnter: () -> Void
    let onHoverExit: () -> Void
    
    @State private var pitchAngle: Double = -5.0
    @State private var bobOffset: CGFloat = -4.0
    @State private var spinAngle: Double = 0.0
    @State private var scaleVal: CGFloat = 0.9
    
    private var cardWidth: CGFloat {
        return bannerWidth
    }

    private var cardHeight: CGFloat {
        return bannerHeight
    }
    
    private var startOffset: CGFloat {
        return bannerWidth + 220.0
    }
    
    private var flightDuration: Double {
        switch flightSpeedName.lowercased() {
        case "slow": return 18.0
        case "fast": return 8.0
        default: return 13.0
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.clear
            
            HStack(spacing: 8) {
                // Boarding pass / Banner
                BannerView(
                    title: eventTitle,
                    minutes: minutesRemaining,
                    startDate: startDate,
                    endDate: endDate,
                    platform: platform,
                    meetingUrl: meetingUrl,
                    cardBgName: cardBgName,
                    fontColorName: fontColorName,
                    width: cardWidth,
                    height: cardHeight,
                    onClose: onClose
                )
                
                // Tow line / Vapor trail
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 15))
                    path.addLine(to: CGPoint(x: 35, y: 15))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundColor(Color.white.opacity(0.4))
                .frame(width: 35, height: 30)
                
                // Animated subject (theme-driven)
                themeSubject()
            }
            .offset(x: 10)
            .onHover { hovering in
                if hovering {
                    onHoverEnter()
                } else {
                    onHoverExit()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .onAppear {
            startThemeAnimation()
        }
    }

    private func loadBundleImage(_ name: String) -> NSImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png") else { return nil }
        return NSImage(contentsOfFile: path)
    }

    // Renders a bundled PNG. flipHorizontal mirrors the image to face right (direction of travel).
    @ViewBuilder
    private func bundleImage(_ name: String, width: CGFloat, height: CGFloat, flipHorizontal: Bool = true) -> some View {
        if let img = loadBundleImage(name) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
                .scaleEffect(x: flipHorizontal ? -1 : 1, y: 1)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }

    @ViewBuilder
    private func themeSubject() -> some View {
        switch animationThemeName {
        case "f1car":
            bundleImage("f1car", width: 54, height: 54)
                .offset(y: bobOffset)
        case "motorbike":
            bundleImage("motorbike", width: 52, height: 52)
                .offset(y: bobOffset)
        case "locomotive":
            bundleImage("locomotive", width: 52, height: 52)
                .offset(y: bobOffset)
        case "helicopter":
            bundleImage("helicopter", width: 50, height: 50, flipHorizontal: false)
                .offset(y: bobOffset)
                .rotationEffect(.degrees(pitchAngle * 0.5))
        case "rocket":
            bundleImage("rocket", width: 44, height: 44, flipHorizontal: false)
                .rotationEffect(.degrees(90)) // rockets point up; rotate to fly right
                .offset(y: bobOffset)
        case "dinosaur":
            Text("🦕")
                .font(.system(size: 32))
                .offset(y: bobOffset)
        default:
            if animationThemeName.hasPrefix("emoji:") {
                let emoji = String(animationThemeName.dropFirst(6))
                Text(emoji.isEmpty ? "✈️" : emoji)
                    .font(.system(size: 30))
                    .offset(y: bobOffset)
            } else {
                // airplane (default)
                bundleImage("airplane", width: 48, height: 48, flipHorizontal: false)
                    .rotationEffect(.degrees(pitchAngle))
                    .offset(y: pitchAngle > 0 ? 2 : -2)
            }
        }
    }

    private func startThemeAnimation() {
        switch animationThemeName {
        case "f1car", "motorbike", "locomotive", "dinosaur":
            withAnimation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bobOffset = 5.0
            }
        case "helicopter":
            // gentle combined bob + slight pitch
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                bobOffset = 4.0
                pitchAngle = 4.0
            }
        case "rocket":
            withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                bobOffset = 6.0
            }
        default:
            if animationThemeName.hasPrefix("emoji:") {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bobOffset = 4.0
                }
            } else {
                // airplane — pitch oscillation
                withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pitchAngle = 5.0
                }
            }
        }
    }
}

struct BannerView: View {
    let title: String
    let minutes: Int
    let startDate: Date?
    let endDate: Date?
    let platform: String?
    let meetingUrl: String?
    let cardBgName: String
    let fontColorName: String
    let width: CGFloat
    let height: CGFloat
    let onClose: () -> Void
    
    private var timeRangeString: String {
        guard let start = startDate else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        if let end = endDate {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        } else {
            return "Due at \(formatter.string(from: start))"
        }
    }
    
    private var isTodoist: Bool { platform?.lowercased().contains("todoist") == true }

    private var platformIcon: String {
        guard let plat = platform?.lowercased() else { return "calendar" }
        if plat.contains("meet") { return "video" }
        if plat.contains("zoom") { return "video.circle" }
        if plat.contains("teams") { return "video" }
        return "mappin.and.ellipse"
    }
    
    // Style Map: Background Color (Solid, no transparency for legibility)
    private var cardBgColor: Color {
        if cardBgName.hasPrefix("#") {
            return Color(hex: cardBgName)
        }
        switch cardBgName.lowercased() {
        case "light": return Color(red: 248/255, green: 248/255, blue: 248/255)
        case "blue": return Color(red: 15/255, green: 30/255, blue: 75/255)
        case "black": return Color.black
        default: return Color(red: 32/255, green: 34/255, blue: 44/255) // solid dark gray
        }
    }
    
    // Style Map: Text Color
    private var textColor: Color {
        if fontColorName.hasPrefix("#") {
            return Color(hex: fontColorName)
        }
        switch fontColorName.lowercased() {
        case "black": return Color.black
        case "yellow": return Color.yellow
        case "amber": return Color.amber
        default: return Color.white
        }
    }
    
    private var headerColor: Color {
        return textColor.opacity(0.7)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                // Left Content (Details)
                VStack(alignment: .leading, spacing: 6) {
                    // Highlighted Countdown Badge & Header
                    HStack(spacing: 6) {
                        Text("\(minutes) MINS")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white) // High contrast white text
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Color.red) // Vibrant red badge
                            .cornerRadius(4)
                            .shadow(color: Color.red.opacity(0.2), radius: 2)
                        
                        Text("STARTING SOON")
                            .font(.system(size: 8.5, weight: .black))
                            .foregroundColor(textColor.opacity(0.6))
                            .tracking(1.0)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.bottom, 1)
                    
                    Text(title.uppercased())
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if startDate != nil {
                        Text(timeRangeString)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(textColor.opacity(0.75))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Platform Badge (Right side stub)
                if let plat = platform {
                    Spacer(minLength: 0)
                    
                    TicketDivider()
                        .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 4]))
                        .foregroundColor(textColor.opacity(0.2))
                        .frame(width: 1)
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .center, spacing: 5) {
                        if isTodoist {
                            VStack(spacing: 4) {
                                TodoistLogo(size: 28)
                                if let urlString = meetingUrl, let url = URL(string: urlString) {
                                    Button(action: { NSWorkspace.shared.open(url); onClose() }) {
                                        Text("Open")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue)
                                            .cornerRadius(5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else if let urlString = meetingUrl, let _ = URL(string: urlString) {
                            Button(action: {
                                if let url = URL(string: urlString) {
                                    NSWorkspace.shared.open(url)
                                }
                                onClose()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: platformIcon)
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Join")
                                        .font(.system(size: 10.5, weight: .black))
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(cardBgColor.isLight ? .white : .black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(cardBgColor.isLight ? Color.blue : Color.amber)
                                .cornerRadius(5)
                                .shadow(color: (cardBgColor.isLight ? Color.blue : Color.amber).opacity(0.3), radius: 3)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: platformIcon)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(headerColor)
                            Text(plat)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(textColor)
                                .lineLimit(1)
                                .frame(maxWidth: 80)
                        }
                    }
                    .frame(width: 112)
                }
            }
            
            // Close / Dismiss Button
            Button(action: {
                onClose()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(textColor.opacity(0.5))
                    .padding(5)
                    .background(textColor.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
            .padding(.trailing, 6)
        }
        .frame(width: width + (platform != nil ? 112 : 0), height: height)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBgColor) // Solid background color
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [textColor.opacity(0.3), textColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct TodoistLogo: View {
    let size: CGFloat

    var body: some View {
        if let path = Bundle.main.path(forResource: "todoist", ofType: "png"),
           let img = NSImage(contentsOfFile: path) {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
    }
}

struct TicketDivider: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

extension Color {
    static let amber = Color(red: 255/255, green: 179/255, blue: 0/255)
    
    var isLight: Bool {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return false }
        let luminance = 0.299 * rgbColor.redComponent + 0.587 * rgbColor.greenComponent + 0.114 * rgbColor.blueComponent
        return luminance > 0.65
    }
}
