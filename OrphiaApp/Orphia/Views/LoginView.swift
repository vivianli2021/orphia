import SwiftUI

/// Mirrors the Sign Up credential pattern for consistency — same PIN pad,
/// same mental model, nothing new to learn.
struct LoginView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var pinEntry: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Welcome back")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)

                Text("Your First Name").font(.system(size: 16, weight: .semibold))
                TextField("Type here", text: $name)
                    .padding(16)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 2))
                    .cornerRadius(12)
                    .font(.system(size: 19))

                Text("Enter your PIN").font(.system(size: 16, weight: .semibold))
                PinDotsView(filledCount: pinEntry.count)
                PinPadView(pin: $pinEntry)

                Button("Log In") {
                    if !name.isEmpty { appState.firstName = name }
                    path.append(.home)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = appState.firstName }
    }
}
