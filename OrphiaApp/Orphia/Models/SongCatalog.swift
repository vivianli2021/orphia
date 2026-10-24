import Foundation

/// Query layer over the generated `allCatalogRows` (see SongCatalogData.swift).
/// Every lookup here returns ALL songs the CSV has for a given bracket+genre —
/// never a hand-picked subset — so Browse/Home always show a resident's full,
/// personalized catalog for their age bracket, not a sample of it.
enum SongCatalog {
    /// All (genre, songs) sections for a bracket, in a fixed genre order, with
    /// every song the CSV has for that bracket+genre (10 for Classical, 4 for
    /// every other genre — see generate_song_dataset.py's printed counts).
    /// `genreOrder` lets callers put the resident's selected genres first
    /// without hiding the rest.
    static func sections(for bracket: AgeBracket, genreOrder: [Genre] = Genre.allCases) -> [(genre: Genre, songs: [Song])] {
        let rowsForBracket = allCatalogRows.filter { $0.bracket == bracket }
        return genreOrder.compactMap { genre in
            let songs = rowsForBracket.filter { $0.song.genre == genre }.map { $0.song }
            return songs.isEmpty ? nil : (genre: genre, songs: songs)
        }
    }

    /// Looks up a song by YouTube ID across the whole catalog (any bracket) —
    /// used for demo-seeded data where the bracket isn't relevant, since the
    /// same song (same id/title/artist/genre/year) repeats across brackets.
    static func song(id: String) -> Song? {
        allCatalogRows.first { $0.song.id == id }?.song
    }

    /// Classical is the one genre guaranteed non-empty in every bracket (10
    /// songs each) — safe fallback if a bracket/genre combination is ever empty.
    static func fallbackSong(for bracket: AgeBracket) -> Song {
        sections(for: bracket).first?.songs.first
            ?? Song(id: "c977QdbTImU", title: "Clair de Lune", artist: "Claude Debussy", genre: .classical, yearLabel: "c. 1890")
    }
}
