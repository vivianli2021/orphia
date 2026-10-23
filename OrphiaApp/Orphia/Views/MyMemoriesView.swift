import SwiftUI

/// New library screen, reachable from Home, answering "where do my saved memories
/// go?" Every memory shows the song it's connected to alongside a dedicated round
/// play button for the voice recording itself — tapping the song info (not the play
/// button) jumps to that song's Song Playing screen. Still private-only per MVP scope.
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
                Text("Tap ▶ to listen back. Tap a memory to jump to its song.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 12)

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

                if !appState.memories.isEmpty {
                    Text("That's every memory you've shared so far.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else {
                    Text("No memories yet — share one from the Song Playing screen.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 30)
                }
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("My Memories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
