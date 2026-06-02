import SwiftUI
import SpriteKit

enum ActiveScreen {
    case none
    case market
    case hire
    case skills
    case artifacts
    case settings
    
    var title: String {
        switch self {
        case .none: return ""
        case .market: return "РЫНОК"
        case .hire: return "АНАЛИТИКИ"
        case .skills: return "НАВЫКИ"
        case .artifacts: return "ЧЁРНЫЙ РЫНОК"
        case .settings: return "НАСТРОЙКИ"
        }
    }
}

struct GameView: View {
    @Environment(GameEngine.self) var engine
    @State private var scene: GameScene?
    @State private var activeScreen: ActiveScreen = .none
    @State private var hintPulse = false
    @State private var quotaToast: QuotaToast?
    
    var body: some View {
        ZStack {
            // 1. The Game Scene (tappable trading pit)
            if let scene = scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            // 2. Main HUD (status header + tap hint + bottom nav)
            VStack(spacing: 8) {
                StatusHeader()
                    .environment(engine)
                
                QuotaBanner()
                    .environment(engine)
                
                Spacer()
                
                Text("ТАПАЙ ПО ПОЛУ, ЧТОБЫ ТОРГОВАТЬ")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.white.opacity(hintPulse ? 0.65 : 0.25))
                    .padding(.bottom, 14)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: hintPulse)
                
                BottomNavBar(activeScreen: $activeScreen)
            }
            
            // 3. Full-screen overlays (classic screens)
            if activeScreen != .none {
                screenOverlay
            }
            
            // 4. Popups
            if engine.showOfflinePopup {
                OfflineProgressView().environment(engine)
            }
            if engine.showEventPopup {
                EventPopupView().environment(engine)
            }
            
