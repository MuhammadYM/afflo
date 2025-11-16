import SwiftUI

struct FocusMetric: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // TODO: Make dynamic - update percentage when tasks completed or sessions finished
        // Show motivational text like "keep going" or "5% more than last week"

        VStack(spacing: 4) {
            Text("Focus")
                .font(.anonymousPro(size: 15))
                .foregroundColor(Color.text(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, -1)

            Text("0%")
                .font(.anonymousPro(size: 15))
                .foregroundColor(Color.text(for: colorScheme))

            Text("start sessions and\ncomplete tasks to\nincrease focus")
                .font(.anonymousPro(size: 10))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(0)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 2)
        .frame(width: 125, height: 100)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme), lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    FocusMetric()
}
