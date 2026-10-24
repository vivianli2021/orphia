import GoogleSignIn
import SwiftUI

@main
struct OrphiaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(auth)
                .onOpenURL { url in
                    // Google's sign-in sheet returns to the app via its URL scheme.
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
