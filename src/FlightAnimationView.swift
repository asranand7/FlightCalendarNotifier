import SwiftUI

struct FlightAnimationView: View {
    let eventTitle: String
    let minutesRemaining: Int
    let screenWidth: CGFloat
    let airplaneColorName: String
    let bannerSizeName: String
    let flightSpeedName: String
    let cardBgName: String
    let fontColorName: String
    
    // Calendar event metadata
    let startDate: Date?
    let endDate: Date?
    let platform: String?
    let meetingUrl: String?
    
    let onClose: () -> Void
    let onHoverEnter: () -> Void
    let onHoverExit: () -> Void
    
    @State private var bobOffset: CGFloat = -6.0
    @State private var pitchAngle: Double = -5.0
    
    private var planeColor: Color {
        switch airplaneColorName.lowercased() {
        case "blue": return Color(red: 0/255, green: 150/255, blue: 255/255)
        case "amber": return Color.amber
        case "green": return Color(red: 46/255, green: 204/255, blue: 113/255)
        default: return .white
        }
    }
    
    private var cardWidth: CGFloat {
        switch bannerSizeName.lowercased() {
        case "small": return 160
        case "large": return 300
        default: return 230
        }
    }
    
    private var startOffset: CGFloat {
        switch bannerSizeName.lowercased() {
        case "small": return 350
        case "large": return 550
        default: return 450
        }
    }
    
    private var flightDuration: Double {
        switch flightSpeedName.lowercased() {
        case "slow": return 12.0
        case "fast": return 5.0
        default: return 8.0
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
                    onClose: onClose
                )
                
                // Tow line / Vapor trail
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 15))
                    path.addLine(to: CGPoint(x: 35, y: 15))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .foregroundColor(planeColor.opacity(0.6))
                .frame(width: 35, height: 30)
                
                // Airplane
                Image(systemName: "airplane")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(planeColor)
                    .rotationEffect(.degrees(pitchAngle))
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .offset(
                x: 10,
                y: bobOffset
            )
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
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                bobOffset = 6.0
                pitchAngle = 5.0
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
    let onClose: () -> Void
    
    private var timeRangeString: String {
        guard let start = startDate, let end = endDate else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private var platformIcon: String {
        guard let plat = platform?.lowercased() else { return "calendar" }
        if plat.contains("meet") { return "video" }
        if plat.contains("zoom") { return "video.circle" }
        if plat.contains("teams") { return "video" }
        return "mappin.and.ellipse"
    }
    
    // Style Map: Background Color (Solid, no transparency for legibility)
    private var cardBgColor: Color {
        switch cardBgName.lowercased() {
        case "light": return Color(red: 248/255, green: 248/255, blue: 248/255)
        case "blue": return Color(red: 15/255, green: 30/255, blue: 75/255)
        case "black": return Color.black
        default: return Color(red: 32/255, green: 34/255, blue: 44/255) // solid dark gray
        }
    }
    
    // Style Map: Text Color
    private var textColor: Color {
        switch fontColorName.lowercased() {
        case "black": return Color.black
        case "yellow": return Color.yellow
        case "amber": return Color.amber
        default: return Color.white
        }
    }
    
    private var headerColor: Color {
        if cardBgName.lowercased() == "light" && fontColorName.lowercased() == "white" {
            return Color(red: 180/255, green: 100/255, blue: 0/255) // Dark amber for white-light conflict
        }
        return fontColorName.lowercased() == "black" ? Color(red: 180/255, green: 100/255, blue: 0/255) : Color.amber
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
                        .frame(width: width, alignment: .leading)
                    
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
                .padding(.vertical, 12)
                
                // Platform Badge (Right side stub)
                if let plat = platform {
                    TicketDivider()
                        .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3, 4]))
                        .foregroundColor(textColor.opacity(0.2))
                        .frame(width: 1)
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .center, spacing: 5) {
                        if let urlString = meetingUrl, let _ = URL(string: urlString) {
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
                                .foregroundColor(cardBgName.lowercased() == "light" ? .white : .black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(cardBgName.lowercased() == "light" ? Color.blue : Color.amber)
                                .cornerRadius(5)
                                .shadow(color: (cardBgName.lowercased() == "light" ? Color.blue : Color.amber).opacity(0.3), radius: 3)
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
                    .padding(.horizontal, 16)
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
}
