import SwiftUI

/// Did not exist in the original sketches — this is what "Play Music" opens into.
/// Personalized on BOTH axes: filtered down to just the genres the resident
/// picked at Sign Up (genre preference), within songs from their computed age
/// bracket (decade) — and within each shown genre, the FULL set the CSV has
/// for that bracket (10 for Classical, 4 for every other genre), not a
/// hand-picked sample. Each row is a real YouTube video; tapping it loads and
/// autoplays that video on the Song Playing screen.
struct BrowseView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose a Song")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text("Picked for your favorite genres and decade — tap any song to play it.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 8)

                ForEach(appState.librarySections, id: \.genre) { group in
                    Text(group.genre.rawValue.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.muted)
                        .padding(.top, 14)
                        .padding(.bottom, 4)

                    ForEach(group.songs) { song in
                        Button {
                            appState.play(song)
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
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.inline)
    }
}
