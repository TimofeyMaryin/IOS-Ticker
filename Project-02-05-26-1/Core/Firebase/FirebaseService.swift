import FirebaseAnalytics
import FirebaseCore
import FirebaseRemoteConfig

@MainActor
final class FirebaseService {
    static let shared = FirebaseService()

    private let remoteConfig: RemoteConfig
    private var isConfigured = false

    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isConfigured = true

        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.setDefaults(["data": "" as NSObject])

        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isConfigured = true
    }

    /// Fetches Remote Config and returns the privacy/policy URL from key `"data"`.
    func fetchPrivacyURL() async -> URL? {
        configureIfNeeded()

        await withCheckedContinuation { continuation in
            remoteConfig.fetchAndActivate { status, error in
                if let error {
                    #if DEBUG
                    print("[Launch] Remote Config error: \(error.localizedDescription)")
                    #endif
                    Analytics.logEvent("remote_config_error", parameters: [
                        "message": error.localizedDescription
                    ])
                } else {
                    #if DEBUG
                    print("[Launch] Remote Config status: \(status.rawValue)")
                    #endif
                    Analytics.logEvent("remote_config_fetched", parameters: [
                        "status": status.rawValue
                    ])
                }
                continuation.resume()
            }
        }

        let raw = remoteConfig.configValue(forKey: "data").stringValue
        #if DEBUG
        print("[Launch] Remote Config raw \"data\": \"\(raw)\"")
        print("[Launch] Remote Config source: \(remoteConfig.configValue(forKey: "data").source.rawValue)")
        #endif

        guard let url = RemoteConfigURLParser.parse(raw) else {
            #if DEBUG
            print("[Launch] Could not parse privacy URL from Remote Config")
            #endif
            return nil
        }

        #if DEBUG
        print("[Launch] Parsed privacy URL: \(url.absoluteString)")
        #endif
        return url
    }

    func logScreen(_ name: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: name
        ])
    }

    func logPrivacyAccepted(version: String?) {
        Analytics.logEvent("privacy_accepted", parameters: [
            "version": version ?? "unknown"
        ])
    }

    func logGameEntered() {
        Analytics.logEvent("game_entered", parameters: nil)
    }
}
