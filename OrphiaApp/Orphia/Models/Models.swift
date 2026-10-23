import Foundation

/// The fixed list of genres a resident can pick from during Sign Up.
/// This exact list (and order) was explicitly specified — don't add/remove/reorder
/// without checking with the product owner first.
enum Genre: String, CaseIterable, Identifiable {
    case classical = "Classical"
    case jazzBlues = "Jazz & Blues"
    case oldiesRock = "Oldies & Rock 'n' Roll"
    case pop = "Pop"
    case countryFolk = "Country & Folk"
    case gospelHymns = "Gospel & Hymns"
    case broadway = "Broadway & Musical Theater"
    case bigBandSwing = "Big Band & Swing"
    case rbSoul = "R&B & Soul"

    var id: String { rawValue }
}

/// A single playable song. YouTube videos are played via the official iframe/player
/// embed (WKWebView-hosted) — audio is never downloaded or re-hosted by the app.
struct Song: Identifiable, Hashable {
    let id: String // YouTube video ID, also used as a stable identifier
    let title: String
    let artist: String
    let genre: Genre
    let yearLabel: String // display string, e.g. "1965" or "c. 1890"

    var genreLine: String { "\(genre.rawValue) · \(yearLabel)" }
    var thumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(id)/mqdefault.jpg")
    }
    var embedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(id)?autoplay=1&rel=0&playsinline=1")
    }
}

/// A saved voice-memo reflection, tied to the song that was playing when it was recorded.
struct Memory: Identifiable, Hashable {
    let id: UUID
    let song: Song
    let dateLabel: String
    let audioFileName: String // file in the app's Documents directory
}

/// Curated 18-song library (2 songs per genre), drawn from the "70s" age-bracket
/// (formative era ~1961–1976) rows of design/song-library-by-age-decade.csv —
/// the same subset used in the HTML wireframe prototype for the Dorothy persona.
/// Kept intentionally small per the MVP "small curated library" philosophy.
struct SongLibrary {
    static let songs: [Song] = [
        Song(id: "2xSpGxAMGKs", title: "Moonlight Sonata", artist: "Ludwig van Beethoven", genre: .classical, yearLabel: "1801"),
        Song(id: "c977QdbTImU", title: "Clair de Lune", artist: "Claude Debussy", genre: .classical, yearLabel: "c. 1890"),

        Song(id: "-DHuW1h1wHw", title: "Take Five", artist: "Dave Brubeck Quartet", genre: .jazzBlues, yearLabel: "1959"),
        Song(id: "76gsMX5Pqc4", title: "Georgia on My Mind", artist: "Ray Charles", genre: .jazzBlues, yearLabel: "1960"),

        Song(id: "O-aavAlSYgc", title: "Can't Help Falling in Love", artist: "Elvis Presley", genre: .oldiesRock, yearLabel: "1961"),
        Song(id: "blt-Jtk25iQ", title: "I Want to Hold Your Hand", artist: "The Beatles", genre: .oldiesRock, yearLabel: "1963"),

        Song(id: "Y5D1_aJB4Dw", title: "Sweet Caroline", artist: "Neil Diamond", genre: .pop, yearLabel: "1969"),
        Song(id: "h0n-mYqB9WQ", title: "Bridge over Troubled Water", artist: "Simon & Garfunkel", genre: .pop, yearLabel: "1970"),

        Song(id: "M3yWXXGncBU", title: "Crazy", artist: "Patsy Cline", genre: .countryFolk, yearLabel: "1961"),
        Song(id: "H48SgS098pM", title: "Ring of Fire", artist: "Johnny Cash", genre: .countryFolk, yearLabel: "1963"),

        Song(id: "E3McBWuZiuE", title: "Amazing Grace", artist: "Judy Collins", genre: .gospelHymns, yearLabel: "1970"),
        Song(id: "RS8hduL63cQ", title: "Oh Happy Day", artist: "The Edwin Hawkins Singers", genre: .gospelHymns, yearLabel: "1968"),

        Song(id: "n6z7UnUmXug", title: "Somewhere", artist: "West Side Story", genre: .broadway, yearLabel: "1961"),
        Song(id: "HBELgNLzLYw", title: "Hello, Dolly!", artist: "Jerry Herman", genre: .broadway, yearLabel: "1964"),

        Song(id: "aME0qvhZ37o", title: "In the Mood", artist: "Glenn Miller Orchestra", genre: .bigBandSwing, yearLabel: "1939"),
        Song(id: "9Ws6DdrDtyo", title: "Moonlight Serenade", artist: "Glenn Miller Orchestra", genre: .bigBandSwing, yearLabel: "1939"),

        Song(id: "y3KJ7d2qBoA", title: "My Girl", artist: "The Temptations", genre: .rbSoul, yearLabel: "1965"),
        Song(id: "A134hShx_gw", title: "Respect", artist: "Aretha Franklin", genre: .rbSoul, yearLabel: "1967"),
    ]

    static func song(id: String) -> Song? {
        songs.first { $0.id == id }
    }

    static var defaultSong: Song { song(id: "y3KJ7d2qBoA")! } // My Girl
    static var favoriteSong: Song { song(id: "A134hShx_gw")! } // Respect

    static var byGenre: [(genre: Genre, songs: [Song])] {
        Genre.allCases.map { g in (genre: g, songs: songs.filter { $0.genre == g }) }
    }
}
