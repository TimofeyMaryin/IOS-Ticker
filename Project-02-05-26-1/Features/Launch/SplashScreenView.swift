import Lottie
import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                LottieAnimationView(animationName: "document-invest", loopMode: .loop)
                    .frame(width: 72, height: 72)

                VStack(spacing: 6) {
                    Text("БРОКЕР КЛИКЕР")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.brandAccent)

                    Text("Загрузка...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            FirebaseService.shared.logScreen("splash")
        }
    }
}
