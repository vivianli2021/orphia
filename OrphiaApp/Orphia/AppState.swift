import Foundation
import SwiftUI

/// Which list Song Playing's back/forward step through: the normal library, or
/// only favorites (when the song was picked from Play Favorites).
enum PlaylistContext {
    case library
    case favorites
}

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
/// to Supabase by `AuthManager`. Voice memos are saved on the phone and backed
/// up to Supabase by `MemorySync`; now-playing state lives in memory only.
final class AppState: ObservableObject {
    /// Supabase user id of the signed-in resident; set by AuthManager.
    var userId: UUID?

    // Profile captured during onboarding, or loaded from Supabase on sign-in.
    @Published var firstName: String = ""
    @Published var birthYear: String = ""
    @Published var selectedGenres: Set<Genre> = []

    // Now-playing state.
    @Published var currentSong: Song = SongCatalog.fallbackSong(for: .seventies)
    @Published var isPlaying: Bool = true // the player autoplays on load
    @Published var playlistContext: PlaylistContext = .library

    // Favorite/dislike are per-song and mutually exclusive — see toggleFavorite/
    // toggleDislike. favoriteSongIDs is ordered (most recently favorited first)
    // since it backs the Favorites screen; dislikedSongIDs is membership-only.
    @Published private(set) var favoriteSongIDs: [String] = []
    @Published private(set) var dislikedSongIDs: Set<String> = []

    // Saved voice-memo reflections, newest first. Loaded from Supabase on
    // sign-in (see loadMemories), plus any recorded here that haven't
    // finished uploading.
    @Published var memories: [Memory] = []

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
    /// Browse and Home from then on without needing to touch the CSV.
    var librarySections: [(genre: Genre, songs: [Song])] {
        SongCatalog.sections(for: ageBracket, genreOrder: genreOrder)
            .map { (genre: $0.genre, songs: $0.songs.filter { !dislikedSongIDs.contains($0.id) }) }
            .filter { !$0.songs.isEmpty }
    }

    /// What Song Playing's back/forward step through: Browse's songs in display
    /// order, or only favorites. Can be empty (e.g. no favorites left).
    var currentPlaylist: [Song] {
        switch playlistContext {
        case .library: return librarySections.flatMap { $0.songs }
        case .favorites: return favoriteSongs
        }
    }

    var defaultSong: Song {
        librarySections.first?.songs.first ?? SongCatalog.fallbackSong(for: ageBracket)
    }

    /// Every song the resident has favorited, most recently favorited first —
    /// the Play Favorites list and its back/forward playlist. Looked up across
    /// the whole catalog (not filtered to the current bracket/genre picks), so
    /// a favorite never silently disappears if genre preferences change later.
    /// Can be empty.
    var favoriteSongs: [Song] {
        favoriteSongIDs.compactMap { SongCatalog.song(id: $0) }
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
        memories = []
        userId = nil
    }

    func play(_ song: Song, context: PlaylistContext = .library) {
        currentSong = song
        isPlaying = true
        playlistContext = context
    }

    /// Saves a new recording: renames the file to match the memory's id, adds
    /// it to the list right away, then transcribes and uploads it in the background.
    func addMemory(for song: Song, recordingFileName: String, durationSeconds: Int) {
        let id = UUID()
        let fileName = MemorySync.localFileName(for: id)
        let documents = AudioRecorderManager.documentsDirectory()
        do {
            try FileManager.default.moveItem(
                at: documents.appendingPathComponent(recordingFileName),
                to: documents.appendingPathComponent(fileName)
            )
        } catch {
            return
        }

        let memory = Memory(id: id, song: song, createdAt: Date(), audioFileName: fileName, durationSeconds: durationSeconds)
        memories.insert(memory, at: 0)
        if let userId {
            PendingMemoryUploads.add(.init(
                id: id, userId: userId, songId: song.id,
                durationSeconds: durationSeconds, createdAt: memory.createdAt
            ))
        }
        transcribeMemory(id: id)
        uploadMemory(id: id)
    }

