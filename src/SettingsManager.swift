import Foundation
import SwiftUI

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let enabledThresholdsKey = "enabled_thresholds"
    private let calendarThresholdsKey = "calendar_thresholds"
    private let todoistThresholdsKey = "todoist_thresholds"
    private let bannerSizeKey = "banner_size"
    private let flightSpeedKey = "flight_speed"
    private let cardBackgroundKey = "card_background"
    private let textColorKey = "text_color"
    private let animationThemeKey = "animation_theme"
    private let bannerPositionKey = "banner_position"
    private let bannerWidthKey = "banner_width"
    private let bannerHeightKey = "banner_height"
    private let isCalendarEnabledKey = "is_calendar_enabled"
    private let isTodoistEnabledKey = "is_todoist_enabled"
    private let todoistTokenKey = "todoist_token"

    init() {
        if defaults.object(forKey: enabledThresholdsKey) == nil {
            defaults.set([10, 5], forKey: enabledThresholdsKey)
        }
        // Migrate legacy shared thresholds into per-source keys on first run
        let legacy = defaults.array(forKey: enabledThresholdsKey) as? [Int] ?? [10, 5]
        if defaults.object(forKey: calendarThresholdsKey) == nil {
            defaults.set(legacy, forKey: calendarThresholdsKey)
        }
        if defaults.object(forKey: todoistThresholdsKey) == nil {
            defaults.set(legacy, forKey: todoistThresholdsKey)
        }
        if defaults.object(forKey: bannerSizeKey) == nil {
            defaults.set("medium", forKey: bannerSizeKey)
        }
        if defaults.object(forKey: flightSpeedKey) == nil {
            defaults.set("medium", forKey: flightSpeedKey)
        }
        if defaults.object(forKey: cardBackgroundKey) == nil {
            defaults.set("#20222C", forKey: cardBackgroundKey)
        } else {
            // Migrate legacy non-hex values if any
            let oldVal = defaults.string(forKey: cardBackgroundKey) ?? ""
            if !oldVal.hasPrefix("#") {
                switch oldVal.lowercased() {
                case "light": defaults.set("#F8F8F8", forKey: cardBackgroundKey)
                case "blue": defaults.set("#0F1E4B", forKey: cardBackgroundKey)
                case "black": defaults.set("#000000", forKey: cardBackgroundKey)
                default: defaults.set("#20222C", forKey: cardBackgroundKey)
                }
            }
        }
        if defaults.object(forKey: textColorKey) == nil {
            defaults.set("#FFFFFF", forKey: textColorKey)
        } else {
            // Migrate legacy non-hex values if any
            let oldVal = defaults.string(forKey: textColorKey) ?? ""
            if !oldVal.hasPrefix("#") {
                switch oldVal.lowercased() {
                case "black": defaults.set("#000000", forKey: textColorKey)
                case "yellow": defaults.set("#FFEB3B", forKey: textColorKey)
                case "amber": defaults.set("#FFB300", forKey: textColorKey)
                default: defaults.set("#FFFFFF", forKey: textColorKey)
                }
            }
        }
        if defaults.object(forKey: animationThemeKey) == nil {
            defaults.set("airplane", forKey: animationThemeKey)
        }
        if defaults.object(forKey: bannerPositionKey) == nil {
            defaults.set("top", forKey: bannerPositionKey)
        }
        if defaults.object(forKey: bannerWidthKey) == nil {
            defaults.set(230.0, forKey: bannerWidthKey)
        }
        if defaults.object(forKey: bannerHeightKey) == nil {
            defaults.set(76.0, forKey: bannerHeightKey)
        }
        if defaults.object(forKey: isCalendarEnabledKey) == nil {
            defaults.set(false, forKey: isCalendarEnabledKey)
        }
        if defaults.object(forKey: isTodoistEnabledKey) == nil {
            defaults.set(false, forKey: isTodoistEnabledKey)
        }
        if defaults.object(forKey: todoistTokenKey) == nil {
            defaults.set("", forKey: todoistTokenKey)
        }
    }
    
    func enabledThresholds() -> [Int] {
        return defaults.array(forKey: enabledThresholdsKey) as? [Int] ?? [10, 5]
    }

    func calendarThresholds() -> [Int] {
        return defaults.array(forKey: calendarThresholdsKey) as? [Int] ?? [10, 5]
    }

    func setCalendarThresholds(_ thresholds: [Int]) {
        defaults.set(thresholds, forKey: calendarThresholdsKey)
    }

    func todoistThresholds() -> [Int] {
        return defaults.array(forKey: todoistThresholdsKey) as? [Int] ?? [10, 5]
    }

    func setTodoistThresholds(_ thresholds: [Int]) {
        defaults.set(thresholds, forKey: todoistThresholdsKey)
    }

    // Legacy — used by menu bar; reads calendar thresholds
    func isThresholdEnabled(_ threshold: Int) -> Bool {
        return calendarThresholds().contains(threshold)
    }

    func setThreshold(_ threshold: Int, enabled: Bool) {
        var thresholds = calendarThresholds()
        if enabled {
            if !thresholds.contains(threshold) { thresholds.append(threshold) }
        } else {
            thresholds.removeAll { $0 == threshold }
        }
        setCalendarThresholds(thresholds)
    }
    
    func bannerSize() -> String {
        return defaults.string(forKey: bannerSizeKey) ?? "medium"
    }
    
    func setBannerSize(_ size: String) {
        defaults.set(size, forKey: bannerSizeKey)
    }
    
    func flightSpeed() -> String {
        return defaults.string(forKey: flightSpeedKey) ?? "medium"
    }
    
    func setFlightSpeed(_ speed: String) {
        defaults.set(speed, forKey: flightSpeedKey)
    }
    
    func cardBackground() -> String {
        return defaults.string(forKey: cardBackgroundKey) ?? "#20222C"
    }
    
    func setCardBackground(_ bg: String) {
        defaults.set(bg, forKey: cardBackgroundKey)
    }
    
    func textColor() -> String {
        return defaults.string(forKey: textColorKey) ?? "#FFFFFF"
    }
    
    func setTextColor(_ color: String) {
        defaults.set(color, forKey: textColorKey)
    }

    func animationTheme() -> String {
        return defaults.string(forKey: animationThemeKey) ?? "airplane"
    }

    func setAnimationTheme(_ theme: String) {
        defaults.set(theme, forKey: animationThemeKey)
    }

    func bannerPosition() -> String {
        return defaults.string(forKey: bannerPositionKey) ?? "top"
    }

    func setBannerPosition(_ position: String) {
        defaults.set(position, forKey: bannerPositionKey)
    }

    func bannerWidth() -> Double {
        let w = defaults.double(forKey: bannerWidthKey)
        return w > 0 ? w : 230.0
    }

    func setBannerWidth(_ w: Double) {
        defaults.set(w, forKey: bannerWidthKey)
    }

    func bannerHeight() -> Double {
        let h = defaults.double(forKey: bannerHeightKey)
        return h > 0 ? h : 76.0
    }

    func setBannerHeight(_ h: Double) {
        defaults.set(h, forKey: bannerHeightKey)
    }

    func isCalendarEnabled() -> Bool {
        return defaults.bool(forKey: isCalendarEnabledKey)
    }
    
    func setCalendarEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: isCalendarEnabledKey)
    }
    
    func isTodoistEnabled() -> Bool {
        return defaults.bool(forKey: isTodoistEnabledKey)
    }
    
    func setTodoistEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: isTodoistEnabledKey)
    }
    
    func todoistToken() -> String {
        return defaults.string(forKey: todoistTokenKey) ?? ""
    }
    
    func setTodoistToken(_ token: String) {
        defaults.set(token, forKey: todoistTokenKey)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(round(rgbColor.redComponent * 255))
        let g = Int(round(rgbColor.greenComponent * 255))
        let b = Int(round(rgbColor.blueComponent * 255))
        let a = Int(round(rgbColor.alphaComponent * 255))
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
    }
}
