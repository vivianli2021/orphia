import Foundation
import Speech

/// Turns a saved voice memo into text with Apple's Speech framework. Uses
/// on-device recognition when the device supports it, since memories are
/// private; otherwise Apple's speech service processes the audio.
enum MemoryTranscriber {
    enum TranscriptionError: Error {
        case notAuthorized
        case unavailable
    }

    static func transcribe(fileURL: URL) async throws -> String {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { throw TranscriptionError.notAuthorized }
        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw TranscriptionError.unavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            recognizer.recognitionTask(with: request) { result, error in
                guard !finished else { return }
                if let result, result.isFinal {
                    finished = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if let error {
                    finished = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// A plain-language explanation for the transcript screen.
    static func message(for error: Error) -> String {
        switch error {
        case TranscriptionError.notAuthorized:
            return "Orphia needs permission to turn speech into text. You can allow it in the Settings app under Orphia."
        case TranscriptionError.unavailable:
            return "Writing out memories isn't available right now. Please try again later."
        default:
            return "We couldn't make out any words in this recording."
        }
    }
}
