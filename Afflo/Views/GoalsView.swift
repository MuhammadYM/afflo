import SwiftUI

struct GoalsView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Goals")
                        .font(.anonymousPro(size: 32, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))
                        .padding(.top, 60)

                    // Milestones Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Milestones")
                            .font(.anonymousPro(size: 20, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        PlaceholderCard(text: "Your milestones will appear here")
                    }

                    // Goals Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Active Goals")
                            .font(.anonymousPro(size: 20, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        PlaceholderCard(text: "Your active goals will appear here")
                    }

                    // AI Insights Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Insights")
                            .font(.anonymousPro(size: 20, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        PlaceholderCard(text: "Personalized insights coming soon")
                    }

                    Spacer()
                }
                .padding(.horizontal, 28)
            }
        }
    }
}

struct PlaceholderCard: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text(text)
                .font(.anonymousPro(size: 14))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    GoalsView()
}
