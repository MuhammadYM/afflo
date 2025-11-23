import SwiftUI

struct CustomNavBar: View {
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
            (colorScheme == .dark ? Color.black.opacity(0.6) : Color.white.opacity(0.6))
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.tint(for: colorScheme).opacity(0.2))
                .padding(.horizontal, 0),
            alignment: .top
        )
    }
}

struct NavBarButton: View {
    let image: String
    let isSelected: Bool
    let action: () -> Void
    let useTemplate: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(
            action: {
                action()
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            },
            label: {
                Image(image)
                    .resizable()
                    .renderingMode(useTemplate ? .template : .original)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(useTemplate && isSelected ? Color.tint(for: colorScheme) : (useTemplate ? Color.icon(for: colorScheme) : nil))
                    .shadow(color: isSelected ? Color.tint(for: colorScheme).opacity(0.8) : Color.clear, radius: 12, x: 0, y: 0)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        )
    }
}

#Preview {
    VStack {
        Spacer()
        CustomNavBar(selectedTab: .constant(0))
    }
    .background(Color.background(for: .light))
}
