import SwiftUI

/// Entry point. One choice, nothing else competing for attention —
/// large wordmark, high contrast, no decorative clutter. New and returning
/// residents use the same button; RootView routes new ones into onboarding.
struct TitleView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        VStack {
            Spacer()
            Image("OrphiaLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .accessibilityHidden(true)
                .padding(.bottom, 12)
            Text("Orphia")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.primaryDark)
            Text("Music from your memories")
                .font(.system(size: 16))
                .foregroundColor(AppColors.muted)
                .padding(.bottom, 40)
            Spacer()

            if let message = auth.errorMessage {
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.rust)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }

            Button {
                Task { await auth.signInWithGoogle(into: appState) }
            } label: {
                if auth.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text("Continue with Google")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(auth.isWorking)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bg)
        .navigationBarHidden(true)
    }
}
