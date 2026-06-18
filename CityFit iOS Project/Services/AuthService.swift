import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import Combine

final class AuthService: ObservableObject {
    @Published var firebaseUser: FirebaseAuth.User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    static let shared = AuthService()

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.firebaseUser = user
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    var isSignedIn: Bool { firebaseUser != nil }
    var uid: String? { firebaseUser?.uid }
    var displayName: String? { firebaseUser?.displayName }
    var email: String? { firebaseUser?.email }

    // MARK: - Google Sign-In

    @MainActor
    func signInWithGoogle(presentingViewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign-In failed: missing token."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
