import SwiftUI

struct BadgeUnlockToast: View {
    let badge: AchievementBadge
    @Environment(\.colorScheme) var colorScheme
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Badge icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F"), Color(hex: "#4A5568")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)

                Text(badge.type.emoji)
                    .font(.system(size: 40))
            }
            .scaleEffect(isShowing ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isShowing)

            // Text
            VStack(spacing: 8) {
                Text("Achievement Unlocked!")
                    .font(.montserrat(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#8E9AAF"))

                Text(badge.type.title)
                    .font(.montserrat(size: 20, weight: .bold))
                    .foregroundColor(Color.text(for: colorScheme))

                Text(badge.type.description)
                    .font(.montserrat(size: 12))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.background(for: colorScheme))
                .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#8E9AAF").opacity(0.3), lineWidth: 2)
        )
        .opacity(isShowing ? 1 : 0)
        .offset(y: isShowing ? 0 : -50)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isShowing)
        .onAppear {
            // Auto dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isShowing = false
                }
            }
        }
    }
}

// Achievement unlock overlay modifier
struct AchievementUnlockModifier: ViewModifier {
    @ObservedObject var viewModel: AchievementViewModel
    @State private var showToast = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let badge = viewModel.recentlyUnlocked, showToast {
                VStack {
                    BadgeUnlockToast(badge: badge, isShowing: $showToast)
                        .padding(.top, 100)
                    Spacer()
                }
                .zIndex(999)
            }
        }
        .onChange(of: viewModel.recentlyUnlocked) { _, newBadge in
            if newBadge != nil {
                withAnimation {
                    showToast = true
                }
            }
        }
    }
}

extension View {
    func achievementUnlockOverlay(_ viewModel: AchievementViewModel) -> some View {
        modifier(AchievementUnlockModifier(viewModel: viewModel))
    }
}
