import SwiftUI

struct QuickStatsBar: View {
    let streak: Int
    let completedTasks: Int
    let totalTasks: Int
    let focusHours: Double

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            StatPill(
                icon: "🔥",
                text: "\(streak) day\(streak == 1 ? "" : "s")"
            )

            StatPill(
                icon: "✅",
                text: "\(completedTasks)/\(totalTasks) tasks"
            )

            StatPill(
                icon: "🎯",
                text: String(format: "%.1fh focused", focusHours)
            )
        }
        .padding(.horizontal, 28)
    }
}

struct StatPill: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 12))

            Text(text)
                .font(.anonymousPro(size: 12))
                .foregroundColor(Color.text(for: colorScheme))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    ZStack {
        Color.lightBackground
            .ignoresSafeArea()

        VStack(spacing: 20) {
            QuickStatsBar(
                streak: 14,
                completedTasks: 3,
                totalTasks: 5,
                focusHours: 2.5
            )

            QuickStatsBar(
                streak: 0,
                completedTasks: 0,
                totalTasks: 3,
                focusHours: 0
            )
        }
    }
}
