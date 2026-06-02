import SwiftUI

struct SkillTreeView: View {
    @Environment(GameEngine.self) var engine
    @State private var selectedSkill: Skill?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                Text("ДЕРЕВО НАВЫКОВ")
                    .font(.system(.title, design: .monospaced).bold())
                    .foregroundColor(Color.brandAccent)
                    .padding(.top)
                
                Text("Тратьте наличные на постоянные пассивные способности.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(engine.skills) { skill in
                            SkillRowView(skill: skill) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedSkill = skill
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Detail Overlay
            if let skill = selectedSkill {
                Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedSkill = nil
                        }
                    }
                
                SkillDetailView(skill: skill) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedSkill = nil
                    }
                }
                .environment(engine)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }
}

struct SkillRowView: View {
    let skill: Skill
    let action: () -> Void
    
    var body: some View {
        Button(action: { menuAction { action() } }) {
            HStack(spacing: 12) {
                skillIcon(size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.name)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(skill.isUnlocked ? Color.brandAccent : .white)
                        .lineLimit(1)
                    
                    Text("УРОВЕНЬ \(skill.tier)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if skill.isUnlocked {
                    Text("ОТКРЫТ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.brandAccent.opacity(0.18))
                        .cornerRadius(4)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(skill.isUnlocked ? Color.brandAccent.opacity(0.4) : Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func skillIcon(size: CGFloat) -> some View {
        if let assetName = GameAssets.skillImageName(for: skill.name, tier: skill.tier) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(skill.isUnlocked ? 1 : 0.45)
                .overlay {
                    if !skill.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.gray)
                    }
                }
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: skill.isUnlocked ? "bolt.fill" : "lock.fill")
                        .foregroundColor(skill.isUnlocked ? Color.brandAccent : .gray)
                        .font(.system(size: size * 0.48))
                )
        }
    }
}

struct SkillDetailView: View {
    @Environment(GameEngine.self) var engine
    let skill: Skill
    let onClose: () -> Void
    
    var canAfford: Bool {
        return (engine.state?.cash ?? 0) >= skill.cashCost
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

                        if let assetName = GameAssets.skillImageName(for: skill.name, tier: skill.tier) {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .opacity(skill.isUnlocked ? 1 : 0.5)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.brandAccent.opacity(0.5))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(skill.name.uppercased())
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(skill.desc)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Analytics Grid
                    VStack(spacing: 12) {
                        Text("О НАВЫКЕ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "СТАТУС", value: skill.isUnlocked ? "ОТКРЫТ" : "ЗАКРЫТ", valueColor: skill.isUnlocked ? Color.brandAccent : .gray)
                            AnalyticCard(title: "УРОВЕНЬ", value: "\(skill.tier)")
                        }
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "ЦЕНА", value: formatMoney(skill.cashCost), valueColor: .white)
                            AnalyticCard(title: "ТИП", value: "ПАССИВ", valueColor: .cyan)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            
            // Bottom Action Bar
            VStack {
                if skill.isUnlocked {
                    Text("НАВЫК ПОЛУЧЕН")
                        .font(.system(.headline, design: .monospaced).bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandAccent.opacity(0.2))
                        .foregroundColor(Color.brandAccent)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .padding(.top, 10)
                } else {
                    Button(action: { menuAction { engine.unlockSkill(skill) } }) {
                        HStack {
                            Text("ОТКРЫТЬ")
                                .font(.system(.headline, design: .monospaced).bold())
                            Spacer()
                            Text(formatMoney(skill.cashCost))
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
