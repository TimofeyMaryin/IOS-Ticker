import Lottie
import SwiftUI

struct LottieAnimationView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let view: Lottie.LottieAnimationView
        if let animation = LottieAnimation.named(animationName, bundle: .main) {
            view = Lottie.LottieAnimationView(animation: animation)
        } else if let animation = LottieAnimation.named(animationName, bundle: .main, subdirectory: "Anim") {
            view = Lottie.LottieAnimationView(animation: animation)
        } else if let animation = LottieAnimation.named(animationName, bundle: .main, subdirectory: "Resources/Anim") {
            view = Lottie.LottieAnimationView(animation: animation)
        } else {
            view = Lottie.LottieAnimationView(name: animationName, bundle: .main)
        }

        view.loopMode = loopMode
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        view.play()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let animationView = uiView.subviews.first as? Lottie.LottieAnimationView {
            if !animationView.isAnimationPlaying {
                animationView.play()
            }
        }
    }
}
