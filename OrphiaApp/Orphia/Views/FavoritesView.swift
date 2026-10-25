import SwiftUI

/// What Home's "Play Favorites" opens: a Browse-style list of only the songs
/// the resident has hearted. Picking one plays it in the favorites playlist,
/// so Song Playing's back/forward stay within favorites.
struct FavoritesView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Favorites")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)

                if appState.favoriteSongs.isEmpty {
                    Text("No favorites yet. Tap ♥ while a song is playing to add it here.")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.muted)
                        .padding(.top, 8)

                    Button("▶  Browse Music") { path.append(.browse) }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 20)
                } else {
                    Text("Tap a song to play it. Use ⏮ ⏭ to move through your favorites.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.muted)
                        .padding(.bottom, 8)

                    ForEach(appState.favoriteSongs) { song in
                        Button {
                            appState.play(song, context: .favorites)
                            path.append(.playing)
                        } label: {
                            HStack(spacing: 14) {
                                SongThumbnail(song: song)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(song.title)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(AppColors.ink)
                                    Text(song.artist)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.muted)
                                }
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(AppColors.carnation)
                            }
                            .padding(.vertical, 10)
                        }
                        Divider().background(AppColors.border)
                    }
                }
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
