import Foundation
import SwiftData
import SwiftUI

struct InteractiveEvent {
    let title: String
    let description: String
    let option1: String
    let option2: String
    let action1: () -> Void
    let action2: () -> Void
}

@MainActor
@Observable
final class GameEngine {
    var modelContext: ModelContext?
    
    var state: GameState?
    var assets: [Asset] = []
    var analysts: [Analyst] = []
    var artifacts: [Artifact] = []
    var skills: [Skill] = []
    
    private var timer: Timer?
    private var tickCount = 0
    var prestigeMultiplier: Double = 1.0
    var gameSpeedMultiplier: Double = 1.0
    
    var onPassiveIncome: (() -> Void)?
    var onLocationChange: ((Rank) -> Void)?
    var onMarketCrash: (() -> Void)?
    var onQuotaResult: ((Bool, Double) -> Void)?  // (success, rewardOrPenalty)
    
    // Modals state
    var offlineEarnings: Double = 0
    var showOfflinePopup: Bool = false
    var currentEvent: InteractiveEvent? = nil
    var showEventPopup: Bool = false
    
    func setup(context: ModelContext) {
        self.modelContext = context
        fetchData()
        
        // Calculate Offline Progress
        if let state = state {
            let now = Date()
            let timePassed = now.timeIntervalSince(state.lastSavedDate)
            
            // If more than 60 seconds passed, calculate offline earnings
            if timePassed > 60 {
                let ticksPassed = timePassed / 1.5 // 1 tick = 1.5s real time
                let passiveIncomePerTick = calculatePassiveIncome()
                
                let earnings = passiveIncomePerTick * ticksPassed
                if earnings > 0 {
                    offlineEarnings = earnings
                    state.cash += earnings
                    showOfflinePopup = true
                    SoundManager.shared.playNewsEvent()
                }
            }
            state.lastSavedDate = now
        }
        
        if let state = state, state.quotaDeadlineDay == 0 {
            startNextQuota()
        }
        
        applyArtifactModifiers()
        startTimer()
    }
    
    // MARK: - Investor Quota (timed challenge)
    
    func startNextQuota() {
        guard let state = state else { return }
        // Required growth scales with the quota level, so it gets progressively harder.
        let growth = 0.30 + 0.06 * Double(state.quotaLevel)
        state.quotaTarget = max(state.netWorth * (1 + growth), state.netWorth + 1_000)
        state.quotaDeadlineDay = state.currentDay + 40
        state.quotaReward = state.netWorth * 0.15 + 1_000
    }
    
    private func evaluateQuota() {
        guard let state = state, state.quotaDeadlineDay > 0,
              state.currentDay >= state.quotaDeadlineDay else { return }
        
        if state.netWorth >= state.quotaTarget {
            let reward = state.quotaReward
            state.cash += reward
            state.quotaLevel += 1
            if state.quotaLevel % 3 == 0 { state.darkTokens += 1 }
            onQuotaResult?(true, reward)
            SoundManager.shared.playNewsEvent()
            triggerHaptic(style: .heavy)
        } else {
            let penalty = state.cash * 0.15
            state.cash -= penalty
            state.quotaLevel = max(1, state.quotaLevel - 1)
            onQuotaResult?(false, penalty)
            SoundManager.shared.playNewsEvent()
            triggerHaptic(style: .heavy)
        }
        updateNetWorthAndRank()
        startNextQuota()
    }
    
    private func applyArtifactModifiers() {
        // Example: If user has artifacts, adjust base multiplier
        var multiplier = 1.0
        for artifact in artifacts where artifact.isOwned {
            if artifact.tokenCost == 1 { multiplier += 0.5 }
            if artifact.tokenCost == 3 { multiplier += 1.0 }
        }
        prestigeMultiplier = multiplier
    }
    
