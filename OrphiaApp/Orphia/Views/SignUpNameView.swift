import SwiftUI

/// Sign Up step 1 of 3, shown right after a new resident's first Google
/// sign-in. The name is pre-filled from their Google account so most people
/// just tap Continue — no typing needed unless they want to change it.
struct SignUpNameView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthManager
    @State private var name: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step 1 of 3")
                    .foregroundColor(AppColors.muted)
                Text("What's your name?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)

                Text("Your First Name").font(.system(size: 16, weight: .semibold))
                TextField("Type here", text: $name)
                    .padding(16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 2))
                    .cornerRadius(12)
                    .font(.system(size: 19))

                Button("Continue") {
                    appState.firstName = name.trimmingCharacters(in: .whitespaces)
                    path.append(.signUpBirthYear)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                // This is the first onboarding screen, so there's no Back —
                // signing out is the way to switch to a different Google account.
                Button("Not you? Sign out") {
                    Task { await auth.signOut(appState: appState) }
                }
                .buttonStyle(GhostButtonStyle())
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear { name = appState.firstName }
    }
}
