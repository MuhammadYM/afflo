import Foundation
import Supabase
import AuthenticationServices
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for auth state changes
        Task {
            for await state in supabase.auth.authStateChanges {
                switch state.event {
                case .signedIn:
                    self.session = state.session
                case .signedOut:
                    self.session = nil
                default:
                    break
                }
            }
        }

        // Check for existing session
        Task {
            do {
                let session = try await supabase.auth.session
                self.session = session
            } catch {
                // No existing session
                self.session = nil
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            self.session = session
        } catch {
            errorMessage = "Failed to sign in: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signOut()
            self.session = nil
            UserDefaultsManager.shared.resetOnboarding()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
