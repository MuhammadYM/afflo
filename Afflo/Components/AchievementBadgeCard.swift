import SwiftUI

struct AchievementBadgeCard: View {
    let badge: AchievementBadge
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(
                        badge.isUnlocked ?
                        LinearGradient(
                            colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.icon(for: colorScheme).opacity(0.1), Color.icon(for: colorScheme).opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Text(badge.type.emoji)
                    .font(.system(size: 32))
                    .opacity(badge.isUnlocked ? 1.0 : 0.3)
            }

            // Title
            Text(badge.type.title)
                .font(.montserrat(size: 12, weight: .bold))
                .foregroundColor(Color.text(for: colorScheme))
                .multilineTextAlignment(.center)

            // Progress or unlock date
            if badge.isUnlocked {
                if let unlockedDate = badge.unlockedAt {
                    Text(formatDate(unlockedDate))
                        .font(.montserrat(size: 10))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                }
            } else {
                // Progress bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.icon(for: colorScheme).opacity(0.1))
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * (badge.progressPercentage / 100), height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)

                    Text("\(badge.progress)/\(badge.type.requirement)")
                        .font(.montserrat(size: 9))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.5))
                }
            }
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    badge.isUnlocked ?
                    Color(hex: "#8E9AAF").opacity(0.3) :
                    Color.tint(for: colorScheme).opacity(0.2),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct AchievementBadgeDetailView: View {
    let badge: AchievementBadge
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 32) {
                Spacer()

                // Large badge icon
                ZStack {
                    Circle()
                        .fill(
                            badge.isUnlocked ?
                            LinearGradient(
                                colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F"), Color(hex: "#4A5568")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.icon(for: colorScheme).opacity(0.1), Color.icon(for: colorScheme).opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: badge.isUnlocked ? Color.black.opacity(0.2) : Color.clear, radius: 20, x: 0, y: 10)

                    Text(badge.type.emoji)
                        .font(.system(size: 64))
                        .opacity(badge.isUnlocked ? 1.0 : 0.3)
                }

                // Title & description
                VStack(spacing: 8) {
                    Text(badge.type.title)
                        .font(.montserrat(size: 28, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))

                    Text(badge.type.description)
                        .font(.montserrat(size: 16))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                // Status
                if badge.isUnlocked {
                    VStack(spacing: 4) {
                        Text("Unlocked")
                            .font(.montserrat(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#8E9AAF"))

                        if let unlockedDate = badge.unlockedAt {
                            Text(formatFullDate(unlockedDate))
                                .font(.montserrat(size: 12))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("Progress")
                            .font(.montserrat(size: 14, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.icon(for: colorScheme).opacity(0.1))
                                    .frame(height: 8)
                                    .cornerRadius(4)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * (badge.progressPercentage / 100), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 40)

                        Text("\(badge.progress) / \(badge.type.requirement)")
                            .font(.montserrat(size: 16, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        Text("\(Int(badge.progressPercentage))% complete")
                            .font(.montserrat(size: 12))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                    }
                }

                Spacer()

                // Close button
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.montserrat(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }
        }
    }

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
