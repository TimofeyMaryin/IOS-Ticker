import AVFoundation

/// Centralized SFX playback for Broker Clicker.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String, CaseIterable {
        case buttonClick = "button-click"
        case collectPoints = "collect-points"
        case menuSelection = "menu-selection-click"
        case newsTing = "news-ting"
        case purchaseSuccess = "purchase-success"

        var fileExtension: String {
            switch self {
            case .menuSelection: return "wav"
            default: return "mp3"
            }
        }

        var subdirectory: String { "Song" }
    }

    var isEnabled: Bool = true

    private var players: [Effect: AVAudioPlayer] = [:]

    private init() {
        configureSession()
        preloadAll()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func preloadAll() {
        for effect in Effect.allCases {
            _ = player(for: effect)
        }
    }

    private func player(for effect: Effect) -> AVAudioPlayer? {
        if let existing = players[effect] { return existing }

        let url =
            Bundle.main.url(
                forResource: effect.rawValue,
                withExtension: effect.fileExtension,
                subdirectory: effect.subdirectory
            )
            ?? Bundle.main.url(
                forResource: effect.rawValue,
                withExtension: effect.fileExtension
            )

        guard let url else {
            #if DEBUG
            print("SoundManager: missing \(effect.rawValue).\(effect.fileExtension)")
            #endif
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[effect] = player
            return player
        } catch {
            #if DEBUG
            print("SoundManager: failed to load \(effect.rawValue): \(error)")
            #endif
            return nil
        }
    }

    func play(_ effect: Effect) {
        guard isEnabled else { return }
        guard let player = player(for: effect) else { return }
        if player.isPlaying {
            player.currentTime = 0
        } else {
            player.play()
        }
    }

    // MARK: - Semantic helpers

    func playGameTap() { play(.buttonClick) }
    func playBonusCollect() { play(.collectPoints) }
    func playMenuSelection() { play(.menuSelection) }
    func playNewsEvent() { play(.newsTing) }
    func playPurchaseSuccess() { play(.purchaseSuccess) }
}

/// Wraps UI actions with menu click SFX.
@MainActor
func menuAction(_ action: () -> Void) {
    SoundManager.shared.playMenuSelection()
    action()
}
