import Foundation

enum AppLinks {
    static let faq = URL(string: "https://ticker-web-delta.vercel.app/faq")!
    static let news = URL(string: "https://ticker-web-delta.vercel.app/news")!
}

enum InAppWebPage: Identifiable {
    case faq
    case news

    var id: String {
        switch self {
        case .faq: return "faq"
        case .news: return "news"
        }
    }

    var title: String {
        switch self {
        case .faq: return "FAQ"
        case .news: return "НОВОСТИ"
        }
    }

    var url: URL {
        switch self {
        case .faq: return AppLinks.faq
        case .news: return AppLinks.news
        }
    }

    var analyticsScreen: String {
        switch self {
        case .faq: return "faq_webview"
        case .news: return "news_webview"
        }
    }
}
