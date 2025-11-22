import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", image: "home-icon")
                }
                .tag(0)

            GoalsView()
                .tabItem {
                    Label("Goals", image: "ai-icon")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", image: "profile-icon")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { _, _ in
            // Haptic feedback on tab change
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        .onAppear {
            // Configure tab bar appearance with blur effect
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()

            // Add blur effect
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
