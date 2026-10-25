import SwiftUI

/// New library screen, reachable from Home, listing every song the resident has
/// favorited (heart on Song Playing) — most recently favorited first. Favorite
/// and dislike are mutually exclusive (see AppState.toggleFavorite), so nothing
/// shown here can also be in the disliked/removed set.
struct FavoritesView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Favorites")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text("Songs you've hearted — tap one to play it.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 12)

                ForEach(appState.favoriteSongs) { song in
                    Button {
                        appState.play(song)
                        path.append(.playing)
                    } label: {
                        HStack(spacing: 14) {
                            SongThumbnail(song: song, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.ink)
                                Text(song.artist)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.muted)
                            }
                            Spacer()
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppColors.carnation)
                        }
                        .padding(14)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 2))
                        .cornerRadius(14)
                    }
                }

                if appState.favoriteSongs.isEmpty {
                    Text("No favorites yet — tap ♥ on a song's playing screen to save it here.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                }
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("My Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
