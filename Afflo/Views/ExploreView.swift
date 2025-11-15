import SwiftUI

struct ExploreView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack {
                Text("Explore")
                    .font(.anonymousPro(size: 24))
                    .foregroundColor(Color.text(for: colorScheme))

                Spacer()

                #if DEBUG
                Button(
                    action: {
                        Task {
                            await authViewModel.signOut()
                        }
                    },
                    label: {
                        Text("Reset App (Debug Only)")
                            .font(.anonymousPro(size: 14))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                )
                .padding(.bottom, 40)
                #endif
            }
        }
    }
}

#Preview {
    ExploreView()
}