    func fetchData() {
        guard let context = modelContext else { return }
        
        let stateDescriptor = FetchDescriptor<GameState>()
        if let existingState = try? context.fetch(stateDescriptor).first {
            self.state = existingState
        } else {
            let newState = GameState()
            context.insert(newState)
            self.state = newState
        }
        
        // Load Assets
        let assetDescriptor = FetchDescriptor<Asset>(sortBy: [SortDescriptor(\.tier)])
        let existingAssets = try? context.fetch(assetDescriptor)
        if existingAssets?.isEmpty == false {
            self.assets = existingAssets!
        } else {
            let initialAssets = [
                Asset(name: "Б/у телефоны", category: .usedGoods, initialPrice: 100, tier: 1),
                Asset(name: "Кроссовки", category: .usedGoods, initialPrice: 250, tier: 1),
                Asset(name: "Тех-акции", category: .stocks, initialPrice: 1500, tier: 2),
                Asset(name: "Клон Doge", category: .crypto, initialPrice: 10, tier: 3),
                Asset(name: "Студия", category: .realEstate, initialPrice: 250_000, tier: 4)
            ]
            for asset in initialAssets { context.insert(asset) }
            self.assets = initialAssets
        }
        
        // Load Analysts
        let analystDescriptor = FetchDescriptor<Analyst>(sortBy: [SortDescriptor(\.baseHireCost)])
        let existingAnalysts = try? context.fetch(analystDescriptor)
        if existingAnalysts?.isEmpty == false {
            self.analysts = existingAnalysts!
            migrateAnalystsToRussian()
        } else {
            let initialAnalysts = [
                Analyst(name: "Парсер новостей", hireCost: 1000, cashPerTick: 10),
                Analyst(name: "Младший аналитик", hireCost: 5000, cashPerTick: 75),
                Analyst(name: "Дневной трейдер", hireCost: 25000, cashPerTick: 400),
                Analyst(name: "ИИ-алгоритм", hireCost: 150_000, cashPerTick: 3000)
            ]
            for analyst in initialAnalysts { context.insert(analyst) }
            self.analysts = initialAnalysts
        }
        
        // Load Artifacts
        let artifactDescriptor = FetchDescriptor<Artifact>()
        let existingArtifacts = try? context.fetch(artifactDescriptor)
        if existingArtifacts?.isEmpty == false {
            self.artifacts = existingArtifacts!
            migrateArtifactsToRussian()
        } else {
            let initialArtifacts = [
                Artifact(name: "Золотой терминал", desc: "+50% к пассивному доходу", tokenCost: 1),
                Artifact(name: "Алмазный кофе", desc: "+100% к пассивному доходу", tokenCost: 3),
                Artifact(name: "Инсайдерская инфо", desc: "Цены падают на 10% реже", tokenCost: 5)
            ]
            for artifact in initialArtifacts { context.insert(artifact) }
            self.artifacts = initialArtifacts
        }
        
        // Load Skills
        let skillDescriptor = FetchDescriptor<Skill>(sortBy: [SortDescriptor(\.tier)])
        let existingSkills = try? context.fetch(skillDescriptor)
        if existingSkills?.isEmpty == false {
            self.skills = existingSkills!
            migrateSkillsToRussian()
        } else {
            let initialSkills = [
                Skill(name: "Харизматик", desc: "Снижает стоимость найма аналитиков на 10%", cashCost: 5000, tier: 1),
                Skill(name: "Тяжёлая рука", desc: "Сила клика удваивается", cashCost: 15000, tier: 2),
                Skill(name: "Уклонение от налогов", desc: "Негативные события стоят на 50% дешевле", cashCost: 100_000, tier: 3)
            ]
            for skill in initialSkills { context.insert(skill) }
            self.skills = initialSkills
        }
    }

