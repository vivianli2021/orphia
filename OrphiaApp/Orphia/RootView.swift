import SwiftUI

/// Root navigation host. Uses a NavigationStack + array-based path, mirroring the
/// HTML prototype's single `order` array of screens, but as real native navigation
/// (title screen is the stack root; everything else pushes/pops).
/// Sign-in state decides where the stack starts: signed out → Title, signed in
/// but new → onboarding, signed in with a saved profile → Home.
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var auth: AuthManager
    @State private var path: [Route] = []

    var body: some View {
        Group {
            if auth.status == .loading {
                LaunchView()
            } else {
                NavigationStack(path: $path) {
                    TitleView()
                        .navigationDestination(for: Route.self) { route in
                            destination(for: route)
                        }
                }
            }
        }
        .tint(AppColors.primary)
        .task { await auth.restoreSession(into: appState) }
        .onChange(of: auth.status) { status in
            switch status {
            case .loading, .signedOut: path = []
            case .needsOnboarding: path = [.signUpName]
            case .signedIn: path = [.home]
            }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .signUpName: SignUpNameView(path: $path)
        case .signUpBirthYear: SignUpBirthYearView(path: $path)
        case .signUpGenres: SignUpGenresView(path: $path)
        case .home: HomeView(path: $path)
        case .browse: BrowseView(path: $path)
        case .playing: SongPlayingView(path: $path)
        case .memoryCapture: MemoryCaptureView(path: $path)
        case .myMemories: MyMemoriesView(path: $path)
        case .favorites: FavoritesView(path: $path)
        }
    }
}

/// Shown for a moment at launch while a saved session is checked.
private struct LaunchView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("OrphiaLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 220)
                .accessibilityHidden(true)
            ProgressView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bg)
    }
}
