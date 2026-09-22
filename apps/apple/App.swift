import SwiftUI
import WebKit

// iOS + macOS shell: the full game is the web build, so every platform plays the same thing.
// ponytail: loads the live site, needs a connection (the 3D tiles do anyway). Bundle site/ for offline if it matters.
let gameURL = URL(string: "https://vancouvervice.heyitsmejosh.com/play.html")!

#if os(macOS)
// WKWebView on macOS has no Pointer Lock, so the app locks the mouse itself and feeds raw deltas to the page.
final class GameWebView: WKWebView {
    var locked = false, dx: CGFloat = 0, dy: CGFloat = 0
    func setLock(_ on: Bool) { guard on != locked else { return }; locked = on; CGAssociateMouseAndMouseCursorPosition(on ? 0 : 1); on ? NSCursor.hide() : NSCursor.unhide() }
    override var acceptsFirstResponder: Bool { true }
}
struct Web: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let v = GameWebView(); v.customUserAgent = "Mozilla/5.0 (Macintosh) AppleWebKit/605.1.15 (KHTML, like Gecko) VancouverViceApp"; v.load(URLRequest(url: gameURL))
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .leftMouseDown, .keyDown]) { e in
            switch e.type {
            case .leftMouseDown: if !v.locked { v.setLock(true) }
            case .keyDown: if e.keyCode == 53 { v.setLock(false) }
            default: if v.locked { v.dx += e.deltaX; v.dy += e.deltaY }
            }
            return e
        }
        // one JS call per frame with the summed deltas, instead of one per mouse event
        Timer.scheduledTimer(withTimeInterval: 1.0 / 120, repeats: true) { _ in
            guard v.dx != 0 || v.dy != 0 else { return }
            v.evaluateJavaScript("window.GS_mouse && GS_mouse(\(v.dx), \(v.dy))"); v.dx = 0; v.dy = 0
        }
        NSApp.windows.forEach { $0.acceptsMouseMovedEvents = true }
        return v
    }
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

@main struct VancouverViceApp: App {
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
