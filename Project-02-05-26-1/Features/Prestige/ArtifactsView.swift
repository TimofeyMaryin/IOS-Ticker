import SwiftUI

struct ArtifactsView: View {
    @Environment(GameEngine.self) var engine
    @State private var showPrestigeAlert = false
    @State private var selectedArtifact: Artifact?
    
    var canPrestige: Bool {
        return (engine.state?.netWorth ?? 0) >= 1_000_000
    }
    
    var tokensEarnedIfPrestige: Int {
        return Int((engine.state?.netWorth ?? 0) / 1_000_000)
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                Text("ЧЁРНЫЙ РЫНОК")
                    .font(.system(.title, design: .monospaced).bold())
                    .foregroundColor(Color.lossCoral)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if let state = engine.state {
                            HStack {
                                HStack(spacing: 6) {
                                    Image("dark-token")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    Text("ТЁМНЫЕ ТОКЕНЫ:")
                                        .font(.system(.headline, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("\(state.darkTokens)")
                                    .font(.system(.title3, design: .monospaced).bold())
                                    .foregroundColor(Color.lossCoral)
                            }
                            .padding()
                            .background(Color.lossCoral.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Button(action: { menuAction { showPrestigeAlert = true } }) {
                            VStack {
                                Text("ОБЪЯВИТЬ БАНКРОТСТВО")
                                    .font(.system(.headline, design: .monospaced).bold())
                                Text("Сброс прогресса → \(tokensEarnedIfPrestige) тёмных токенов")
                                    .font(.system(.caption, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canPrestige ? Color.lossCoral : Color.gray.opacity(0.3))
                            .foregroundColor(canPrestige ? .black : .gray)
                            .cornerRadius(10)
                        }
                        .disabled(!canPrestige)
                        .alert(isPresented: $showPrestigeAlert) {
                            Alert(
                                title: Text("Объявить банкротство?"),
                                message: Text("Обнулятся наличные, активы и аналитики. Вы получите \(tokensEarnedIfPrestige) тёмных токенов. Артефакты сохранятся навсегда."),
                                primaryButton: .destructive(Text("Сделать")) {
                                    engine.resetPrestige()
                                },
                                secondaryButton: .cancel(Text("Отмена"))
                            )
                        }
                        
                        Text("АРТЕФАКТЫ")
                            .font(.system(.headline, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(engine.artifacts) { artifact in
                                ArtifactRowView(artifact: artifact) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedArtifact = artifact
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Detail Overlay
            if let artifact = selectedArtifact {
                Color.black.opacity(0.85).edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedArtifact = nil
                        }
                    }
                
                ArtifactDetailView(artifact: artifact) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedArtifact = nil
                    }
                }
                .environment(engine)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }
}

struct ArtifactRowView: View {
    let artifact: Artifact
    let action: () -> Void
    
    var body: some View {
        Button(action: { menuAction { action() } }) {
            HStack(spacing: 12) {
                artifactIcon(size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.name)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(artifact.isOwned ? Color.lossCoral : .white)
                        .lineLimit(1)
                    
                    Text("\(artifact.tokenCost) ТКН")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if artifact.isOwned {
                    Text("КУПЛЕН")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.lossCoral)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.lossCoral.opacity(0.18))
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
                    .stroke(artifact.isOwned ? Color.lossCoral.opacity(0.4) : Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func artifactIcon(size: CGFloat) -> some View {
        if let assetName = GameAssets.artifactImageName(for: artifact.name, tokenCost: artifact.tokenCost) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(artifact.isOwned ? 1 : 0.45)
                .overlay {
                    if !artifact.isOwned {
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
                    Image(systemName: artifact.isOwned ? "crown.fill" : "lock.fill")
                        .foregroundColor(artifact.isOwned ? Color.lossCoral : .gray)
                        .font(.system(size: size * 0.48))
                )
        }
    }
}

struct ArtifactDetailView: View {
    @Environment(GameEngine.self) var engine
    let artifact: Artifact
    let onClose: () -> Void
    
    var canAfford: Bool {
        return (engine.state?.darkTokens ?? 0) >= artifact.tokenCost
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
                                    .stroke(Color.lossCoral.opacity(0.3), lineWidth: 1)
                            )

                        if let assetName = GameAssets.artifactImageName(for: artifact.name, tokenCost: artifact.tokenCost) {
                            Image(assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .opacity(artifact.isOwned ? 1 : 0.5)
                        } else {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color.lossCoral.opacity(0.5))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(artifact.name.uppercased())
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(artifact.desc)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Analytics Grid
                    VStack(spacing: 12) {
                        Text("ОБ АРТЕФАКТЕ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            AnalyticCard(title: "СТАТУС", value: artifact.isOwned ? "КУПЛЕН" : "ЗАКРЫТ", valueColor: artifact.isOwned ? Color.lossCoral : .gray)
                            AnalyticCard(title: "ЦЕНА", value: "\(artifact.tokenCost) ТКН", valueColor: .white)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            
            // Bottom Action Bar
            VStack {
                if artifact.isOwned {
                    Text("АРТЕФАКТ ПОЛУЧЕН")
                        .font(.system(.headline, design: .monospaced).bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lossCoral.opacity(0.2))
                        .foregroundColor(Color.lossCoral)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .padding(.top, 10)
                } else {
                    Button(action: { menuAction { engine.buyArtifact(artifact) } }) {
                        HStack {
                            Text("КУПИТЬ АРТЕФАКТ")
                                .font(.system(.headline, design: .monospaced).bold())
                            Spacer()
                            Text("\(artifact.tokenCost) ТКН")
                                .font(.system(.headline, design: .monospaced).bold())
                        }
                        .padding()
                        .background(canAfford ? Color.lossCoral.opacity(0.85) : Color.gray.opacity(0.3))
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
