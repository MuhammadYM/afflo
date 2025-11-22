import Combine
import Foundation
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client

    func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let userId = try await getUserId()

            let response: UserProfile = try await supabase
                .from("user_profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            userProfile = response
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("Error fetching user profile:", error)
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    private func getUserId() async throws -> String {
        // Check if using mock auth
        if readConfigFlag("USE_LOCAL") {
            print("🧪 ProfileViewModel: Using mock user ID")
            return "00000000-0000-0000-0000-000000000000"
        }

        // Normal auth flow
        do {
            let session = try await supabase.auth.session
            guard let userId = session.user.id.uuidString as String? else {
                throw NSError(domain: "No authenticated user", code: 401)
            }
            return userId
        } catch {
            throw NSError(domain: "Auth session missing", code: 401)
        }
    }

    private func readConfigFlag(_ key: String) -> Bool {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = config[key] as? Bool else {
            return false
        }
        return value
    }
}
