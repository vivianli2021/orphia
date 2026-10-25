import Foundation
import SwiftUI

enum Route: Hashable {
    case signUpName
    case signUpBirthYear
    case signUpGenres
    case home
    case browse
    case playing
    case memoryCapture
    case myMemories
    case favorites
}

/// Central app state shared across views via @EnvironmentObject.
/// The resident's profile (name, birth year, genres) is loaded from and saved
/// to Supabase by `AuthManager`; memories and now-playing state still live in
/// memory for now.
final class AppState: ObservableObject {
    // Profile captured during onboarding, or loaded from Supabase on sign-in.
    @Published var firstName: String = ""
    @Published var birthYear: String = ""
    @Published var selectedGenres: Set<Genre> = []

    // Now-playing state.
    @Published var currentSong: Song = SongCatalog.fallbackSong(for: .seventies)
    @Published var isPlaying: Bool = true // the player autoplays on load

    // Favorite/dislike are per-song and mutually exclusive — see toggleFavorite/
    // toggleDislike. favoriteSongIDs is ordered (most recently favorited first)
    // since it backs the Favorites screen; dislikedSongIDs is membership-only.
    @Published private(set) var favoriteSongIDs: [String] = []
    @Published private(set) var dislikedSongIDs: Set<String> = []

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
    /// Disliked songs are filtered out here, so a dislike removes a song from
    /// this playlist and every future one built from it (Browse, Home, the
    /// Song Playing screen's forward/back) without needing to touch the CSV.
    var librarySections: [(genre: Genre, songs: [Song])] {
        SongCatalog.sections(for: ageBracket, genreOrder: genreOrder)
            .map { (genre: $0.genre, songs: $0.songs.filter { !dislikedSongIDs.contains($0.id) }) }
            .filter { !$0.songs.isEmpty }
    }

    /// The resident's current playlist as one ordered list (Browse's genre
    /// sections flattened in display order) — what Song Playing's forward/back
    /// buttons step through.
    var currentPlaylist: [Song] {
        librarySections.flatMap { $0.songs }
    }

    var defaultSong: Song {
        librarySections.first?.songs.first ?? SongCatalog.fallbackSong(for: ageBracket)
    }

    /// Every song the resident has favorited, most recently favorited first —
    /// backs the Favorites screen. Looked up across the whole catalog (not
    /// filtered to the current bracket/genre picks), so a favorite never
    /// silently disappears if genre preferences change later.
    var favoriteSongs: [Song] {
        favoriteSongIDs.compactMap { SongCatalog.song(id: $0) }
    }

    /// Used by Home's "Play Favorites" quick action: the most recent real
    /// favorite if the resident has one, otherwise a sensible fallback pick
    /// from their personalized library so the button is never a dead end.
    var favoriteSong: Song {
        if let mostRecentFavorite = favoriteSongs.first {
            return mostRecentFavorite
        }
        let sections = librarySections
        if let first = sections.first, first.songs.count > 1 {
            return first.songs[1]
        }
        if sections.count > 1, let secondGenreSong = sections[1].songs.first {
            return secondGenreSong
        }
        return SongCatalog.fallbackSong(for: ageBracket)
    }

    func isFavorite(_ song: Song) -> Bool { favoriteSongIDs.contains(song.id) }
    func isDisliked(_ song: Song) -> Bool { dislikedSongIDs.contains(song.id) }

    /// Favorite and dislike are mutually exclusive — favoriting a disliked
    /// song un-dislikes it (and puts it back in future playlists), and vice versa.
    func toggleFavorite(_ song: Song) {
        if let index = favoriteSongIDs.firstIndex(of: song.id) {
            favoriteSongIDs.remove(at: index)
        } else {
            favoriteSongIDs.insert(song.id, at: 0)
            dislikedSongIDs.remove(song.id)
        }
    }

    func toggleDislike(_ song: Song) {
        if dislikedSongIDs.contains(song.id) {
            dislikedSongIDs.remove(song.id)
        } else {
            dislikedSongIDs.insert(song.id)
            favoriteSongIDs.removeAll { $0 == song.id }
        }
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

    func apply(_ profile: Profile) {
        firstName = profile.firstName ?? ""
        birthYear = profile.birthYear.map(String.init) ?? ""
        selectedGenres = Set(profile.genres.compactMap(Genre.init(rawValue:)))
    }

    /// Clears the signed-in resident's profile on sign out — favorites/dislikes
    /// too, so they don't leak into a different resident's session on this device.
    func reset() {
        firstName = ""
        birthYear = ""
        selectedGenres = []
        favoriteSongIDs = []
        dislikedSongIDs = []
    }

    func play(_ song: Song) {
        currentSong = song
        isPlaying = true
    }

    func addMemory(for song: Song, audioFileName: String) {
        let memory = Memory(id: UUID(), song: song, dateLabel: "Today", audioFileName: audioFileName)
        memories.insert(memory, at: 0)
    }
}
