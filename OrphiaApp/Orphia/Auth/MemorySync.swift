import Foundation
import Supabase

/// Backs up voice memos to Supabase: the audio goes to the private `memos`
/// bucket at `<user id>/<memory id>.m4a`, and a row describing it goes in the
/// `memories` table (see docs/supabase-google-auth-setup.md, Part 6).
/// Recordings are always saved on the phone first; this only copies them up.
enum MemorySync {
    /// One row of the `memories` table.
    struct Row: Codable {
        let id: UUID
        let userId: UUID
        let songId: String
        let audioPath: String
        let durationSec: Int?
        let transcript: String?
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case songId = "song_id"
            case audioPath = "audio_path"
            case durationSec = "duration_sec"
            case transcript
            case createdAt = "created_at"
        }
    }

    private static let bucket = "memos"

    /// Storage policies compare the folder name to `auth.uid()::text`, which
    /// Postgres writes in lowercase — Swift's `uuidString` is uppercase.
    static func storagePath(userId: UUID, memoryId: UUID) -> String {
        "\(userId.uuidString.lowercased())/\(memoryId.uuidString.lowercased()).m4a"
    }

    /// Local file name in Documents for a memory's recording.
    static func localFileName(for memoryId: UUID) -> String {
        "memory-\(memoryId.uuidString).m4a"
    }

    static func localURL(for memory: Memory) -> URL {
        AudioRecorderManager.documentsDirectory().appendingPathComponent(memory.audioFileName)
    }

    static func upload(_ memory: Memory, userId: UUID) async throws {
        let data = try Data(contentsOf: localURL(for: memory))
        let path = storagePath(userId: userId, memoryId: memory.id)
        try await supabase.storage
            .from(bucket)
            .upload(path, data: data, options: FileOptions(contentType: "audio/mp4", upsert: true))

        var transcript: String?
        if case .done(let text) = memory.transcript { transcript = text }
        let row = Row(
            id: memory.id,
            userId: userId,
            songId: memory.song.id,
            audioPath: path,
            durationSec: memory.durationSeconds,
            transcript: transcript,
            createdAt: memory.createdAt
        )
        try await supabase.from("memories").upsert(row).execute()
    }

    /// All of the signed-in resident's memories, newest first. RLS limits
    /// the result to their own rows.
    static func fetchAll() async throws -> [Row] {
        try await supabase
            .from("memories")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Downloads a recording saved from another device (or before a reinstall).
    static func download(_ row: Row, to fileName: String) async throws {
        let data = try await supabase.storage.from(bucket).download(path: row.audioPath)
        let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
    }

    static func saveTranscript(_ text: String, memoryId: UUID) async throws {
        try await supabase
            .from("memories")
            .update(["transcript": text])
            .eq("id", value: memoryId.uuidString)
            .execute()
    }
}

/// Memories recorded on this phone that haven't finished uploading yet.
/// Kept in a small JSON file so a memory recorded with no Wi-Fi still backs
/// up later, even if the app is closed in between.
enum PendingMemoryUploads {
    struct Entry: Codable {
        let id: UUID
        let userId: UUID
        let songId: String
        let durationSeconds: Int?
        let createdAt: Date
    }

    private static var fileURL: URL {
        AudioRecorderManager.documentsDirectory().appendingPathComponent("pending-memory-uploads.json")
    }

    static func entries(for userId: UUID) -> [Entry] {
        load().filter { $0.userId == userId }
    }

    static func add(_ entry: Entry) {
        save(load().filter { $0.id != entry.id } + [entry])
    }

    static func remove(id: UUID) {
        save(load().filter { $0.id != id })
    }

    private static func load() -> [Entry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    private static func save(_ entries: [Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
