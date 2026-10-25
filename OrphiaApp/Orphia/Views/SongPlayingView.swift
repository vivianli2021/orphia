import SwiftUI

/// Keeps the original layout — big artwork area, title, artist, transport row —
/// but the artwork area is now a real embedded YouTube player. Tapping any song
/// (Browse, Continue Listening, Play Favorites, or a Memory) loads that video
/// here and autoplays it.
///
/// IMPORTANT (copyright): there is intentionally no lyrics display on this
/// screen. An earlier placeholder lyrics block was removed outright — even
/// generic/non-real placeholder text invited someone to eventually swap in
/// real lyrics for whatever song is loaded, which would be a copyright
/// violation. If synced lyrics become a real feature later, it needs a
/// separately licensed lyrics source and a deliberate decision, not a quiet
/// re-add of this block.
struct SongPlayingView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                YouTubePlayerView(videoID: appState.currentSong.id, isPlaying: $appState.isPlaying)
                    .aspectRatio(16.0/9.0, contentMode: .fit)
                    .cornerRadius(16)
                    .background(Color.black)

                Text(appState.currentSong.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text(appState.currentSong.artist)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.muted)
                Text(appState.currentSong.genreLine.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.primaryDark)

                // Favorite and dislike are mutually exclusive (see AppState.toggleFavorite/
                // toggleDislike). A dislike removes the song from Browse and favorites.
                HStack(spacing: 24) {
                    ctrlButton(systemName: "hand.thumbsdown", size: 56, iconSize: 22, active: appState.isDisliked(appState.currentSong), activeColor: AppColors.rust) {
                        let song = appState.currentSong
                        let oldIndex = appState.currentPlaylist.firstIndex(of: song)
                        appState.toggleDislike(song)
                        // A dislike removes the song from either playlist, so move on
                        // to whatever now sits at its old position.
                        if appState.isDisliked(song), let oldIndex {
                            let playlist = appState.currentPlaylist
                            if !playlist.isEmpty {
                                appState.play(playlist[min(oldIndex, playlist.count - 1)], context: appState.playlistContext)
                            }
                        }
                    }
                    ctrlButton(systemName: "heart.fill", size: 56, iconSize: 22, active: appState.isFavorite(appState.currentSong), activeColor: AppColors.carnation) {
                        appState.toggleFavorite(appState.currentSong)
                    }
                }
                .padding(.top, 6)

                // Back/forward step through the normal Browse list, or only through
                // favorites when the song was picked from Play Favorites.
                HStack(spacing: 28) {
                    stepButton(systemName: "backward.end.fill") { step(by: -1) }

                    Button {
                        appState.isPlaying.toggle()
                    } label: {
                        Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 76, height: 76)
                            .background(AppColors.primary)
                            .clipShape(Circle())
                    }

                    stepButton(systemName: "forward.end.fill") { step(by: 1) }
                }
                .padding(.top, 4)

                Button("💬  Share a Memory") { path.append(.memoryCapture) }
                    .buttonStyle(SecondaryButtonStyle())
                    .font(.system(size: 21, weight: .semibold))
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// False when the active playlist has no other song to step to (empty, or
    /// only the one currently playing).
    private var canStep: Bool {
        appState.currentPlaylist.contains { $0.id != appState.currentSong.id }
    }

    /// Steps through the active playlist with wraparound. If the current song
    /// isn't in it (e.g. just un-hearted while playing favorites), forward goes
    /// to the first song and back to the last.
    private func step(by delta: Int) {
        let playlist = appState.currentPlaylist
        guard !playlist.isEmpty else { return }
        let next: Song
        if let index = playlist.firstIndex(of: appState.currentSong) {
            next = playlist[(index + delta + playlist.count) % playlist.count]
        } else {
            next = delta > 0 ? playlist[0] : playlist[playlist.count - 1]
        }
        appState.play(next, context: appState.playlistContext)
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22))
                .foregroundColor(AppColors.ink)
                .frame(width: 56, height: 56)
                .background(Color.white)
                .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
                .clipShape(Circle())
        }
        .disabled(!canStep)
        .opacity(canStep ? 1 : 0.4)
    }

    private func ctrlButton(systemName: String, size: CGFloat, iconSize: CGFloat, active: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize))
                .foregroundColor(active ? activeColor : AppColors.ink)
                .frame(width: size, height: size)
                .background(Color.white)
                .overlay(Circle().stroke(active ? activeColor : AppColors.border, lineWidth: 2))
                .clipShape(Circle())
        }
    }
}
