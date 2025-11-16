import SwiftUI

struct VoiceJournalComponent: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(
            action: {
                // Empty action for now
            },
            label: {
                VStack(spacing: 8) {
                    Image("mic-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 21)

                    Text("start voice\njournal")
                        .font(.anonymousPro(size: 16))
                        .foregroundColor(Color.text(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .padding(.vertical, 19)
                .frame(width: 182)
                .background(Color.background(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.tint(for: colorScheme), lineWidth: 2)
                )
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VoiceJournalComponent()
}
