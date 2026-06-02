import SwiftUI
import SwiftData

@main
struct BrokerClickerApp: App {
    @State private var engine = GameEngine()

    init() {
        FirebaseService.shared.configureIfNeeded()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameState.self,
            Asset.self,
            Analyst.self,
            NewsEvent.self,
            Artifact.self,
            Skill.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(engine)
        }
        .modelContainer(sharedModelContainer)
    }
}
