import SwiftUI
import WebKit

struct SimpleWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}

struct InAppBrowserView: View {
    let page: InAppWebPage
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(page.title)
                    .font(.system(.headline, design: .monospaced).bold())
                    .foregroundColor(.white)
                Spacer()
                Button(action: { menuAction { onClose() } }) {
                    Image(systemName: "xmark")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(red: 0.06, green: 0.06, blue: 0.08))

            Rectangle()
                .fill(Color.brandAccent.opacity(0.5))
                .frame(height: 1)

            SimpleWebView(url: page.url)
                .background(Color(red: 0.04, green: 0.04, blue: 0.05))
        }
        .background(Color.black)
        .onAppear {
            FirebaseService.shared.logScreen(page.analyticsScreen)
        }
    }
}