    /// Приводит названия/описания навыков к русским (старые сейвы могли быть на EN).
    private func migrateSkillsToRussian() {
        let catalog: [(tier: Int, name: String, desc: String)] = [
            (1, "Харизматик", "Снижает стоимость найма аналитиков на 10%"),
            (2, "Тяжёлая рука", "Сила клика удваивается"),
            (3, "Уклонение от налогов", "Негативные события стоят на 50% дешевле")
        ]
        var changed = false
        for skill in skills {
            guard let entry = catalog.first(where: { $0.tier == skill.tier }) else { continue }
            if skill.name != entry.name || skill.desc != entry.desc {
                skill.name = entry.name
                skill.desc = entry.desc
                changed = true
            }
        }
        if changed { try? modelContext?.save() }
    }

    /// Приводит артефакты к русским названиям (старые сейвы — EN).
    private func migrateArtifactsToRussian() {
        let catalog: [(tokenCost: Int, name: String, desc: String)] = [
            (1, "Золотой терминал", "+50% к пассивному доходу"),
            (3, "Алмазный кофе", "+100% к пассивному доходу"),
            (5, "Инсайдерская инфо", "Цены падают на 10% реже")
        ]
        var changed = false
        for artifact in artifacts {
            guard let entry = catalog.first(where: { $0.tokenCost == artifact.tokenCost }) else { continue }
            if artifact.name != entry.name || artifact.desc != entry.desc {
                artifact.name = entry.name
                artifact.desc = entry.desc
                changed = true
            }
        }
        if changed { try? modelContext?.save() }
    }

    /// Приводит аналитиков к русским именам (старые сейвы — EN).
    private func migrateAnalystsToRussian() {
        let catalog: [(baseHireCost: Double, name: String)] = [
            (1000, "Парсер новостей"),
            (5000, "Младший аналитик"),
            (25000, "Дневной трейдер"),
            (150_000, "ИИ-алгоритм")
        ]
        var changed = false
        for analyst in analysts {
            guard let entry = catalog.first(where: { $0.baseHireCost == analyst.baseHireCost }) else { continue }
            if analyst.name != entry.name {
                analyst.name = entry.name
                changed = true
            }
        }
        if changed { try? modelContext?.save() }
    }

    func hasUnlockedSkill(tier: Int) -> Bool {
        skills.contains { $0.tier == tier && $0.isUnlocked }
    }
    
