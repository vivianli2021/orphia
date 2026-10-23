import Foundation
import AVFoundation

/// Records short voice-memo reflections to the app's Documents directory.
/// MVP scope: recordings are private to the resident only — no sharing/upload here.
final class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsedSeconds = 0
    @Published var lastRecordingFileName: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func requestPermissionAndStart() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard granted else { return }
                self?.startRecording()
            }
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            return
        }

        let fileName = "memory-\(UUID().uuidString).m4a"
        let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
            elapsedSeconds = 0
            lastRecordingFileName = fileName
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.elapsedSeconds += 1
            }
        } catch {
            isRecording = false
        }
    }

    func stopRecording() {
        recorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func discardRecording() {
        if let name = lastRecordingFileName {
            let url = AudioRecorderManager.documentsDirectory().appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
        lastRecordingFileName = nil
        elapsedSeconds = 0
    }

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
