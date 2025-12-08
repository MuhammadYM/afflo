import SwiftUI

struct VoiceRecordingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VoiceJournalViewModel

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 32) {
                // Header
                HStack {
                    Text("Voice Journal")
                        .font(.montserrat(size: 24, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))

                    Spacer()

                    if !viewModel.isRecording {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                                .foregroundColor(Color.icon(for: colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)

                Spacer()

                // Recording visualization
                VStack(spacing: 24) {
                    // Pulse animation
                    ZStack {
                        if viewModel.isRecording {
                            Circle()
                                .fill(Color(hex: "#8E9AAF").opacity(0.2))
                                .frame(width: 200, height: 200)
                                .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isRecording)

                            Circle()
                                .fill(Color(hex: "#8E9AAF").opacity(0.3))
                                .frame(width: 160, height: 160)
                                .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isRecording)
                        }

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

                        Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }

                    // Duration
                    if viewModel.isRecording {
                        Text(viewModel.formattedDuration)
                            .font(.montserrat(size: 32, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))
                    }

                    // Status
                    Text(viewModel.isRecording ? "Recording..." : "Tap to start recording")
                        .font(.montserrat(size: 16))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                }

                Spacer()

                // Live transcription
                if !viewModel.transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Live Transcription")
                            .font(.montserrat(size: 14, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        ScrollView {
                            Text(viewModel.transcription)
                                .font(.montserrat(size: 14))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                    }
                    .padding(16)
                    .background(Color.background(for: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#8E9AAF").opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 28)
                }

                // Control button
                Button(action: {
                    Task {
                        if viewModel.isRecording {
                            await viewModel.stopRecording()
                        } else {
                            await viewModel.startRecording()
                        }
                    }
                }) {
                    Text(viewModel.isRecording ? "Stop & Process" : "Start Recording")
                        .font(.montserrat(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: viewModel.isRecording ?
                                    [Color.red.opacity(0.8), Color.red] :
                                    [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }
        }
        .onDisappear {
            if viewModel.isRecording {
                Task {
                    await viewModel.stopRecording()
                }
            }
        }
    }
}
