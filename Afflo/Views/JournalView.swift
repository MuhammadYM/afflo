import SwiftUI

struct JournalView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Color.background(for: colorScheme)
                    .ignoresSafeArea()

                BackgroundGridOverlay()

                VStack {
                    Text("Journal")
                        .font(.anonymousPro(size: 24, weight: .bold))
                        .foregroundColor(.text(for: colorScheme))

                    Spacer()
                }
                .padding(.top, 60)
            }
        }
    }
}

#Preview {
    JournalView()
}
