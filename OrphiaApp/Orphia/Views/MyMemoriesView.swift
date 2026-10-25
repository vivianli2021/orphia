import SwiftUI

/// Library screen, reachable from Home, answering "where do my saved memories
/// go?" Each memory shows the song it's connected to: tap ▶ to hear the
/// recording, tap the song to read what was said. Still private-only per MVP scope.
struct MyMemoriesView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @StateObject private var playbackManager = AudioPlaybackManager()
    @State private var transcriptFor: MemoryRef?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Memories")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)
                Text("Tap ▶ to listen back. Tap a song to read what you said.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.muted)
                    .padding(.bottom, 12)

                ForEach(appState.memories) { memory in
                    HStack(spacing: 14) {
                        Button {
                            transcriptFor = MemoryRef(id: memory.id)
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
                        .accessibilityHint("Shows what you said in this memory")

                        Button {
                            playbackManager.toggle(memory: memory)
                        } label: {
                            Image(systemName: playbackManager.currentlyPlayingID == memory.id ? "pause.fill" : "play.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(playbackManager.currentlyPlayingID == memory.id ? AppColors.carnationDark : AppColors.carnation)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(playbackManager.currentlyPlayingID == memory.id ? "Pause recording" : "Play recording")
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
        .sheet(item: $transcriptFor) { ref in
            MemoryTranscriptView(memoryID: ref.id) { song in
                transcriptFor = nil
                appState.play(song)
                path.append(.playing)
            }
        }
    }
}

private struct MemoryRef: Identifiable {
    let id: UUID
}

/// Reads back what the resident said in a memory. Looks the memory up by ID
/// so the text appears as soon as transcription finishes, even if the sheet
/// is already open.
private struct MemoryTranscriptView: View {
    let memoryID: UUID
    let onPlaySong: (Song) -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var memory: Memory? {
        appState.memories.first { $0.id == memoryID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let memory {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            SongThumbnail(song: memory.song, size: 56)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(memory.song.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.ink)
                                Text("\(memory.song.artist) · \(memory.dateLabel)")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.muted)
                            }
                        }

                        Text("WHAT YOU SAID")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.muted)
                            .padding(.top, 8)

                        transcriptBody(for: memory)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.border, lineWidth: 2))
                            .cornerRadius(14)

                        Button("▶  Play This Song") { onPlaySong(memory.song) }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .background(AppColors.bg)
            .navigationTitle("Your Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .onAppear { appState.transcribeMemory(id: memoryID) }
    }

    @ViewBuilder
    private func transcriptBody(for memory: Memory) -> some View {
        if memory.audioFileName.isEmpty {
            Text("This is a sample memory, so there's no recording to read.")
                .font(.system(size: 18))
                .foregroundColor(AppColors.muted)
        } else {
            switch memory.transcript {
            case .notStarted, .inProgress:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Writing out your memory…")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.muted)
                }
            case .done(let text):
                Text(text.isEmpty ? "We couldn't make out any words in this recording." : text)
                    .font(.system(size: 20))
                    .lineSpacing(6)
                    .foregroundColor(AppColors.ink)
                    .textSelection(.enabled)
            case .failed(let message):
                VStack(alignment: .leading, spacing: 12) {
                    Text(message)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.rust)
                    Button("Try Again") { appState.transcribeMemory(id: memory.id, retry: true) }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
}
