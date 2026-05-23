import Foundation

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let enabledThresholdsKey = "enabled_thresholds"
    private let airplaneColorKey = "airplane_color"
    private let bannerSizeKey = "banner_size"
    private let flightSpeedKey = "flight_speed"
    private let cardBackgroundKey = "card_background"
    private let textColorKey = "text_color"
    
    init() {
        if defaults.object(forKey: enabledThresholdsKey) == nil {
            defaults.set([10, 5], forKey: enabledThresholdsKey)
        }
        if defaults.object(forKey: airplaneColorKey) == nil {
            defaults.set("white", forKey: airplaneColorKey)
        }
        if defaults.object(forKey: bannerSizeKey) == nil {
            defaults.set("medium", forKey: bannerSizeKey)
        }
        if defaults.object(forKey: flightSpeedKey) == nil {
            defaults.set("medium", forKey: flightSpeedKey)
        }
        if defaults.object(forKey: cardBackgroundKey) == nil {
            defaults.set("dark", forKey: cardBackgroundKey)
        }
        if defaults.object(forKey: textColorKey) == nil {
            defaults.set("white", forKey: textColorKey)
        }
    }
    
    func enabledThresholds() -> [Int] {
        return defaults.array(forKey: enabledThresholdsKey) as? [Int] ?? [10, 5]
    }
    
    func isThresholdEnabled(_ threshold: Int) -> Bool {
        return enabledThresholds().contains(threshold)
    }
    
    func setThreshold(_ threshold: Int, enabled: Bool) {
        var thresholds = enabledThresholds()
        if enabled {
            if !thresholds.contains(threshold) {
                thresholds.append(threshold)
            }
        } else {
            thresholds.removeAll { $0 == threshold }
        }
        defaults.set(thresholds, forKey: enabledThresholdsKey)
    }
    
    func airplaneColor() -> String {
        return defaults.string(forKey: airplaneColorKey) ?? "white"
    }
    
    func setAirplaneColor(_ color: String) {
        defaults.set(color, forKey: airplaneColorKey)
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
        return defaults.string(forKey: cardBackgroundKey) ?? "dark"
    }
    
    func setCardBackground(_ bg: String) {
        defaults.set(bg, forKey: cardBackgroundKey)
    }
    
    func textColor() -> String {
        return defaults.string(forKey: textColorKey) ?? "white"
    }
    
    func setTextColor(_ color: String) {
        defaults.set(color, forKey: textColorKey)
    }
}
