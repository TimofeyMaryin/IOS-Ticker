import Foundation

enum RemoteConfigURLParser {
    /// Normalizes Remote Config `"data"` into a loadable https URL string.
    static func parse(_ raw: String) -> URL? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        // Strip wrapping quotes from console copy-paste mistakes.
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
            (value.hasPrefix("'") && value.hasSuffix("'")) {
            value = String(value.dropFirst().dropLast())
        }

        if let url = URL(string: value), url.scheme?.hasPrefix("http") == true {
            return url
        }

        // Some teams store JSON in the parameter value.
        if let data = value.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["url", "link", "data", "privacy", "value"] {
                if let nested = object[key] as? String, let url = parse(nested) {
                    return url
                }
            }
        }

        return nil
    }
}
