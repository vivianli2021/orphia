import SwiftUI

/// Sign Up step 2 of 3. Only birth year is collected (not full DOB) — enough to
/// infer "songs from their youth" without extra typing. The field starts EMPTY
/// (explicit product decision — do not pre-fill a default year).
struct SignUpBirthYearView: View {
    @Binding var path: [Route]
    @EnvironmentObject var appState: AppState
    @State private var year: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Step 2 of 3")
                    .foregroundColor(AppColors.muted)
                Text("What year were you born?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.ink)

                Text("Birth Year").font(.system(size: 16, weight: .semibold))
                TextField("e.g. 1948", text: $year)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primaryDark)
                    .padding(20)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 2))
                    .cornerRadius(12)

                Button("Continue") {
                    appState.birthYear = year
                    path.append(.signUpGenres)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(year.count != 4)

                Button("Back") { path.removeLast() }
                    .buttonStyle(GhostButtonStyle())
            }
            .padding(20)
        }
        .background(AppColors.bg)
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}
