import SwiftUI
import WebKit

@main
struct MoonRabbitPlannerApp: App {
    var body: some Scene {
        WindowGroup {
            PlannerWebView()
                .background(Color(red: 0.97, green: 0.96, blue: 0.94))
        }
    }
}

/// All planner code and artwork ships with the app; personal records stay on-device.
struct PlannerWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController.addUserScript(WKUserScript(
            source: "window.moonRabbit = { platform: 'ipad' };",
            injectionTime: .atDocumentStart, forMainFrameOnly: true
        ))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .systemBackground
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.accessibilityIdentifier = "plannerWebView"
        view.allowsBackForwardNavigationGestures = false
        if let directory = Bundle.main.resourceURL?.appendingPathComponent("web", isDirectory: true) {
            context.coordinator.resourceDirectory = directory.standardizedFileURL
            view.loadFileURL(directory.appendingPathComponent("index.html"), allowingReadAccessTo: directory)
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        var resourceDirectory: URL?

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { decisionHandler(.cancel); return }
            if url.isFileURL, let directory = resourceDirectory,
               url.standardizedFileURL.path.hasPrefix(directory.path + "/") {
                decisionHandler(.allow)
                return
            }
            // Attribution links open in the system browser, never inside the local planner.
            let allowedHosts: Set<String> = ["open-meteo.com", "www.open-meteo.com", "openstreetmap.org", "www.openstreetmap.org", "geonames.org", "www.geonames.org", "photon.komoot.io", "github.com"]
            if action.navigationType == .linkActivated, url.scheme == "https",
               let host = url.host?.lowercased(), allowedHosts.contains(host) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }
}
