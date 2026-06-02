import SwiftUI
import Charts

struct TradingFloorView: View {
    @Environment(GameEngine.self) var engine
    
    // Portfolio aggregates across all owned holdings.
    private var totalInvested: Double {
        engine.assets.reduce(0) { $0 + $1.purchasePrice * Double($1.quantityOwned) }
    }
    private var totalValue: Double {
        engine.assets.reduce(0) { $0 + $1.currentMarketPrice * Double($1.quantityOwned) }
    }
    private var totalPnL: Double { totalValue - totalInvested }
    private var totalPnLPct: Double { totalInvested > 0 ? (totalPnL / totalInvested) * 100 : 0 }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 14) {
                    portfolioCard
                    
                    HStack {
                        Text("АКТИВЫ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        if let trend = engine.state?.marketTrend {
                            Text("РЫНОК: \(trend.displayName.uppercased())")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(trend == .bull ? .gainGreen : (trend == .bear ? .lossCoral : .gray))
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    LazyVStack(spacing: 10) {
                        ForEach(engine.assets) { asset in
                            AssetRowView(asset: asset)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("СТОИМОСТЬ ПОРТФЕЛЯ")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(formatMoney(totalValue))
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // All-time return badge
            HStack(spacing: 6) {
                Image(systemName: totalPnL >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 11))
                Text("\(formatMoney(totalPnL)) (\(formatSignedPercent(totalPnLPct)))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                Text("ЗА ВСЁ ВРЕМЯ")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .foregroundColor(totalPnL >= 0 ? .gainGreen : .lossCoral)
            
            Divider().background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("ВЛОЖЕНО")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(formatMoney(totalInvested))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("СВОБОДНЫЕ СРЕДСТВА")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(formatMoney(engine.state?.cash ?? 0))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.brandAccent)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.brandAccent.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct AssetRowView: View {
    @Environment(GameEngine.self) var engine
    let asset: Asset
    @State private var isExpanded = false
    
    private var owned: Bool { asset.quantityOwned > 0 }
    private var invested: Double { asset.purchasePrice * Double(asset.quantityOwned) }
    private var marketValue: Double { asset.currentMarketPrice * Double(asset.quantityOwned) }
    private var pnl: Double { marketValue - invested }
    private var pnlPct: Double { invested > 0 ? (pnl / invested) * 100 : 0 }
    private var pnlColor: Color { pnl >= 0 ? .gainGreen : .lossCoral }
    
    private var trendColor: Color {
        if asset.priceHistory.count >= 2 {
            let last = asset.priceHistory[asset.priceHistory.count - 1].value
            let prev = asset.priceHistory[asset.priceHistory.count - 2].value
            if last > prev { return .gainGreen }
            if last < prev { return .lossCoral }
        }
        return .gray
    }
    
    private var tickChange: String {
        if asset.priceHistory.count >= 2 {
            let last = asset.priceHistory[asset.priceHistory.count - 1].value
            let prev = asset.priceHistory[asset.priceHistory.count - 2].value
            return formatSignedPercent(((last - prev) / prev) * 100)
        }
        return "0.0%"
    }
    
    // Safe Y-axis domain so Swift Charts never receives a zero-height (NaN) domain.
    private var yDomain: ClosedRange<Double> {
        let values = asset.priceHistory.map { $0.value }
        guard let minV = values.min(), let maxV = values.max() else { return 0...1 }
        if minV == maxV {
            let pad = maxV == 0 ? 1 : abs(maxV) * 0.1
            return (minV - pad)...(maxV + pad)
        }
        let pad = (maxV - minV) * 0.15
        return (minV - pad)...(maxV + pad)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            collapsedHeader
            if isExpanded { expandedDetail }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? Color.brandAccent.opacity(0.45) : Color.gray.opacity(0.25), lineWidth: 1)
        )
    }
    
    private var collapsedHeader: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(asset.name)
                    .font(.system(.subheadline, design: .monospaced).bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                if owned {
                    Text("\(asset.quantityOwned) × \(formatMoney(asset.purchasePrice))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                } else {
                    Text(asset.category.displayName.uppercased())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 108, alignment: .leading)
            
            // Sparkline
            Chart {
                ForEach(Array(asset.priceHistory.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("T", index), y: .value("P", value.value))
                        .foregroundStyle(trendColor)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    AreaMark(x: .value("T", index), y: .value("P", value.value))
                        .foregroundStyle(
                            LinearGradient(colors: [trendColor.opacity(0.3), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: yDomain)
            .frame(height: 38)
            
            VStack(alignment: .trailing, spacing: 3) {
                Text(formatMoney(asset.currentMarketPrice))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                if owned {
                    Text(formatSignedPercent(pnlPct))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(pnlColor)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(pnlColor.opacity(0.18))
                        .cornerRadius(4)
                } else {
                    Text(tickChange)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(trendColor)
                }
            }
            .frame(width: 78, alignment: .trailing)
        }
        .padding(12)
        .contentShape(Rectangle())
        .onTapGesture {
            menuAction {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isExpanded.toggle() }
            }
        }
    }
    
    private var expandedDetail: some View {
        VStack(spacing: 14) {
            Divider().background(Color.gray.opacity(0.25))
            
            // Holding P/L banner (only if owned)
            if owned {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ВАША ДОХОДНОСТЬ")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(formatMoney(pnl))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(pnlColor)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: pnl >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 12))
                        Text(formatSignedPercent(pnlPct))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(pnlColor)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(pnlColor.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            
            // Stats grid
            VStack(spacing: 10) {
                statRow("РЫН. ЦЕНА", formatMoney(asset.currentMarketPrice),
                        "СР. ЦЕНА", owned ? formatMoney(asset.purchasePrice) : "—")
                statRow("В ЛАДЕЛИИ", "\(asset.quantityOwned)",
                        "РЫН. СТОИМ.", formatMoney(marketValue))
                statRow("ВЛОЖЕНО", formatMoney(invested),
                        "КАТЕГОРИЯ", asset.category.displayName.uppercased())
            }
            .padding(.horizontal)
            
            // Detailed chart
            VStack(alignment: .leading, spacing: 4) {
                Text("ИСТОРИЯ ЦЕНЫ (10 ТИКОВ)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
                Chart {
                    ForEach(Array(asset.priceHistory.enumerated()), id: \.offset) { index, value in
                        LineMark(x: .value("Time", index), y: .value("Price", value.value))
                            .foregroundStyle(trendColor)
                            .symbol(Circle().strokeBorder(lineWidth: 2)).symbolSize(28)
                        AreaMark(x: .value("Time", index), y: .value("Price", value.value))
                            .foregroundStyle(
                                LinearGradient(colors: [trendColor.opacity(0.25), .clear],
                                               startPoint: .top, endPoint: .bottom)
                            )
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel() {
                            if let d = value.as(Double.self) {
                                Text(formatMoney(d))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        AxisGridLine().foregroundStyle(.gray.opacity(0.15))
                    }
                }
                .chartYScale(domain: yDomain)
                .frame(height: 130)
            }
            .padding(.horizontal)
            
            // Trade buttons
            HStack(spacing: 8) {
                tradeButton("ПРОД. ВСЁ", .lossCoral, filled: false) { engine.sellMax(asset) }
                tradeButton("ПРОД. 1", .lossCoral, filled: true) { engine.sellAsset(asset, quantity: 1) }
                tradeButton("КУП. 1", .gainGreen, filled: true) { engine.buyAsset(asset, quantity: 1) }
                tradeButton("КУП. ВСЁ", .gainGreen, filled: false) { engine.buyMax(asset) }
            }
            .padding(.horizontal)
            .padding(.bottom, 14)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
    
    private func statRow(_ l1: String, _ v1: String, _ l2: String, _ v2: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(l1).font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                Text(v1).font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(l2).font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
                Text(v2).font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
            }
        }
    }
    
    private func tradeButton(_ title: String, _ color: Color, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { menuAction { action() } }) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(filled ? color.opacity(0.85) : color.opacity(0.15))
                .foregroundColor(filled ? .black : color)
                .cornerRadius(8)
        }
    }
}
