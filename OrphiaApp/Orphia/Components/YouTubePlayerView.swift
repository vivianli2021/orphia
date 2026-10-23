import SwiftUI
import YouTubeiOSPlayerHelper

/// Hosts YouTube playback via Google's official `youtube-ios-player-helper`
/// library (`YTPlayerView`), not a hand-rolled WKWebView + raw iframe.
///
/// IMPORTANT (why not a plain WKWebView): loading `youtube.com/embed/<id>`
/// directly, or wrapping it in a local HTML string via `loadHTMLString`, both
/// fail in WKWebView with YouTube error 152 ("missing or invalid Referer
/// header") — WKWebView does not generate a real browser-style Referer for
/// those load paths, and manually setting a `Referer` header on the request is
/// unreliable (WebKit can silently drop a hand-set Referer on navigation; this
/// is a widely-reported WKWebView limitation, not something fixable from this
/// app's HTML). `YTPlayerView` is Google's own solution to exactly this
/// problem and is what production apps use to embed YouTube natively on iOS.
struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String?

    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.delegate = context.coordinator
        return playerView
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        guard let id = videoID, context.coordinator.lastLoadedID != id else { return }
        context.coordinator.lastLoadedID = id
        let playerVars: [String: Any] = [
            "playsinline": 1,
            "autoplay": 1,
            "rel": 0,
            "modestbranding": 1
        ]
        uiView.load(withVideoId: id, playerVars: playerVars)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, YTPlayerViewDelegate {
        var lastLoadedID: String?

        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            playerView.playVideo()
        }
    }
}
