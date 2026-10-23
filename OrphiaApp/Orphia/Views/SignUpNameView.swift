import SwiftUI

/// Sign Up step 1 of 3. Replaces "username + passcode" text fields with
/// First Name + a PIN pad — easier to tap accurately than a QWERTY keyboard,
/// which matters since signup is self-service with no one present to help.
struct SignUpNameView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var pinEntry: String = ""

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

                Text("Create a PIN").font(.system(size: 16, weight: .semibold))
                PinDotsView(filledCount: pinEntry.count)
                PinPadView(pin: $pinEntry)

                Button("Continue") {
                    appState.firstName = name.isEmpty ? appState.firstName : name
                    appState.pin = pinEntry
                    path.append(.signUpBirthYear)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 10)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || pinEntry.count < 4)
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}
