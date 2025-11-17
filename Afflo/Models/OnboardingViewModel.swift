import Combine
import Foundation
import Supabase

struct OnboardingQuestion {
    let id: String
    let question: String
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var stepIndex = 0
    @Published var answers: [String: String] = [:]
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared.client

    let questions: [OnboardingQuestion] = [
        OnboardingQuestion(id: "manifest_goal", question: "What do you want to manifest right now?"),
        OnboardingQuestion(id: "why", question: "Why does this matter to you?"),
        OnboardingQuestion(id: "obstacle", question: "What's one thing holding you back?")
    ]

    var currentQuestion: OnboardingQuestion {
        questions[stepIndex]
    }

    var currentAnswer: String {
        answers[currentQuestion.id] ?? ""
    }

    var isLastStep: Bool {
        stepIndex >= questions.count - 1
    }

    var canProceed: Bool {
        !currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateAnswer(_ text: String) {
        answers[currentQuestion.id] = text
    }

    func handleNext(onComplete: @escaping () -> Void) async {
        guard canProceed else { return }

        if isLastStep {
            await saveAnswersToSupabase(onComplete: onComplete)
        } else {
            stepIndex = min(stepIndex + 1, questions.count - 1)
        }
    }

    func handleBack() {
        stepIndex = max(stepIndex - 1, 0)
    }

    private func saveAnswersToSupabase(onComplete: @escaping () -> Void) async {
        isSubmitting = true
        errorMessage = nil

        do {
            let userId = try await getUserId()

            let profileData = UserProfileUpsert(
                id: userId,
                manifestGoal: answers["manifest_goal"] ?? "",
                why: answers["why"] ?? "",
                obstacle: answers["obstacle"] ?? ""
            )

            try await supabase
                .from("user_profiles")
                .upsert(profileData)
                .execute()

            UserDefaultsManager.shared.hasCompletedOnboarding = true
            onComplete()
        } catch {
            errorMessage = "Failed to save answers: \(error.localizedDescription)"
            // TODO: Show error to user
            print("Error saving onboarding answers:", error)
        }

        isSubmitting = false
    }

    // MARK: - Helper Methods

    private func getUserId() async throws -> String {
        // Check if using mock auth
        if readConfigFlag("USE_LOCAL") {
            print("🧪 OnboardingViewModel: Using mock user ID")
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
