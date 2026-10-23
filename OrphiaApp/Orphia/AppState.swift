import Foundation
import SwiftUI

enum Route: Hashable {
    case signUpName
    case signUpBirthYear
    case signUpGenres
    case login
    case home
    case browse
    case playing
    case memoryCapture
    case myMemories
}

/// Central app state shared across views via @EnvironmentObject.
/// MVP note: there is no backend — everything lives in memory for this prototype/demo build.
final class AppState: ObservableObject {
    // Identity captured during sign up / login (demo defaults mirror the HTML
    // prototype's "Dorothy" persona).
    @Published var firstName: String = "Dorothy"
    @Published var pin: String = "1234"
    @Published var birthYear: String = ""
    @Published var selectedGenres: Set<Genre> = []

    // Now-playing state.
    @Published var currentSong: Song = SongLibrary.defaultSong
    @Published var thumbsDown: Bool = false
    @Published var isFavorite: Bool = false

    // Saved voice-memo reflections. Seeded with a few demo entries so
    // "My Memories" isn't empty on first run, matching the wireframe.
    @Published var memories: [Memory] = [
        Memory(id: UUID(), song: SongLibrary.song(id: "y3KJ7d2qBoA")!, dateLabel: "Oct 12", audioFileName: ""),
        Memory(id: UUID(), song: SongLibrary.song(id: "c977QdbTImU")!, dateLabel: "Oct 9", audioFileName: ""),
        Memory(id: UUID(), song: SongLibrary.song(id: "E3McBWuZiuE")!, dateLabel: "Oct 3", audioFileName: ""),
    ]

    static let maxGenres = 4

    func toggleGenre(_ genre: Genre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else if selectedGenres.count < AppState.maxGenres {
            selectedGenres.insert(genre)
        }
        // if already at cap and genre isn't selected, tap is silently ignored —
        // mirrors the HTML prototype's toggleGenre() cap behavior.
    }

    func play(_ song: Song) {
        currentSong = song
        thumbsDown = false
        isFavorite = false
    }

    func addMemory(for song: Song, audioFileName: String) {
        let memory = Memory(id: UUID(), song: song, dateLabel: "Today", audioFileName: audioFileName)
        memories.insert(memory, at: 0)
    }
}