    /// Copies a memory up to Supabase. On failure it stays in the pending
    /// list and is retried by retryPendingUploads / the next sign-in.
    func uploadMemory(id: UUID) {
        guard let userId, let memory = memories.first(where: { $0.id == id }), !memory.isBackedUp else { return }
        Task { @MainActor in
            do {
                try await MemorySync.upload(memory, userId: userId)
                PendingMemoryUploads.remove(id: id)
                if let i = self.memories.firstIndex(where: { $0.id == id }) {
                    self.memories[i].isBackedUp = true
                }
            } catch {
                // Stays pending; retried later.
            }
        }
    }

    func retryPendingUploads() {
        for memory in memories where !memory.isBackedUp {
            uploadMemory(id: memory.id)
        }
    }

    /// Rebuilds the memory list from Supabase after sign-in, keeps any
    /// recordings that are still waiting to upload, and downloads audio
    /// that isn't on this phone yet (e.g. after a reinstall).
    @MainActor
    func loadMemories() async {
        guard let userId else { return }
        let rows: [MemorySync.Row]
        do {
            rows = try await MemorySync.fetchAll()
        } catch {
            rows = []
        }
        guard self.userId == userId else { return } // signed out meanwhile

        var loaded: [Memory] = rows.compactMap { row in
            guard let song = SongCatalog.song(id: row.songId) else { return nil }
            return Memory(
                id: row.id,
                song: song,
                createdAt: row.createdAt,
                audioFileName: MemorySync.localFileName(for: row.id),
                durationSeconds: row.durationSec,
                transcript: row.transcript.map { .done($0) } ?? .notStarted,
                isBackedUp: true
            )
        }
        let savedIDs = Set(rows.map(\.id))
        for entry in PendingMemoryUploads.entries(for: userId) {
            if savedIDs.contains(entry.id) {
                PendingMemoryUploads.remove(id: entry.id)
                continue
            }
            let fileName = MemorySync.localFileName(for: entry.id)
            guard let song = SongCatalog.song(id: entry.songId),
                  FileManager.default.fileExists(atPath: AudioRecorderManager.documentsDirectory().appendingPathComponent(fileName).path)
            else {
                PendingMemoryUploads.remove(id: entry.id)
                continue
            }
            loaded.append(Memory(
                id: entry.id, song: song, createdAt: entry.createdAt,
                audioFileName: fileName, durationSeconds: entry.durationSeconds
            ))
        }
        memories = loaded.sorted { $0.createdAt > $1.createdAt }
        retryPendingUploads()

        for row in rows {
            let fileName = MemorySync.localFileName(for: row.id)
            let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: url.path) {
                try? await MemorySync.download(row, to: fileName)
            }
        }
    }

    /// Writes out a memory's recording as text and stores it on the memory.
    /// Runs once per memory; pass `retry` to try again after a failure.
    func transcribeMemory(id: UUID, retry: Bool = false) {
        guard let index = memories.firstIndex(where: { $0.id == id }) else { return }
        let memory = memories[index]
        guard !memory.audioFileName.isEmpty else { return }
        switch memory.transcript {
        case .inProgress, .done: return
        case .failed where !retry: return
        default: break
        }

        memories[index].transcript = .inProgress
        let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(memory.audioFileName)
        Task { @MainActor in
            let result: TranscriptStatus
            do {
                result = .done(try await MemoryTranscriber.transcribe(fileURL: url))
            } catch {
                result = .failed(MemoryTranscriber.message(for: error))
            }
            if let i = self.memories.firstIndex(where: { $0.id == id }) {
                self.memories[i].transcript = result
            }
            // Back up the text too. If the upload hasn't happened yet, it
            // includes the transcript itself, so a failure here is harmless.
            if case .done(let text) = result, self.userId != nil {
                try? await MemorySync.saveTranscript(text, memoryId: id)
            }
        }
    }
}
