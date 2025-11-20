import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isTaskComponentExpanded = false
    @State private var isMomentumExpanded = false

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            ScrollView {
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

                    TaskComponent(isExpanded: $isTaskComponentExpanded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.leading, 28)
                        .padding(.trailing, 28)
                        .zIndex(2) // Ensure TaskComponent is above the overlay

                    MomentumTrendCard(isExpanded: $isMomentumExpanded)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.leading, 28)
                        .padding(.trailing, 28)
                        .zIndex(1) // Below TaskComponent but above overlay

                    Spacer()
                        .frame(height: 40)

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
            .zIndex(1) // ScrollView should be above overlay
            
            // Full screen tap-to-collapse overlay
            if isTaskComponentExpanded || isMomentumExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isTaskComponentExpanded = false
                            isMomentumExpanded = false
                        }
                    }
                    .zIndex(0) // Overlay behind the VStack
            }
        }
    }
}

#Preview {
    HomeView()
}
