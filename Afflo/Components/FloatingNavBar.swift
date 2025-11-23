import SwiftUI

struct FloatingNavBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            NavBarButton(
                image: "home-icon",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 },
                useTemplate: true
            )

            Spacer()

            NavBarButton(
                image: "ai-icon",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 },
                useTemplate: false
            )

            Spacer()

            NavBarButton(
                image: "journal-icon",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 },
                useTemplate: false
            )

            Spacer()

            NavBarButton(
                image: "profile-icon",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 },
                useTemplate: true
            )
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 34)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 34)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    // Inner highlight for more depth
                    RoundedRectangle(cornerRadius: 34)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.15),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 0.5
                        )
                        .padding(1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        FloatingNavBar(selectedTab: .constant(0))
    }
    .background(Color.background(for: .light))
}
