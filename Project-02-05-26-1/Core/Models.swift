import Foundation
import SwiftData

struct ChartDataPoint: Codable, Equatable {
    var value: Double
}

enum MarketTrend: String, Codable {
    case bull = "Bull"
    case bear = "Bear"
    case neutral = "Neutral"
    
    var displayName: String {
        switch self {
        case .bull: return "Бычий"
        case .bear: return "Медвежий"
        case .neutral: return "Нейтральный"
        }
    }
}

enum Rank: String, Codable, CaseIterable {
    case streetHustler = "Street Hustler"
    case officeRookie = "Office Rookie"
    case floorTrader = "Floor Trader"
    case whale = "Whale"
    case wallStreetLegend = "Wall St. Legend"
    case orbitalCEO = "Orbital CEO"
    
    var displayName: String {
        switch self {
        case .streetHustler: return "Уличный торгаш"
        case .officeRookie: return "Офисный новичок"
        case .floorTrader: return "Трейдер с пола"
        case .whale: return "Кит"
        case .wallStreetLegend: return "Легенда Уолл-стрит"
        case .orbitalCEO: return "Орбитальный CEO"
        }
    }
    
    var requiredNetWorth: Double {
        switch self {
        case .streetHustler: return 0
        case .officeRookie: return 10_000
        case .floorTrader: return 500_000
        case .whale: return 10_000_000
        case .wallStreetLegend: return 1_000_000_000
        case .orbitalCEO: return 100_000_000_000
        }
    }
    
    var locationName: String {
        switch self {
        case .streetHustler: return "Грязный переулок"
        case .officeRookie: return "Дешёвый гараж"
        case .floorTrader: return "Коворкинг"
        case .whale: return "Офис на Уолл-стрит"
        case .wallStreetLegend: return "Пентхаус Манхэттена"
        case .orbitalCEO: return "Орбитальная станция"
        }
    }
}

@Model
final class GameState {
    var id: UUID = UUID()
    var cash: Double
    var netWorth: Double
    var currentDay: Int
    var marketTrend: MarketTrend
    var currentRank: Rank
    var netWorthHistory: [ChartDataPoint]
    
    // Offline Progress & Prestige
    var lastSavedDate: Date
    var darkTokens: Int
    
    // Investor Quota (timed challenge)
    var quotaTarget: Double
    var quotaDeadlineDay: Int
    var quotaReward: Double
    var quotaLevel: Int
    
    init(cash: Double = 500, netWorth: Double = 500, currentDay: Int = 1, marketTrend: MarketTrend = .neutral, currentRank: Rank = .streetHustler, netWorthHistory: [ChartDataPoint] = [ChartDataPoint(value: 500)], lastSavedDate: Date = Date(), darkTokens: Int = 0, quotaTarget: Double = 0, quotaDeadlineDay: Int = 0, quotaReward: Double = 0, quotaLevel: Int = 1) {
        self.cash = cash
        self.netWorth = netWorth
        self.currentDay = currentDay
        self.marketTrend = marketTrend
        self.currentRank = currentRank
        self.netWorthHistory = netWorthHistory
        self.lastSavedDate = lastSavedDate
        self.darkTokens = darkTokens
        self.quotaTarget = quotaTarget
        self.quotaDeadlineDay = quotaDeadlineDay
        self.quotaReward = quotaReward
        self.quotaLevel = quotaLevel
    }
}

enum AssetCategory: String, Codable, CaseIterable {
    case usedGoods = "Used Goods"
    case stocks = "Stocks"
    case crypto = "Crypto"
    case realEstate = "Real Estate"
    
    var displayName: String {
        switch self {
        case .usedGoods: return "Б/у товары"
        case .stocks: return "Акции"
        case .crypto: return "Крипто"
        case .realEstate: return "Недвижимость"
        }
    }
    
    var baseVolatility: Double {
        switch self {
        case .usedGoods: return 0.05
        case .stocks: return 0.15
        case .crypto: return 0.35
        case .realEstate: return 0.02
        }
    }
}

@Model
final class Asset {
    var id: UUID = UUID()
    var name: String
    var category: AssetCategory
    var purchasePrice: Double
    var currentMarketPrice: Double
    var quantityOwned: Int
    var priceHistory: [ChartDataPoint]
    var tier: Int
    
    init(name: String, category: AssetCategory, initialPrice: Double, tier: Int) {
        self.name = name
        self.category = category
        self.purchasePrice = 0
        self.currentMarketPrice = initialPrice
        self.quantityOwned = 0
        self.priceHistory = [ChartDataPoint(value: initialPrice)]
        self.tier = tier
    }
}

@Model
final class Analyst {
    var id: UUID = UUID()
    var name: String
    var baseHireCost: Double
    var cashPerTick: Double
    var quantityHired: Int
    
    var currentHireCost: Double {
        return baseHireCost * pow(1.15, Double(quantityHired))
    }
    
    init(name: String, hireCost: Double, cashPerTick: Double) {
        self.name = name
        self.baseHireCost = hireCost
        self.cashPerTick = cashPerTick
        self.quantityHired = 0
    }
}

@Model
final class NewsEvent {
    var id: UUID = UUID()
    var text: String
    var day: Int
    var isPositive: Bool
    var dateCreated: Date
    
    init(text: String, day: Int, isPositive: Bool) {
        self.text = text
        self.day = day
        self.isPositive = isPositive
        self.dateCreated = Date()
    }
}

@Model
final class Artifact {
    var id: UUID = UUID()
    var name: String
    var desc: String
    var tokenCost: Int
    var isOwned: Bool
    
    init(name: String, desc: String, tokenCost: Int) {
        self.name = name
        self.desc = desc
        self.tokenCost = tokenCost
        self.isOwned = false
    }
}

@Model
final class Skill {
    var id: UUID = UUID()
    var name: String
    var desc: String
    var cashCost: Double
    var isUnlocked: Bool
    var tier: Int
    
    init(name: String, desc: String, cashCost: Double, tier: Int) {
        self.name = name
        self.desc = desc
        self.cashCost = cashCost
        self.tier = tier
        self.isUnlocked = false
    }
}
