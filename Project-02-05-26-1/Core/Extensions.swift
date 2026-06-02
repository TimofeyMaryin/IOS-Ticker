import SwiftUI

extension Color {
    /// Primary brand accent (gold/yellow). Used for chrome: headers, nav, borders, cash.
    static let brandAccent = Color(hex: "FFC400")
    /// Semantic "gain / price up" color.
    static let gainGreen = Color(hex: "00FF66")
    /// Semantic "loss / price down" color.
    static let lossCoral = Color(hex: "FF3366")
    
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Asset name mapping

enum GameAssets {
    static func artifactImageName(for name: String, tokenCost: Int = 0) -> String? {
        let lower = name.lowercased()
        if lower.contains("терминал") || lower.contains("terminal") || lower.contains("golden") {
            return "golden-terminal"
        }
        if lower.contains("инсайд") || lower.contains("insider") {
            return "insider-info"
        }
        switch tokenCost {
        case 1: return "golden-terminal"
        case 5: return "insider-info"
        default: return nil
        }
    }

    static func skillImageName(for name: String, tier: Int = 0) -> String? {
        let lower = name.lowercased()
        if lower.contains("харизм") || lower.contains("charism") { return "charismatic" }
        if lower.contains("рук") || lower.contains("heavy") || lower.contains("power") || lower.contains("click") {
            return "power-click"
        }
        if lower.contains("налог") || lower.contains("уклон") || lower.contains("tax") || lower.contains("evasion") {
            return "tax-evasion"
        }
        switch tier {
        case 1: return "charismatic"
        case 2: return "power-click"
        case 3: return "tax-evasion"
        default: return nil
        }
    }
}
