import AuthenticationServices
import Combine
import Foundation
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Check if USE_LOCAL mode is enabled for mock auth
        if readConfigFlag("USE_LOCAL") {
            setupMockAuth()
            return
        }

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

    // MARK: - Mock Auth for Local Development

    private func readConfigFlag(_ key: String) -> Bool {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = config[key] as? Bool else {
            return false
        }
        return value
    }

    private func setupMockAuth() {
        let mockUserId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        // Create mock user
        let mockUser = User(
            id: mockUserId,
            appMetadata: [:],
            userMetadata: ["email": "dev@afflo.local", "name": "Dev User"],
            aud: "authenticated",
            createdAt: Date(),
            updatedAt: Date()
        )

        // Create mock session
        let mockSession = Session(
            accessToken: "mock-access-token",
            tokenType: "bearer",
            expiresIn: 3600,
            expiresAt: Date().addingTimeInterval(3600).timeIntervalSince1970,
            refreshToken: "mock-refresh-token",
            user: mockUser
        )

        self.session = mockSession

        print("🧪 MOCK AUTH ACTIVE: Using dev@afflo.local (00000000-0000-0000-0000-000000000000)")
    }
}
