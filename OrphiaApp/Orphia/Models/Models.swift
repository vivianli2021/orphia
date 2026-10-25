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
    let audioFileName: String // file in the app's Documents directory; empty for demo-seeded memories
    var transcript: TranscriptStatus = .notStarted
}

enum TranscriptStatus: Hashable {
    case notStarted
    case inProgress
    case done(String)
    case failed(String)
}

// The song library itself now lives in SongCatalog.swift (query layer) and the
// generated SongCatalogData.swift (full dataset) — every song the CSV has for
// a resident's age bracket, not a hand-picked subset. See AgeBracket.swift for
// how a resident's bracket is computed from their birth year.
