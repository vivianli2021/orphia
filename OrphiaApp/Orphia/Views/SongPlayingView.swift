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
                // clean, symmetric back / pause / forward layout.
                HStack(spacing: 24) {
                    ctrlButton(systemName: "hand.thumbsdown", size: 56, iconSize: 22, active: appState.thumbsDown, activeColor: AppColors.rust) {
                        appState.thumbsDown.toggle()
                    }
                    ctrlButton(systemName: "heart.fill", size: 56, iconSize: 22, active: appState.isFavorite, activeColor: AppColors.carnation) {
                        appState.isFavorite.toggle()
                    }
                }
                .padding(.top, 6)

                // Transport row: pause/play is the true center, with back and
                // forward symmetric on either side of it.
                HStack(spacing: 28) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.ink)
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                        .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
                        .clipShape(Circle())

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

                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.ink)
                        .frame(width: 56, height: 56)
                        .background(Color.white)
                        .overlay(Circle().stroke(AppColors.border, lineWidth: 2))
                        .clipShape(Circle())
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
