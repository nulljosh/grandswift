import SwiftUI
import WebKit

// iOS + macOS shell: the full game is the web build, so every platform plays the same thing.
// ponytail: loads the live site, needs a connection (the 3D tiles do anyway). Bundle site/ for offline if it matters.
let gameURL = URL(string: "https://rainjack.heyitsmejosh.com/play.html")!

#if os(macOS)
struct Web: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { let v = WKWebView(); v.load(URLRequest(url: gameURL)); return v }
    func updateNSView(_ v: WKWebView, context: Context) {}
}
#else
struct Web: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let c = WKWebViewConfiguration(); c.allowsInlineMediaPlayback = true; c.mediaTypesRequiringUserActionForPlayback = []
        let v = WKWebView(frame: .zero, configuration: c); v.scrollView.isScrollEnabled = false; v.isOpaque = false; v.backgroundColor = .black
        v.load(URLRequest(url: gameURL)); return v
    }
    func updateUIView(_ v: WKWebView, context: Context) {}
}
#endif

@main struct RainjackApp: App {
    var body: some Scene {
        WindowGroup { Web().ignoresSafeArea().background(Color.black)
            #if os(iOS)
            .statusBarHidden()
            #else
            .onAppear { DispatchQueue.main.async { if let w = NSApp.windows.first, !w.styleMask.contains(.fullScreen) { w.toggleFullScreen(nil) } } }
            #endif
        }
    }
}
