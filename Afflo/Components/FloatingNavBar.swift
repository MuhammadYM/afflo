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
                .overlay(
                    RoundedRectangle(cornerRadius: 34)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 1)
    }
}

#Preview {
    VStack {
        Spacer()
        FloatingNavBar(selectedTab: .constant(0))
    }
    .background(Color.background(for: .light))
}
