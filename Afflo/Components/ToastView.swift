import SwiftUI

struct ToastView: View {
    @Binding var show: Bool
    @Binding var message: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Spacer()

            if show {
                Text(message)
                    .font(.anonymousPro(size: 14))
                    .foregroundColor(Color.text(for: colorScheme))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.background(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.tint(for: colorScheme), lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                show = false
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: show)
    }
}
