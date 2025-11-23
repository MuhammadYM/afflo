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
                FloatingNavBar(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    MainTabView()
}
