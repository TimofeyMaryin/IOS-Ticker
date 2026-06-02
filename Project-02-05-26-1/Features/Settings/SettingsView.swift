import SwiftUI

struct SettingsView: View {
    @Environment(GameEngine.self) var engine
    @State private var showingPrestigeAlert = false
    @State private var webPage: InAppWebPage?
    
    var canPrestige: Bool {
        return (engine.state?.netWorth ?? 0) >= 1_000_000
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
            VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("НАСТРОЙКИ ИГРЫ")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("Скорость игры")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("Скорость", selection: Bindable(engine).gameSpeedMultiplier) {
                                Text("1×").tag(1.0)
                                Text("2×").tag(2.0)
                                Text("5×").tag(5.0)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ИНФОРМАЦИЯ")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.brandAccent)

                        infoLinkButton(title: "ЧАСТЫЕ ВОПРОСЫ", subtitle: "Механики, прогресс, престиж") {
                            webPage = .faq
                        }

                        infoLinkButton(title: "НОВОСТИ", subtitle: "Патчноуты и события") {
                            webPage = .news
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ЧЁРНЫЙ РЫНОК (ПРЕСТИЖ)")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(Color.lossCoral)
                        
                        Text("Сбросьте текущий прогресс (наличные, активы, аналитиков), чтобы получить постоянный бонус к пассивному доходу. Для доступа к чёрному рынку нужен капитал не менее $1 000 000.")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineSpacing(5)
                        
                        HStack {
                            Text("Текущий множитель:")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(String(format: "%.1f", engine.prestigeMultiplier))×")
                                .font(.system(.headline, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        .padding(.vertical, 5)
                        
                        Button(action: {
                            menuAction { showingPrestigeAlert = true }
                        }) {
                            Text("ОБЪЯВИТЬ БАНКРОТСТВО")
                                .font(.system(.headline, design: .monospaced).bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(canPrestige ? Color.lossCoral.opacity(0.3) : Color.gray.opacity(0.3))
                                .foregroundColor(canPrestige ? Color.lossCoral : .gray)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(canPrestige ? Color.lossCoral : Color.gray, lineWidth: 1)
                                )
                        }
                        .disabled(!canPrestige)
                        .alert(isPresented: $showingPrestigeAlert) {
                            Alert(
                                title: Text("Вы уверены?"),
                                message: Text("Наличные, активы и аналитики обнулятся. Вы начнёте заново с бонусом +50% к пассивному доходу."),
                                primaryButton: .destructive(Text("Сделать")) {
                                    engine.resetPrestige()
                                },
                                secondaryButton: .cancel(Text("Отмена"))
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }

            if let page = webPage {
                Color.black.opacity(0.97)
                    .ignoresSafeArea()
                    .zIndex(10)

                InAppBrowserView(page: page) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        webPage = nil
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(11)
            }
        }
    }

    private func infoLinkButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: { menuAction { action() } }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.subheadline, design: .monospaced).bold())
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.brandAccent.opacity(0.7))
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.brandAccent.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
