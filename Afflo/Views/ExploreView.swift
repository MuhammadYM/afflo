import SwiftUI

struct ExploreView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack {
                Text("Explore")
                    .font(.anonymousPro(size: 24))
                    .foregroundColor(Color.text(for: colorScheme))
            }
        }
    }
}

#Preview {
    ExploreView()
}
