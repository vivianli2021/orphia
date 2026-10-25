import SwiftUI

/// Core structure kept from the original sketch: welcome message plus big,
/// clearly separated actions. "Continue listening" pulls a real song
/// personalized to the resident's age bracket and selected genres;
/// "Play Favorites" opens the list of songs they've hearted.
/// "My Memories" gives reflection its own front-door from Home instead of
/// only being reachable mid-playback.
struct HomeView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthManager
    @State private var confirmingSignOut = false

    private var continueSong: Song { appState.defaultSong }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome, \(appState.firstName)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.ink)
                    .padding(.top, 8)

                Button {
                    appState.play(continueSong)
                    path.append(.playing)
                } label: {
                    HStack(spacing: 12) {
                        SongThumbnail(song: continueSong, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continue listening")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.muted)
                            Text("\(continueSong.title) — \(continueSong.artist)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.ink)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColors.border, lineWidth: 2))
                    .cornerRadius(16)
                }

                Button("▶  Play Music") { path.append(.browse) }
                    .buttonStyle(PrimaryButtonStyle())

                Button("♥  Play Favorites") { path.append(.favorites) }
                    .buttonStyle(SecondaryButtonStyle())

                Button("🎧  My Memories") { path.append(.myMemories) }
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Text(appState.firstName)
                    Button("Sign Out", role: .destructive) { confirmingSignOut = true }
                } label: {
                    ZStack {
                        Circle().fill(AppColors.primary)
                        Text(String(appState.firstName.prefix(1)))
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(width: 34, height: 34)
                }
                .accessibilityLabel("Account")
            }
        }
        // Confirm first — a stray tap shouldn't sign a resident out with no one around to help.
        .confirmationDialog("Sign out of Orphia?", isPresented: $confirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await auth.signOut(appState: appState) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

/// Shared song-art thumbnail: loads the real YouTube thumbnail image for a song.
struct SongThumbnail: View {
    let song: Song
    var size: CGFloat = 46

    var body: some View {
        AsyncImage(url: song.thumbnailURL) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                Rectangle().fill(AppColors.primary)
            }
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.2)
        .clipped()
    }
}
