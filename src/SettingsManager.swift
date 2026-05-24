import Foundation
import SwiftUI
import AppKit
import Security

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
    private let customImagePathKey = "custom_image_path"
    private let lastTodoistSyncKey = "last_todoist_sync"
    private let todoistSyncIntervalKey = "todoist_sync_interval"
    private let soundEnabledKey = "sound_enabled"
    private let soundTypeKey = "sound_type"
    private let notificationHistoryKey = "notification_history"
    private let ignoredKeywordsKey = "ignored_keywords"
    private let historyCapacity = 50

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
        if defaults.object(forKey: soundEnabledKey) == nil {
            defaults.set(true, forKey: soundEnabledKey)
        }
        if defaults.object(forKey: soundTypeKey) == nil {
            defaults.set("Glass", forKey: soundTypeKey)
        }
        if defaults.object(forKey: ignoredKeywordsKey) == nil {
            defaults.set("", forKey: ignoredKeywordsKey)
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
        // 1. Try to read from Keychain
        if let token = KeychainHelper.get() {
            return token
        }
        
        // 2. Check if we have a legacy token in UserDefaults to migrate
        if let legacyToken = defaults.string(forKey: todoistTokenKey), !legacyToken.isEmpty {
            let success = KeychainHelper.set(legacyToken)
            if success {
                defaults.removeObject(forKey: todoistTokenKey)
            }
            return legacyToken
        }
        
        return ""
    }
    
    func setTodoistToken(_ token: String) {
        if token.isEmpty {
            _ = KeychainHelper.delete()
        } else {
            _ = KeychainHelper.set(token)
        }
        defaults.removeObject(forKey: todoistTokenKey)
    }

    func isSoundEnabled() -> Bool {
        return defaults.bool(forKey: soundEnabledKey)
    }

    func setSoundEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: soundEnabledKey)
    }

    func soundType() -> String {
        return defaults.string(forKey: soundTypeKey) ?? "Glass"
    }

    func setSoundType(_ type: String) {
        defaults.set(type, forKey: soundTypeKey)
    }

    func ignoredKeywords() -> String {
        return defaults.string(forKey: ignoredKeywordsKey) ?? ""
    }
    
    func setIgnoredKeywords(_ keywords: String) {
        defaults.set(keywords, forKey: ignoredKeywordsKey)
    }
    
    func shouldIgnoreEvent(title: String) -> Bool {
        let keywordsStr = ignoredKeywords()
        guard !keywordsStr.isEmpty else { return false }
        
        let keywords = keywordsStr
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            
        guard !keywords.isEmpty else { return false }
        
        let lowerTitle = title.lowercased()
        return keywords.contains { lowerTitle.contains($0) }
    }

    func customImagePath() -> String? {
        return defaults.string(forKey: customImagePathKey)
    }

    func todoistSyncInterval() -> Int {
        let v = defaults.integer(forKey: todoistSyncIntervalKey)
        return v > 0 ? v : 300
    }

    func setTodoistSyncInterval(_ seconds: Int) {
        defaults.set(seconds, forKey: todoistSyncIntervalKey)
    }

    func lastTodoistSync() -> Date? {
        return defaults.object(forKey: lastTodoistSyncKey) as? Date
    }

    func setLastTodoistSync(_ date: Date) {
        defaults.set(date, forKey: lastTodoistSyncKey)
    }

    // MARK: - Notification History

    func notificationHistory() -> [NotificationEntry] {
        guard let data = defaults.data(forKey: notificationHistoryKey) else { return [] }
        return (try? JSONDecoder().decode([NotificationEntry].self, from: data)) ?? []
    }

    func addNotificationEntry(title: String, source: String, threshold: Int) {
        var history = notificationHistory()
        let entry = NotificationEntry(title: title, source: source, threshold: threshold, date: Date())
        history.insert(entry, at: 0)
        if history.count > historyCapacity {
            history = Array(history.prefix(historyCapacity))
        }
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: notificationHistoryKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("NotificationHistoryUpdated"), object: nil)
        }
    }

    func clearNotificationHistory() {
        defaults.removeObject(forKey: notificationHistoryKey)
    }

    func setCustomImagePath(_ path: String?) {
        if let path = path {
            defaults.set(path, forKey: customImagePathKey)
        } else {
            defaults.removeObject(forKey: customImagePathKey)
        }
    }

    // Accepts any NSImage-readable format, resizes to ≤256px (retina-safe), saves as PNG.
    // Returns the destination URL on success.
    static func processAndSaveCustomImage(from sourceURL: URL) -> URL? {
        guard let source = NSImage(contentsOf: sourceURL) else { return nil }

        // Work in pixels: prefer the highest-res representation
        var pixelSize = CGSize.zero
        for rep in source.representations {
            let s = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            if s.width * s.height > pixelSize.width * pixelSize.height { pixelSize = s }
        }
        if pixelSize == .zero { pixelSize = source.size }

        let maxPx: CGFloat = 256
        let scale = min(maxPx / pixelSize.width, maxPx / pixelSize.height, 1.0)
        let targetSize = CGSize(width: max(1, pixelSize.width * scale),
                                height: max(1, pixelSize.height * scale))

        guard let offscreen = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: offscreen)
        NSGraphicsContext.current?.imageInterpolation = .high
        source.draw(in: CGRect(origin: .zero, size: targetSize),
                    from: CGRect(origin: .zero, size: pixelSize),
                    operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        guard let pngData = offscreen.representation(using: .png, properties: [:]) else { return nil }

        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = appSupport.appendingPathComponent("com.anand.FlightNotifier", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        let dest = dir.appendingPathComponent("custom_theme.png")
        try? pngData.write(to: dest)
        return dest
    }
}

struct NotificationEntry: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let source: String   // "Calendar" or "Todoist"
    let threshold: Int   // minutes before (0 = late)
    let date: Date
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

// MARK: - Keychain Security Helper
struct KeychainHelper {
    static let service = "com.anand.FlightNotifier"
    static let account = "todoist_token"
    
    static func set(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        _ = delete()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func get() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    static func delete() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
