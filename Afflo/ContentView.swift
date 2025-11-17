import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var hasCompletedOnboarding = UserDefaultsManager.shared.hasCompletedOnboarding

    var body: some View {
        Group {
            if authViewModel.session == nil {
                // No session -> show auth
                AuthView()
            } else if !hasCompletedOnboarding {
                // Session exists but no onboarding -> show onboarding
                OnboardingView(onComplete: {
                    hasCompletedOnboarding = true
                })
            } else {
//                 Session exists and onboarding complete -> show main tabs
                MainTabView()
            }
        }
        .onAppear {
            // Refresh onboarding status on appear
            hasCompletedOnboarding = UserDefaultsManager.shared.hasCompletedOnboarding
        }
        .onChange(of: authViewModel.session) { _, _ in
            // Refresh onboarding status when session changes
            hasCompletedOnboarding = UserDefaultsManager.shared.hasCompletedOnboarding
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh session when app enters foreground
            Task {
                await refreshSession()
            }
        }
    }

    private func refreshSession() async {
        // Session is automatically refreshed by AuthViewModel's init listener
        // Just refresh onboarding status
        hasCompletedOnboarding = UserDefaultsManager.shared.hasCompletedOnboarding
    }
}

#Preview {
    ContentView()
}
