import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Content views
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    GoalsView()
                case 2:
                    JournalView()
                case 3:
                    ProfileView()
                default:
                    HomeView()
                }
            }
            .ignoresSafeArea(.all, edges: .bottom)

            // Floating nav bar at bottom
            VStack {
                Spacer()
                CustomNavBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Additional method to hide home indicator
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.setNeedsUpdateOfHomeIndicatorAutoHidden()
            }
        }
    }
}

#Preview {
    MainTabView()
}
