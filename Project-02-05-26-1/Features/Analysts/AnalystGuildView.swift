import SwiftUI
import Charts

struct AnalystGuildView: View {
    @Environment(GameEngine.self) var engine
    @State private var selectedAnalyst: Analyst?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let state = engine.state {
                VStack(spacing: 0) {
                    // Header
                    Text("АГЕНТСТВО")
                        .font(.system(.title, design: .monospaced).bold())
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // Top Bar
                    HStack {
                        VStack(alignment: .leading) {
                            Text("НАЛИЧНЫЕ")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(formatMoney(state.cash))
                                .font(.system(.subheadline, design: .monospaced).bold())
                                .foregroundColor(Color.brandAccent)
                        }
                        
                        Spacer()
                        
                        let passiveIncome = engine.analysts.reduce(0) { $0 + (Double($1.quantityHired) * $1.cashPerTick) } * engine.prestigeMultiplier
                        
                        VStack(alignment: .trailing) {
                            Text("ПАССИВНЫЙ ДОХОД")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(formatMoney(passiveIncome))/день")
                                .font(.system(.subheadline, design: .monospaced).bold())
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(engine.analysts) { analyst in
                                AnalystRowView(analyst: analyst) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedAnalyst = analyst
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                Text("Загрузка...")
                    .foregroundColor(.white)
            }
            
            // Detail Overlay
            if let analyst = selectedAnalyst {
                Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedAnalyst = nil
                        }
                    }
                
                AnalystDetailView(analyst: analyst) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedAnalyst = nil
                    }
                }
                .environment(engine)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }
}

struct AnalystRowView: View {
    @Environment(GameEngine.self) var engine
    let analyst: Analyst
    let action: () -> Void
    
    var body: some View {
        Button(action: { menuAction { action() } }) {
            HStack(spacing: 12) {
                Image("investor-1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(analyst.name)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text("НАНЯТО: \(analyst.quantityHired)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("+\(formatMoney(analyst.cashPerTick))/день")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                
                Spacer()
                
                // Chevron icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(12)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalystDetailView: View {
    @Environment(GameEngine.self) var engine
    let analyst: Analyst
    let onClose: () -> Void
    
    var cost: Double {
        var c = analyst.currentHireCost
        if engine.hasUnlockedSkill(tier: 1) {
            c *= 0.9
        }
        return c
    }
    
    var canAfford: Bool {
        return (engine.state?.cash ?? 0) >= cost
    }
    
    var roiPerDay: Double {
        return cost > 0 ? (analyst.cashPerTick * engine.prestigeMultiplier) / cost * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ДОСЬЕ")
                    .font(.system(.headline, design: .monospaced).bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: { menuAction { onClose() } }) {
                    Image(systemName: "xmark")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
            
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color.gray.opacity(0.3), Color.black.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.brandAccent.opacity(0.3), lineWidth: 1)
                            )

                        Image("investor-1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(analyst.name.uppercased())
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Приносит пассивный доход, пока вас нет в игре.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Analytics Grid
                    VStack(spacing: 12) {
                        Text("АНАЛИТИКА")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        let baseIncome = analyst.cashPerTick
                        let actualIncome = baseIncome * engine.prestigeMultiplier
                        let totalContribution = actualIncome * Double(analyst.quantityHired)
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "НАНЯТО", value: "\(analyst.quantityHired)")
                            AnalyticCard(title: "БАЗ. ДОХОД", value: formatMoney(baseIncome) + "/д")
                        }
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "ФАКТ. ДОХОД", value: formatMoney(actualIncome) + "/д")
                            AnalyticCard(title: "ВСЕГО/ДЕНЬ", value: formatMoney(totalContribution) + "/д")
                        }
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "СТОИМОСТЬ", value: formatMoney(cost), valueColor: .white)
                            AnalyticCard(title: "ROI/ДЕНЬ", value: formatSignedPercent(roiPerDay), valueColor: .gainGreen)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            
            // Bottom Action Bar
            VStack {
                Button(action: { menuAction { engine.hireAnalyst(analyst) } }) {
                    HStack {
                        Text("НАНЯТЬ")
                            .font(.system(.headline, design: .monospaced).bold())
                        Spacer()
                        Text(formatMoney(cost))
                            .font(.system(.headline, design: .monospaced).bold())
                    }
                    .padding()
                    .background(canAfford ? Color.brandAccent.opacity(0.85) : Color.gray.opacity(0.3))
                    .foregroundColor(canAfford ? .black : .gray)
                    .cornerRadius(12)
                }
                .disabled(!canAfford)
                .padding(.horizontal)
                .padding(.bottom, 30)
                .padding(.top, 10)
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
        }
        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height * 0.85)
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: -5)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

struct AnalyticCard: View {
    let title: String
    let value: String
    var valueColor: Color = .cyan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
