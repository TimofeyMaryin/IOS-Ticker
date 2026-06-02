import SwiftUI
import WebKit

struct PrivacyWebView: View {
    let url: URL
    let onAccepted: () -> Void

    var body: some View {
        PrivacyWebViewRepresentable(url: url, onAccepted: onAccepted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.04, green: 0.04, blue: 0.05))
            .ignoresSafeArea()
    }
}

private struct PrivacyWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let onAccepted: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAccepted: onAccepted)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "tickerPrivacy")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.load(URLRequest(url: url))

        context.coordinator.webView = webView
        FirebaseService.shared.logScreen("privacy_webview")
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "tickerPrivacy")
        coordinator.webView = nil
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let onAccepted: () -> Void
        weak var webView: WKWebView?

        init(onAccepted: @escaping () -> Void) {
            self.onAccepted = onAccepted
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "tickerPrivacy",
                  let body = message.body as? [String: Any],
                  body["action"] as? String == "privacy_accept"
            else { return }

            let version = body["version"] as? String
            FirebaseService.shared.logPrivacyAccepted(version: version)

            DispatchQueue.main.async {
                self.onAccepted()
            }
        }
    }
}
