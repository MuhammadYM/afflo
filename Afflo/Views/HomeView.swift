import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusViewModel()
    @State private var isTaskComponentExpanded = false
    @State private var isMomentumExpanded = false
    @State private var showFocusSetup = false

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

                        QuickStatsBar(
                            streak: taskViewModel.currentStreak,
                            completedTasks: taskViewModel.tasks.filter { $0.isCompleted }.count,
                            totalTasks: taskViewModel.tasks.count,
                            focusHours: focusViewModel.totalFocusHoursToday
                        )
                        .padding(.top, 20)

                        HStack(spacing: 20) {
                            VoiceJournalComponent()

                            FocusMetric()
                        }
                        .frame(height: 100)
                        .padding(.top, 16)
                        .padding(.leading, 28)
                        .padding(.trailing, 28)

                        if !isTaskComponentExpanded {
                            TaskComponent(isExpanded: $isTaskComponentExpanded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 20)
                                .padding(.leading, 28)
                                .padding(.trailing, 28)
                        } else {
                            Spacer()
                                .frame(height: 127)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Productivity trend")
                                .font(.montserrat(size: 14))
                                .foregroundColor(Color.text(for: colorScheme))

                            ProductivityTrendCard(isExpanded: $isMomentumExpanded)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .zIndex(1) // Below TaskComponent but above overlay
                        }
                        .padding(.top, 20)
                        .padding(.leading, 28)
                        .padding(.trailing, 28)
                        .id("momentumCard")

                        Spacer()
                            .frame(height: 120)
                        }
                    }
                }
                .onChange(of: isMomentumExpanded) { _, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("momentumCard", anchor: .top)
                            }
                        }
                    }
                }
            }
            .zIndex(isMomentumExpanded ? 2 : 0)

            // Full screen tap-to-collapse overlay
            if isMomentumExpanded || isTaskComponentExpanded {
                Color.black.opacity(isTaskComponentExpanded ? 0.3 : 0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMomentumExpanded = false
                            isTaskComponentExpanded = false
                        }
                    }
                    .zIndex(1) // Overlay above background but below ScrollView when expanded
            }

            // Expanded TaskComponent as overlay
            if isTaskComponentExpanded {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        TaskComponent(isExpanded: $isTaskComponentExpanded)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.leading, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(999)
            }

            // Floating Focus Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if focusViewModel.isSessionActive {
                            // Show timer view
                        } else {
                            showFocusSetup = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: focusViewModel.isSessionActive ? "pause.fill" : "brain.head.profile")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)

                            if !focusViewModel.isSessionActive {
                                Text("Focus")
                                    .font(.montserrat(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F"), Color(hex: "#4A5568")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 28)
                    .padding(.bottom, 100) // Above tab bar
                }
            }
            .zIndex(1000)
        }
        .sheet(isPresented: $showFocusSetup) {
            FocusSessionSetupView(viewModel: focusViewModel)
        }
        .fullScreenCover(isPresented: $focusViewModel.isSessionActive) {
            FocusTimerView(viewModel: focusViewModel)
        }
        .task {
            await taskViewModel.loadTasks()
            await focusViewModel.loadTodaysFocusHours()
        }
    }
}

#Preview {
    HomeView()
}
