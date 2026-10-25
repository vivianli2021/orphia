import SwiftUI

/// Library screen, reachable from Home, for everything the resident has saved
/// about songs: favorites and voice-memo reflections together on one screen —
/// these aren't separate destinations, since both answer the same question
/// ("where do my saved songs/memories go?"). Favorites: tap a row to jump
/// straight to that song. Memories: tap the song info to jump to its Song
/// Playing screen, tap ▶ to hear the recording itself. Still private-only per
/// MVP scope.
struct MyMemoriesView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @StateObject private var playbackManager = AudioPlaybackManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Memories")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text("Your favorite songs and saved reflections, all in one place.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 12)

                sectionHeader("Favorites")

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
                        .padding(.vertical, 8)
                }

                sectionHeader("Reflections")

                ForEach(appState.memories) { memory in
                    HStack(spacing: 14) {
                        Button {
                            appState.play(memory.song)
                            path.append(.playing)
                        } label: {
                            HStack(spacing: 14) {
                                SongThumbnail(song: memory.song, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(memory.song.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppColors.ink)
                                    Text("\(memory.song.artist) · \(memory.dateLabel)")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.muted)
                                }
                                Spacer()
                            }
                        }

                        Button {
                            playbackManager.toggle(memory: memory)
                        } label: {
                            Image(systemName: playbackManager.currentlyPlayingID == memory.id ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(playbackManager.currentlyPlayingID == memory.id ? AppColors.carnationDark : AppColors.carnation)
                                .clipShape(Circle())
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 2))
                    .cornerRadius(14)
                }

                if appState.memories.isEmpty {
                    Text("No memories yet — share one from the Song Playing screen.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.muted)
                        .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("My Memories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(AppColors.muted)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }
}
