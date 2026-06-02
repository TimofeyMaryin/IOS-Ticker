import SwiftUI

struct OfflineProgressView: View {
    @Environment(GameEngine.self) var engine
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("ПОКА ВАС НЕ БЫЛО...")
                    .font(.system(.title2, design: .monospaced).bold())
                    .foregroundColor(.brandAccent)
                
                Text("Ваши аналитики продолжали работать и заработали:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Text(formatMoney(engine.offlineEarnings))
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .foregroundColor(.white)
                
                Button(action: {
                    menuAction { engine.showOfflinePopup = false }
                }) {
                    Text("ЗАБРАТЬ")
                        .font(.system(.headline, design: .monospaced).bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brandAccent)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding(30)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.brandAccent, lineWidth: 2)
            )
            .padding(40)
        }
    }
}

struct EventPopupView: View {
    @Environment(GameEngine.self) var engine
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            if let event = engine.currentEvent {
                VStack(spacing: 20) {
                    Text("СРОЧНЫЕ НОВОСТИ")
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundColor(.yellow)
                    
                    Text(event.title)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(event.description)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 15) {
                        Button(action: { menuAction { event.action1() } }) {
                            Text(event.option1)
                                .font(.system(.caption, design: .monospaced).bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                        }
                        
                        Button(action: { menuAction { event.action2() } }) {
                            Text(event.option2)
                                .font(.system(.caption, design: .monospaced).bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.3))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple, lineWidth: 1))
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(30)
                .background(Color(red: 0.15, green: 0.1, blue: 0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow, lineWidth: 2)
                )
                .padding(40)
            }
        }
    }
}
