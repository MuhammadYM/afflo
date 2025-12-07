import SwiftUI

struct ProductivityBreakdownView: View {
    @Environment(\.colorScheme) var colorScheme

    let breakdown: ProductivityBreakdown

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
                ProductivityProgressBar(label: "Sessions", value: breakdown.sessions)
                ProductivityProgressBar(label: "Focus", value: breakdown.focus)
                ProductivityProgressBar(label: "Journal", value: breakdown.journal)
                ProductivityProgressBar(label: "Tasks", value: breakdown.tasks)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    ProductivityBreakdownView(
        breakdown: ProductivityBreakdown(
            sessions: 0.7,
            focus: 0.4,
            journal: 0.2,
            tasks: 0.9
        )
    )
    .padding()
    .background(Color.lightBackground)
}
