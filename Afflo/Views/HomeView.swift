import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(alignment: .leading, spacing: 0) {
                DateScrollView()
                    .padding(.top, 60)

                HStack(spacing: 20) {
                    VoiceJournalComponent()

                    FocusMetric()
                }
                .frame(height: 100)
                .padding(.top, 36)
                .padding(.leading, 28)
                .padding(.trailing, 28)

                TaskComponent()
                    .padding(.top, 20)
                    .padding(.leading, 28)
                    .padding(.trailing, 28)

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
    HomeView()
}
