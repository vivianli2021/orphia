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
    @Published var currentSong: Song = SongCatalog.fallbackSong(for: .seventies)
    @Published var thumbsDown: Bool = false
    @Published var isFavorite: Bool = false

    // Saved voice-memo reflections. Seeded with a few demo entries so
    // "My Memories" isn't empty on first run, matching the wireframe.
    @Published var memories: [Memory] = [
        Memory(id: UUID(), song: SongCatalog.song(id: "y3KJ7d2qBoA")!, dateLabel: "Oct 12", audioFileName: ""),
        Memory(id: UUID(), song: SongCatalog.song(id: "c977QdbTImU")!, dateLabel: "Oct 9", audioFileName: ""),
        Memory(id: UUID(), song: SongCatalog.song(id: "E3McBWuZiuE")!, dateLabel: "Oct 3", audioFileName: ""),
    ]

    static let maxGenres = 4

    /// The resident's current age bracket, computed from birth year — falls
    /// back to "70s" (matching the Dorothy demo persona) before a birth year
    /// has been entered or if it's unparseable.
    var ageBracket: AgeBracket {
        guard let year = Int(birthYear) else { return .seventies }
        return AgeBracket.current(birthYear: year)
    }

    /// Browse/Home are filtered down to just the genres the resident picked at
    /// Sign Up (their genre preference) — not all 9. Falls back to every genre
    /// only if they haven't picked any yet (e.g. mid-signup), so the library is
    /// never empty.
    var genreOrder: [Genre] {
        selectedGenres.isEmpty ? Genre.allCases : Genre.allCases.filter { selectedGenres.contains($0) }
    }

    /// Every song the CSV has for this resident's bracket, restricted to their
    /// selected genres and grouped by genre — personalized to BOTH genre
    /// preference and decade (age bracket), and never trimmed within a shown
    /// genre: a genre with 4 or 10 songs in the dataset shows all 4 or all 10.
    var librarySections: [(genre: Genre, songs: [Song])] {
        SongCatalog.sections(for: ageBracket, genreOrder: genreOrder)
    }

    var defaultSong: Song {
        librarySections.first?.songs.first ?? SongCatalog.fallbackSong(for: ageBracket)
    }

    var favoriteSong: Song {
        let sections = librarySections
        if let first = sections.first, first.songs.count > 1 {
            return first.songs[1]
        }
        if sections.count > 1, let secondGenreSong = sections[1].songs.first {
            return secondGenreSong
        }
        return SongCatalog.fallbackSong(for: ageBracket)
    }

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
