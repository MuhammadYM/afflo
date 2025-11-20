import SwiftUI

struct MomentumBreakdownView: View {
    @Environment(\.colorScheme) var colorScheme

    let breakdown: MomentumBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("Your weekly growth trend")
                .font(.anonymousPro(size: 13))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

            // Divider
            Rectangle()
                .fill(Color.icon(for: colorScheme).opacity(0.15))
                .frame(height: 1)

            // Progress bars
            VStack(spacing: 10) {
                MomentumProgressBar(label: "Sessions", value: breakdown.sessions)
                MomentumProgressBar(label: "Focus", value: breakdown.focus)
                MomentumProgressBar(label: "Journal", value: breakdown.journal)
                MomentumProgressBar(label: "Tasks", value: breakdown.tasks)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    MomentumBreakdownView(
        breakdown: MomentumBreakdown(
            sessions: 0.7,
            focus: 0.4,
            journal: 0.2,
            tasks: 0.9
        )
    )
    .padding()
    .background(Color.lightBackground)
}
