import SwiftData
import SwiftUI

enum LaunchPhase: Equatable {
    case splash
    case privacy(URL)
    case main
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(GameEngine.self) private var engine

    @State private var phase: LaunchPhase = .splash
    @State private var didBootstrap = false

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashScreenView()
                    .transition(.opacity)

            case .privacy(let url):
                PrivacyWebView(url: url) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        enterMainGame()
                    }
                }
                .transition(.opacity)
                .zIndex(1)

            case .main:
                GameView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            await runLaunchFlow()
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func runLaunchFlow() async {
        FirebaseService.shared.configureIfNeeded()

        async let privacyURLTask = FirebaseService.shared.fetchPrivacyURL()
        async let splashDelay: Void = {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
        }()

        let privacyURL = await privacyURLTask
        _ = await splashDelay

        #if DEBUG
        print("[Launch] privacyURL = \(privacyURL?.absoluteString ?? "nil")")
        #endif

        if let privacyURL {
            #if DEBUG
            print("[Launch] Showing privacy WebView")
            #endif
            withAnimation {
                phase = .privacy(privacyURL)
            }
            return
        }

        #if DEBUG
        print("[Launch] No privacy URL — opening game directly")
        #endif
        enterMainGame()
    }

    @MainActor
    private func enterMainGame() {
        guard phase != .main else { return }
        engine.setup(context: modelContext)
        FirebaseService.shared.logGameEntered()
        phase = .main
    }
}
