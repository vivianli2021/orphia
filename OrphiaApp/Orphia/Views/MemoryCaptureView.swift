import SwiftUI

/// Did not exist in the original sketches — this is the "reflect on memories
/// connected to the music" screen from the pitch. Voice-first, not text (typing
/// is the main friction point everywhere else). Explicitly private for MVP —
/// no sharing/permissions UI, but the (memory ↔ song) data shape leaves room to
/// add sharing later without a rebuild.
struct MemoryCaptureView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @StateObject private var recorderManager = AudioRecorderManager()

    var body: some View {
        VStack(spacing: 16) {
            Text("Does this song remind you of anything?")
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.ink)
            Text("Tap the button and tell us. Just you — no one else will hear this unless you choose to share it later.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.muted)

            Button {
                if recorderManager.isRecording {
                    recorderManager.stopRecording()
                } else {
                    recorderManager.requestPermissionAndStart()
                }
            } label: {
                Image(systemName: recorderManager.isRecording ? "stop.fill" : "circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 110, height: 110)
                    .background(recorderManager.isRecording ? Color(hex: "#6B1E22") : AppColors.rust)
                    .clipShape(Circle())
            }
            .padding(.vertical, 20)

            Text(timerLabel)
                .font(.system(size: 20))
                .foregroundColor(AppColors.muted)

            Button("Save Memory") {
                if let fileName = recorderManager.lastRecordingFileName {
                    appState.addMemory(
                        for: appState.currentSong,
                        recordingFileName: fileName,
                        durationSeconds: recorderManager.elapsedSeconds
                    )
                }
                path.removeLast()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(recorderManager.lastRecordingFileName == nil || recorderManager.isRecording)

            Button("Discard") {
                recorderManager.discardRecording()
                path.removeLast()
            }
            .buttonStyle(GhostButtonStyle())

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.bg)
        .navigationTitle("Share a Memory")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timerLabel: String {
        if recorderManager.isRecording {
            let m = recorderManager.elapsedSeconds / 60
            let s = recorderManager.elapsedSeconds % 60
            return String(format: "%d:%02d", m, s)
        } else if recorderManager.lastRecordingFileName != nil {
            return "Recorded — tap Save to keep it"
        } else {
            return "Tap to record"
        }
    }
}
