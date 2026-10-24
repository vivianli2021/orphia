import Foundation
import GoogleSignIn
import Supabase
import UIKit

/// Owns sign-in state. Google's native sign-in sheet hands back an ID token,
/// which is exchanged for a Supabase session (`signInWithIdToken`) — no browser
/// redirect. Supabase keeps the session in the Keychain, so residents stay
/// signed in between launches.
@MainActor
final class AuthManager: ObservableObject {
    enum Status {
        case loading          // checking for a saved session at launch
        case signedOut
        case needsOnboarding  // signed in, but birth year / genres not saved yet
        case signedIn
    }

    @Published private(set) var status: Status = .loading
    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    private var userId: UUID?

    /// Called once at launch: picks up a saved session if there is one.
    func restoreSession(into appState: AppState) async {
        do {
            let session = try await supabase.auth.session
            try await finishSignIn(userId: session.user.id, googleName: nil, appState: appState)
        } catch {
            status = .signedOut
        }
    }

    func signInWithGoogle(into appState: AppState) async {
        guard let presenter = Self.topViewController() else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google didn't return a sign-in token. Please try again."
                return
            }
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
            )
            try await finishSignIn(
                userId: session.user.id,
                googleName: result.user.profile?.givenName,
                appState: appState
            )
        } catch let error as GIDSignInError where error.code == .canceled {
            // Resident closed the Google sheet — not an error worth showing.
        } catch {
            errorMessage = "Sign in didn't work. Please check your internet connection and try again."
        }
    }

    /// Saves name, birth year, and genres at the end of onboarding.
    func saveProfile(from appState: AppState) async {
        guard let userId else { return }
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        let profile = Profile(
            id: userId,
            firstName: appState.firstName,
            birthYear: Int(appState.birthYear),
            genres: appState.genreOrder.map(\.rawValue)
        )
        do {
            try await supabase.from("profiles").upsert(profile).execute()
            status = .signedIn
        } catch {
            errorMessage = "Couldn't save your choices. Please check your internet connection and try again."
        }
    }

    func signOut(appState: AppState) async {
        GIDSignIn.sharedInstance.signOut()
        try? await supabase.auth.signOut()
        userId = nil
        appState.reset()
        status = .signedOut
    }

    private func finishSignIn(userId: UUID, googleName: String?, appState: AppState) async throws {
        self.userId = userId
        let rows: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .execute()
            .value

        if let profile = rows.first {
            appState.apply(profile)
        }
        if appState.firstName.isEmpty, let googleName {
            appState.firstName = googleName
        }
        status = rows.first?.isComplete == true ? .signedIn : .needsOnboarding
    }

    /// The view controller Google's sign-in sheet presents from.
    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