    func startTimer() {
        timer?.invalidate()
        let interval = max(0.1, 1.5 / gameSpeedMultiplier)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func calculatePassiveIncome() -> Double {
        return analysts.reduce(0) { $0 + (Double($1.quantityHired) * $1.cashPerTick) } * prestigeMultiplier
    }
    
    func tick() {
        guard let state = state else { return }
        tickCount += 1
        state.currentDay += 1
        state.lastSavedDate = Date()
        
        let passiveIncome = calculatePassiveIncome()
        if passiveIncome > 0 {
            state.cash += passiveIncome
            onPassiveIncome?()
        }
        
        if tickCount % 5 == 0 {
            updateMarket()
            
            // Random Interactive Event check
            if !showEventPopup && Double.random(in: 0...1) < 0.05 {
                triggerRandomEvent()
            }
        }
        
        updateNetWorthAndRank()
        evaluateQuota()
        try? modelContext?.save()
    }
    
    private func triggerRandomEvent() {
        guard let state = state else { return }
        let events = [
            InteractiveEvent(
                title: "Налоговая проверка",
                description: "Налоговая изучает ваши счета.",
                option1: "Дать взятку ($10 000)",
                option2: "Спрятать средства (50% риск потерять $50K)",
                action1: {
                    if state.cash >= 10_000 { state.cash -= 10_000 }
                    self.showEventPopup = false
                },
                action2: {
                    if Bool.random() {
                        state.cash = max(0, state.cash - 50_000)
                    }
                    self.showEventPopup = false
                }
            ),
            InteractiveEvent(
                title: "Вирусный твит",
                description: "Известный CEO написал о новой криптовалюте.",
                option1: "Игнорировать",
                option2: "Вложиться вслепую ($5 000)",
                action1: { self.showEventPopup = false },
                action2: {
                    if state.cash >= 5000 {
                        state.cash -= 5000
                        if Bool.random() { state.cash += 20_000 } // Win big
                    }
                    self.showEventPopup = false
                }
            )
        ]
        
        currentEvent = events.randomElement()
        showEventPopup = true
        SoundManager.shared.playNewsEvent()
        triggerHaptic(style: .heavy)
    }
    
    private func updateMarket() {
        guard let state = state else { return }
        
        if Double.random(in: 0...1) < 0.15 {
            let trends: [MarketTrend] = [.bull, .bear, .neutral]
            let newTrend = trends.randomElement()!
            if newTrend == .bear && state.marketTrend != .bear {
                onMarketCrash?()
                SoundManager.shared.playNewsEvent()
                triggerHaptic(style: .heavy)
            } else {
                triggerHaptic(style: .medium)
            }
            state.marketTrend = newTrend
        }
        
        var trendModifier: Double
        switch state.marketTrend {
        case .bull: trendModifier = 0.05
        case .bear: trendModifier = -0.05
        case .neutral: trendModifier = 0.0
        }
        
        let hasInsiderArtifact = artifacts.contains(where: { $0.tokenCost == 5 && $0.isOwned })
        if hasInsiderArtifact && trendModifier < 0 {
            trendModifier = -0.02 // Less negative impact
        }
        
        // Black Swan: rare catastrophic crash of an entire asset category.
        // Makes passively holding everything risky and rewards active timing.
        var blackSwanCategory: AssetCategory?
        if Double.random(in: 0...1) < 0.04 {
            blackSwanCategory = AssetCategory.allCases.randomElement()
            onMarketCrash?()
            SoundManager.shared.playNewsEvent()
        }
        
        for asset in assets {
            let vol = asset.category.baseVolatility
            let randomChange = Double.random(in: -vol...vol)
            var delta = randomChange + trendModifier
            
            if asset.category == blackSwanCategory {
                delta = -Double.random(in: 0.35...0.55)
            }
            
            asset.currentMarketPrice = max(1.0, asset.currentMarketPrice * (1 + delta))
            
            var history = asset.priceHistory
            history.append(ChartDataPoint(value: asset.currentMarketPrice))
            if history.count > 10 {
                history.removeFirst()
            }
            asset.priceHistory = history
        }
    }
    
    private func updateNetWorthAndRank() {
        guard let state = state else { return }
        
        let assetsValue = assets.reduce(0) { $0 + ($1.currentMarketPrice * Double($1.quantityOwned)) }
        state.netWorth = state.cash + assetsValue
        
        var history = state.netWorthHistory
        history.append(ChartDataPoint(value: state.netWorth))
        if history.count > 30 {
            history.removeFirst()
        }
        state.netWorthHistory = history
        
        let oldRank = state.currentRank
        for rank in Rank.allCases.reversed() {
            if state.netWorth >= rank.requiredNetWorth {
                state.currentRank = rank
                break
            }
        }
        
        if oldRank != state.currentRank {
            onLocationChange?(state.currentRank)
            SoundManager.shared.playNewsEvent()
            triggerHaptic(style: .heavy)
        }
    }
    
    func buyAsset(_ asset: Asset, quantity: Int) {
        guard let state = state, quantity > 0 else { return }
        let cost = asset.currentMarketPrice * Double(quantity)
        if state.cash >= cost {
            state.cash -= cost
            // Maintain weighted average cost basis (purchasePrice = avg cost / share).
            let newQty = asset.quantityOwned + quantity
            asset.purchasePrice = (asset.purchasePrice * Double(asset.quantityOwned) + cost) / Double(newQty)
            asset.quantityOwned = newQty
            updateNetWorthAndRank()
            try? modelContext?.save()
            SoundManager.shared.playPurchaseSuccess()
            triggerHaptic(style: .light)
        }
    }
    
    func sellAsset(_ asset: Asset, quantity: Int) {
        guard let state = state, quantity > 0 else { return }
        let amountToSell = min(quantity, asset.quantityOwned)
        if amountToSell > 0 {
            let revenue = asset.currentMarketPrice * Double(amountToSell)
            state.cash += revenue
            asset.quantityOwned -= amountToSell
            // Average cost per share is unchanged when selling; reset once flat.
            if asset.quantityOwned == 0 {
                asset.purchasePrice = 0
            }
            updateNetWorthAndRank()
            try? modelContext?.save()
            triggerHaptic(style: .light)
        }
    }
    
    func buyMax(_ asset: Asset) {
        guard let state = state else { return }
        let quantity = Int(state.cash / asset.currentMarketPrice)
        buyAsset(asset, quantity: quantity)
    }
    
    func sellMax(_ asset: Asset) {
        sellAsset(asset, quantity: asset.quantityOwned)
    }
    
    func hireAnalyst(_ analyst: Analyst) {
        guard let state = state else { return }
        
        var cost = analyst.currentHireCost
        if hasUnlockedSkill(tier: 1) {
            cost *= 0.9
        }
        
        if state.cash >= cost {
            state.cash -= cost
            analyst.quantityHired += 1
            try? modelContext?.save()
            SoundManager.shared.playPurchaseSuccess()
            triggerHaptic(style: .medium)
        }
    }
    
    func unlockSkill(_ skill: Skill) {
        guard let state = state, !skill.isUnlocked else { return }
        if state.cash >= skill.cashCost {
            state.cash -= skill.cashCost
            skill.isUnlocked = true
            try? modelContext?.save()
            SoundManager.shared.playPurchaseSuccess()
            triggerHaptic(style: .medium)
        }
    }
    
    func buyArtifact(_ artifact: Artifact) {
        guard let state = state, !artifact.isOwned else { return }
        if state.darkTokens >= artifact.tokenCost {
            state.darkTokens -= artifact.tokenCost
            artifact.isOwned = true
            applyArtifactModifiers()
            try? modelContext?.save()
            SoundManager.shared.playPurchaseSuccess()
            triggerHaptic(style: .heavy)
        }
    }
    
    /// Value earned by a single base tap (before combo / critical multipliers).
    var tapBaseValue: Double {
        var baseClick: Double = 1.0
        let analystBonus = analysts.reduce(0) { $0 + Double($1.quantityHired) * 0.1 }
        if hasUnlockedSkill(tier: 2) {
            baseClick *= 2
        }
        return (baseClick + analystBonus) * prestigeMultiplier
    }
    
    /// Apply tap earnings. Intentionally does NOT hit disk on every tap (the periodic
    /// tick persists state) so rapid tapping stays buttery smooth.
    func applyTapEarnings(_ amount: Double) {
        guard let state = state else { return }
        state.cash += amount
        updateNetWorthAndRank()
    }
    
    func resetPrestige() {
        guard let state = state, let context = modelContext else { return }
        if state.netWorth >= 1_000_000 {
            // Give 1 Dark Token per $1,000,000 net worth
            let earnedTokens = Int(state.netWorth / 1_000_000)
            state.darkTokens += earnedTokens
            
            // Reset Progress
            state.cash = 500
            state.netWorth = 500
            state.currentDay = 1
            state.currentRank = .streetHustler
            state.netWorthHistory = [ChartDataPoint(value: 500)]
            
            for asset in assets { asset.quantityOwned = 0; asset.purchasePrice = 0 }
            for analyst in analysts { analyst.quantityHired = 0 }
            for skill in skills { skill.isUnlocked = false }
            
            state.quotaLevel = 1
            startNextQuota()
            onLocationChange?(state.currentRank)
            try? context.save()
            triggerHaptic(style: .heavy)
        }
    }
    
    private func triggerHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
