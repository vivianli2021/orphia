import SwiftUI

/// Root navigation host. Uses a NavigationStack + array-based path, mirroring the
/// HTML prototype's single `order` array of screens, but as real native navigation
/// (title screen is the stack root; everything else pushes/pops).
struct RootView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            TitleView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .tint(AppColors.primary)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .signUpName: SignUpNameView(path: $path)
        case .signUpBirthYear: SignUpBirthYearView(path: $path)
        case .signUpGenres: SignUpGenresView(path: $path)
        case .login: LoginView(path: $path)
        case .home: HomeView(path: $path)
        case .browse: BrowseView(path: $path)
        case .playing: SongPlayingView(path: $path)
        case .memoryCapture: MemoryCaptureView(path: $path)
        case .myMemories: MyMemoriesView(path: $path)
        }
    }
}
