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

                // Reaction row: thumbs-down / favorite, as their own centered pair —
                // kept separate from transport so the transport row below can be a
                // clean, symmetric back / pause / forward layout. Mutually exclusive:
                // AppState.toggleFavorite/toggleDislike clear the other one. A dislike
                // also removes the song from this (and every future) playlist — see
                // AppState.librarySections — so advance away from it if it was playing.
                HStack(spacing: 24) {
                    ctrlButton(systemName: "hand.thumbsdown", size: 56, iconSize: 22, active: appState.isDisliked(appState.currentSong), activeColor: AppColors.rust) {
                        let song = appState.currentSong
                        let oldIndex = appState.currentPlaylist.firstIndex(where: { $0.id == song.id })
                        appState.toggleDislike(song)
                        // Disliking removes `song` from currentPlaylist, so step
                        // using where it WAS, landing on whatever now sits at (or
                        // just before, if it was last) that position.
                        if appState.isDisliked(song), let oldIndex {
                            let newPlaylist = appState.currentPlaylist
                            if !newPlaylist.isEmpty {
                                appState.play(newPlaylist[min(oldIndex, newPlaylist.count - 1)], context: appState.playlistContext)
                            }
                        }
                    }
                    ctrlButton(systemName: "heart.fill", size: 56, iconSize: 22, active: appState.isFavorite(appState.currentSong), activeColor: AppColors.carnation) {
                        appState.toggleFavorite(appState.currentSong)
                    }
                }
                .padding(.top, 6)

                // Transport row: pause/play is the true center, with back and
                // forward symmetric on either side of it. Back/forward step through
                // AppState.currentPlaylist (library or favorites, whichever is
                // active), wrapping around at either end. Dimmed + disabled rather
                // than silently doing nothing when that playlist has nothing (or
                // only this one song) to step to — e.g. a favorites playlist with
                // zero or one favorite.
                HStack(spacing: 28) {
                    Button { step(by: -1) } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.ink)
                            .frame(width: 56, height: 56)
                            .background(Color.white)
                            .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
                            .clipShape(Circle())
                    }
                    .disabled(!canStep)
                    .opacity(canStep ? 1 : 0.4)

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

                    Button { step(by: 1) } label: {
                        Image(systemName: "forward.end.fill")
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

    /// False when the active playlist has nothing else to step to — empty, or
    /// just this one song (e.g. a favorites playlist with only the song
    /// currently playing).
    private var canStep: Bool {
        appState.currentPlaylist.count > 1
    }

    /// Moves to the adjacent song in AppState.currentPlaylist (library or
    /// favorites, whichever is active), wrapping around at either end (delta
    /// is +1 for forward, -1 for back). The playlist can be empty (e.g. a
    /// favorites playlist with nothing favorited) — then this is a no-op
    /// rather than a crash.
    private func step(by delta: Int) {
        let playlist = appState.currentPlaylist
        guard !playlist.isEmpty,
              let currentIndex = playlist.firstIndex(where: { $0.id == appState.currentSong.id }) else { return }
        let nextIndex = (currentIndex + delta + playlist.count) % playlist.count
        appState.play(playlist[nextIndex], context: appState.playlistContext)
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
