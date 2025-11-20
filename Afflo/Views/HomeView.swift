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

            ScrollViewReader { proxy in
                ScrollView {
                    ZStack {
                        // Transparent background to catch taps outside cards
                        if isMomentumExpanded || isTaskComponentExpanded {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        isMomentumExpanded = false
                                        isTaskComponentExpanded = false
                                    }
                                }
                        }

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

                        VStack(spacing: 0) {
                            MomentumTrendCard(isExpanded: $isMomentumExpanded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .zIndex(1) // Below TaskComponent but above overlay
                        }
                        .padding(.top, 20)
                        .padding(.leading, 28)
                        .padding(.trailing, 28)
                        .id("momentumCard")

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
                }
                .onChange(of: isMomentumExpanded) { oldValue, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("momentumCard", anchor: .top)
                            }
                        }
                    }
                }
            }
            .zIndex(isTaskComponentExpanded || isMomentumExpanded ? 2 : 0)

            // Full screen tap-to-collapse overlay
            if isMomentumExpanded || isTaskComponentExpanded {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMomentumExpanded = false
                            isTaskComponentExpanded = false
                        }
                    }
                    .zIndex(1) // Overlay above background but below ScrollView when expanded
            }
        }
    }
}

#Preview {
    HomeView()
}
