import SwiftUI

struct FocusSessionSetupView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FocusViewModel

    @State private var selectedDuration: Int = 25
    @State private var selectedSound: FocusSoundType? = .rain

    let durationOptions = [15, 25, 45, 60, 90]

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Focus Session")
                        .font(.anonymousPro(size: 24, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(Color.icon(for: colorScheme))
                    }
                }
                .padding(.top, 20)

                // Duration Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                    HStack(spacing: 12) {
                        ForEach(durationOptions, id: \.self) { duration in
                            DurationButton(
                                duration: duration,
                                isSelected: selectedDuration == duration,
                                action: { selectedDuration = duration }
                            )
                        }
                    }
                }

                // Sound Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Sound")
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                    VStack(spacing: 8) {
                        ForEach(FocusSoundType.allCases, id: \.self) { sound in
                            SoundOptionButton(
                                sound: sound,
                                isSelected: selectedSound == sound,
                                action: { selectedSound = sound }
                            )
                        }

                        // None option
                        SoundOptionButton(
                            sound: nil,
                            isSelected: selectedSound == nil,
                            action: { selectedSound = nil }
                        )
                    }
                }

                Spacer()

                // Start Button
                Button(action: {
                    Task {
                        await viewModel.startSession(duration: selectedDuration, sound: selectedSound)
                        dismiss()
                    }
                }) {
                    Text("Start Focus")
                        .font(.anonymousPro(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blob)
                        .cornerRadius(12)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 28)
        }
    }
}

struct DurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text("\(duration)m")
                .font(.anonymousPro(size: 14))
                .foregroundColor(isSelected ? .white : Color.text(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blob : Color.background(for: colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blob : Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
        }
    }
}

struct SoundOptionButton: View {
    let sound: FocusSoundType?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack {
                if let sound = sound {
                    Text(sound.emoji)
                        .font(.system(size: 18))

                    Text(sound.rawValue)
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme))
                } else {
                    Text("🔇")
                        .font(.system(size: 18))

                    Text("No Sound")
                        .font(.anonymousPro(size: 14))
                        .foregroundColor(Color.text(for: colorScheme))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.blob)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.background(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blob : Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }
}

#Preview {
    FocusSessionSetupView(viewModel: FocusViewModel())
}
