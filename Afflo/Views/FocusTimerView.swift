import SwiftUI

struct FocusTimerView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: FocusViewModel
    @State private var showEndConfirmation = false

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 40) {
                Spacer()

                // Timer Circle
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.icon(for: colorScheme).opacity(0.15), lineWidth: 8)
                        .frame(width: 240, height: 240)

                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blob, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: progress)

                    // Pulsing sound wave (if sound is playing)
                    if viewModel.selectedSound != nil {
                        Circle()
                            .fill(Color.blob.opacity(0.2))
                            .frame(width: pulseSize, height: pulseSize)
                            .scaleEffect(pulse ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                            .onAppear { pulse = true }
                    }

                    // Time remaining
                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.anonymousPro(size: 48, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        if let sound = viewModel.selectedSound {
                            Text(sound.emoji)
                                .font(.system(size: 24))
                        }
                    }
                }

                Spacer()

                // End Session Button
                Button(action: {
                    showEndConfirmation = true
                }) {
                    Text("End Session")
                        .font(.anonymousPro(size: 16))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.background(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
        .confirmationDialog("End Focus Session?", isPresented: $showEndConfirmation) {
            Button("End Session", role: .destructive) {
                Task {
                    await viewModel.endSession()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Computed Properties
    private var progress: Double {
        guard let session = viewModel.currentSession else { return 0 }
        let totalSeconds = Double(session.duration * 60)
        return (totalSeconds - viewModel.remainingTime) / totalSeconds
    }

    private var timeString: String {
        let minutes = Int(viewModel.remainingTime) / 60
        let seconds = Int(viewModel.remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var pulseSize: CGFloat {
        160
    }

    @State private var pulse = false
}

#Preview {
    let viewModel = FocusViewModel()
    Task {
        await viewModel.startSession(duration: 25, sound: .rain)
    }
    return FocusTimerView(viewModel: viewModel)
}
