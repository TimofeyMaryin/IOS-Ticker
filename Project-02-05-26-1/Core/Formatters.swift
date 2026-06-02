import Foundation

func formatMoney(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = "$"
    formatter.maximumFractionDigits = 1
    
    let absValue = abs(value)
    
    if value < 0 {
        return "-" + formatMoney(-value)
    }
    if absValue >= 1_000_000_000 {
        return "$\(String(format: "%.1f", value / 1_000_000_000))B"
    } else if absValue >= 1_000_000 {
        return "$\(String(format: "%.1f", value / 1_000_000))M"
    } else if absValue >= 1_000 {
        return "$\(String(format: "%.1f", value / 1_000))K"
    } else {
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

/// Formats a percentage with an explicit sign, e.g. "+12.4%" / "-3.1%".
func formatSignedPercent(_ value: Double) -> String {
    let prefix = value > 0 ? "+" : ""
    return "\(prefix)\(String(format: "%.2f", value))%"
}
