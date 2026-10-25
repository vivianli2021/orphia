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
///
/// `isPlaying` is a two-way binding: the Song Playing screen's pause button
/// sets it to drive the player, and the player's own delegate callbacks write
/// back into it (e.g. if playback state changes for a reason other than that
/// button), so the icon never drifts out of sync with what's actually playing.
struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String?
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        playerView.delegate = context.coordinator
        return playerView
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        guard let id = videoID else { return }

        if context.coordinator.lastLoadedID != id {
            context.coordinator.lastLoadedID = id
            context.coordinator.knownPlaying = true // autoplay on load
            let playerVars: [String: Any] = [
                "playsinline": 1,
                "autoplay": 1,
                "rel": 0,
                "modestbranding": 1
            ]
            uiView.load(withVideoId: id, playerVars: playerVars)
            return
        }

        guard isPlaying != context.coordinator.knownPlaying else { return }
        context.coordinator.knownPlaying = isPlaying
        if isPlaying {
            uiView.playVideo()
        } else {
            uiView.pauseVideo()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(isPlaying: $isPlaying) }

    final class Coordinator: NSObject, YTPlayerViewDelegate {
        var lastLoadedID: String?
        var knownPlaying = true
        private let isPlaying: Binding<Bool>

        init(isPlaying: Binding<Bool>) {
            self.isPlaying = isPlaying
        }

        func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
            playerView.playVideo()
        }

        func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
            switch state {
            case .playing:
                knownPlaying = true
                if !isPlaying.wrappedValue { isPlaying.wrappedValue = true }
            case .paused:
                knownPlaying = false
                if isPlaying.wrappedValue { isPlaying.wrappedValue = false }
            default:
                break
            }
        }
    }
}
