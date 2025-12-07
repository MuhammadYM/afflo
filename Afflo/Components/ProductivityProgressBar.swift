import SwiftUI

struct ProductivityProgressBar: View {
    @Environment(\.colorScheme) var colorScheme

    let label: String
    let value: Double
    let maxValue: Double

    init(label: String, value: Double, maxValue: Double = 1.0) {
        self.label = label
        self.value = value
        self.maxValue = maxValue
    }

    private var progress: Double {
        min(max(value / maxValue, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.anonymousPro(size: 13))
                    .foregroundColor(Color.text(for: colorScheme))

                Spacer()

                Text(String(format: "%.1f", value))
                    .font(.anonymousPro(size: 13))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.icon(for: colorScheme).opacity(0.15))
                        .frame(height: 6)

                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blob)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ProductivityProgressBar(label: "Sessions", value: 0.7)
        ProductivityProgressBar(label: "Focus", value: 0.4)
        ProductivityProgressBar(label: "Journal", value: 0.2)
        ProductivityProgressBar(label: "Tasks", value: 0.9)
    }
    .padding()
    .background(Color.lightBackground)
}