            // 5. Quota result toast
            if let toast = quotaToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: toast.success ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(toast.success ? "КВОТА ВЫПОЛНЕНА" : "КВОТА ПРОВАЛЕНА")
                                .font(.system(.subheadline, design: .monospaced).bold())
                            Text(toast.message)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(toast.success ? .black : .white)
                    .background(toast.success ? Color.brandAccent : Color.lossCoral)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 150)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(200)
            }
        }
        .onAppear {
            hintPulse = true
            guard scene == nil else { return }
            let newScene = GameScene()
            newScene.size = UIScreen.main.bounds.size
            newScene.scaleMode = .resizeFill
            newScene.engine = engine
            
            engine.onPassiveIncome = {
                DispatchQueue.main.async { newScene.spawnPassiveIncomeCoin() }
            }
            engine.onLocationChange = { rank in
                DispatchQueue.main.async {
                    newScene.updateLocation(to: rank)
                    newScene.rankUpEffect()
                }
            }
            engine.onMarketCrash = {
                DispatchQueue.main.async { newScene.crashEffect() }
            }
            engine.onQuotaResult = { success, amount in
                DispatchQueue.main.async {
                    if success {
                        newScene.rankUpEffect()
                        quotaToast = QuotaToast(success: true, message: "Награда: \(formatMoney(amount))")
                    } else {
                        newScene.crashEffect()
                        quotaToast = QuotaToast(success: false, message: "Штраф: −\(formatMoney(amount))")
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {}
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation { quotaToast = nil }
                    }
                }
            }
            self.scene = newScene
        }
    }
    
    private var screenOverlay: some View {
        ZStack {
            Color.black.opacity(0.97).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Text(activeScreen.title)
                        .font(.system(.headline, design: .monospaced).bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        menuAction {
                            withAnimation(.easeInOut(duration: 0.25)) { activeScreen = .none }
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(.body, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(red: 0.06, green: 0.06, blue: 0.08))
                
                Rectangle()
                    .fill(Color.brandAccent.opacity(0.5))
                    .frame(height: 1)
                
                // Screen content (each screen owns its own scrolling)
                Group {
                    switch activeScreen {
                    case .market: TradingFloorView()
                    case .hire: AnalystGuildView()
                    case .skills: SkillTreeView()
                    case .artifacts: ArtifactsView()
                    case .settings: SettingsView()
                    case .none: EmptyView()
                    }
                }
                .environment(engine)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Status Header

struct StatusHeader: View {
    @Environment(GameEngine.self) var engine
    
    private func rankInfo(_ state: GameState) -> (next: Rank?, progress: Double) {
        let ranks = Rank.allCases
        guard let idx = ranks.firstIndex(of: state.currentRank), idx + 1 < ranks.count else {
            return (nil, 1.0)
        }
        let next = ranks[idx + 1]
        let lower = state.currentRank.requiredNetWorth
        let upper = next.requiredNetWorth
        let frac = (state.netWorth - lower) / max(1, upper - lower)
        return (next, min(max(frac, 0), 1))
    }
    
    var body: some View {
        if let state = engine.state {
            let info = rankInfo(state)
            
            VStack(spacing: 12) {
                // Top line: app tag, day, tokens
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.brandAccent)
                            .frame(width: 7, height: 7)
                        Text("БРОКЕР КЛИКЕР")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandAccent)
                    }
                    Spacer()
                    if state.darkTokens > 0 {
                        HStack(spacing: 4) {
                            Image("dark-token")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                            Text("\(state.darkTokens)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(Color(hex: "FF3366"))
                    }
                    Text("ДЕНЬ \(state.currentDay)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                // Money line
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image("default-coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                            Text("НАЛИЧНЫЕ")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Text(formatMoney(state.cash))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.brandAccent)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("КАПИТАЛ")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(formatMoney(state.netWorth))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
                
                // Rank progress
                VStack(spacing: 5) {
                    HStack {
                        Text(state.currentRank.displayName.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        if let next = info.next {
                            Text("ДАЛЕЕ: \(next.displayName.uppercased())")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        } else {
                            Text("МАКС. РАНГ")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.brandAccent)
                        }
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.brandAccent, Color(hex: "FF8A00")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, geo.size.width * info.progress))
                        }
                    }
                    .frame(height: 6)
                    
                    // Market trend pill
                    HStack {
                        Spacer()
                        Text("РЫНОК: \(state.marketTrend.displayName.uppercased())")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(trendColor(state.marketTrend))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(trendColor(state.marketTrend).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brandAccent.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 10)
            .padding(.top, 8)
        }
    }
    
    private func trendColor(_ trend: MarketTrend) -> Color {
        switch trend {
        case .bull: return .gainGreen
        case .bear: return .lossCoral
        case .neutral: return .gray
        }
    }
}

// MARK: - Investor Quota Banner

struct QuotaToast: Identifiable {
    let id = UUID()
    let success: Bool
    let message: String
}

struct QuotaBanner: View {
    @Environment(GameEngine.self) var engine
    
    var body: some View {
        if let state = engine.state, state.quotaTarget > 0 {
            let daysLeft = max(0, state.quotaDeadlineDay - state.currentDay)
            let progress = min(1.0, max(0, state.netWorth / state.quotaTarget))
            let urgent = daysLeft <= 12 && progress < 1.0
            let metColor: Color = progress >= 1.0 ? .gainGreen : (urgent ? .lossCoral : .brandAccent)
            
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Image("investor-boss")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text("КВОТА ИНВЕСТОРА #\(state.quotaLevel)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(metColor)
                    Spacer()
                    Text("ОСТАЛОСЬ \(daysLeft) ДН.")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(urgent ? .lossCoral : .gray)
                }
                
                HStack {
                    Text("ЦЕЛЬ \(formatMoney(state.quotaTarget))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(progress >= 1.0 ? "ГОТОВО ✓" : "\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(metColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(metColor)
                            .frame(width: max(4, geo.size.width * progress))
                    }
                }
                .frame(height: 5)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(metColor.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 10)
        }
    }
}

// MARK: - Bottom Navigation

struct BottomNavBar: View {
    @Binding var activeScreen: ActiveScreen
    
    private let items: [(screen: ActiveScreen, icon: String, label: String)] = [
        (.market, "chart.line.uptrend.xyaxis", "Рынок"),
        (.hire, "person.3.fill", "Найм"),
        (.skills, "bolt.fill", "Навыки"),
        (.artifacts, "crown.fill", "Престиж"),
        (.settings, "gearshape.fill", "Ещё")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.screen) { item in
                Button(action: {
                    menuAction {
                        withAnimation(.easeInOut(duration: 0.25)) { activeScreen = item.screen }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18))
                        Text(item.label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.brandAccent)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.brandAccent.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }
}
