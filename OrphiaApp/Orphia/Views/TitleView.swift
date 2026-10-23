import SwiftUI

/// Entry point. Only two choices, nothing else competing for attention —
/// large wordmark, high contrast, no decorative clutter.
struct TitleView: View {
    @Binding var path: [Route]

    var body: some View {
        VStack {
            Spacer()
            CarnationLogo(size: 90, withStem: true)
                .padding(.bottom, 8)
            Text("Orphia")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppColors.primaryDark)
            Text("Music from your memories")
                .font(.system(size: 16))
                .foregroundColor(AppColors.muted)
                .padding(.bottom, 40)
            Spacer()
            Button("Log In") { path.append(.login) }
                .buttonStyle(PrimaryButtonStyle())
            Button("Sign Up") { path.append(.signUpName) }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bg)
        .navigationBarHidden(true)
    }
}
