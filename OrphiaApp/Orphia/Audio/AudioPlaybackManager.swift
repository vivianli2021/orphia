import Foundation
import AVFoundation

/// Plays back a saved voice-memo recording from the Documents directory.
/// Used by My Memories — one memory plays at a time, matching the HTML
/// prototype's toggleMemoryPlay() behavior (starting a new one stops any other).
final class AudioPlaybackManager: NSObject, ObservableObject {
    @Published var currentlyPlayingID: UUID?

    private var player: AVAudioPlayer?

    func toggle(memory: Memory) {
        if currentlyPlayingID == memory.id {
            stop()
            return
        }
        stop()
        guard !memory.audioFileName.isEmpty else {
            // demo-seeded memories have no real audio file; just reflect "playing" state briefly in UI
            currentlyPlayingID = memory.id
            return
        }
        let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(memory.audioFileName)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            currentlyPlayingID = memory.id
        } catch {
            currentlyPlayingID = nil
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentlyPlayingID = nil
    }
}

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentlyPlayingID = nil
    }
}
