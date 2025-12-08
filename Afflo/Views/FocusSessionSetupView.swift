import SwiftUI

struct FocusSessionSetupView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FocusViewModel

    @State private var selectedDuration: Int = 25
    @State private var selectedSound: FocusSoundType? = .rain
    @State private var showCustomDuration = false
    @State private var customHours = 0
    @State private var customMinutes = 25
    @State private var customTimeConfirmed = false

    let durationOptions = [25, 45, 60] // Pomodoro, standard, and 1 hour
    let hours = Array(0...23)
    let minutes = Array(0...59)

    var customTimeDisplay: String {
        if customHours > 0 && customMinutes > 0 {
            return "\(customHours)h \(customMinutes)m"
        } else if customHours > 0 {
            return "\(customHours)h"
        } else {
            return "\(customMinutes)m"
        }
    }

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Focus Session")
                        .font(.montserrat(size: 24, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(Color.icon(for: colorScheme))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                // Duration Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.montserrat(size: 14))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(durationOptions, id: \.self) { duration in
                            DurationButton(
                                duration: duration,
                                isSelected: selectedDuration == duration && !customTimeConfirmed,
                                action: {
                                    selectedDuration = duration
                                    showCustomDuration = false
                                    customTimeConfirmed = false
                                }
                            )
                        }

                        // Custom duration button
                        Button(action: {
                            withAnimation {
                                showCustomDuration.toggle()
                                if showCustomDuration {
                                    // Initialize picker to current selection or default
                                    if customTimeConfirmed {
                                        customHours = selectedDuration / 60
                                        customMinutes = selectedDuration % 60
                                    }
                                }
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text(customTimeConfirmed ? customTimeDisplay : "Custom")
                                    .font(.montserrat(size: 14, weight: .bold))
                                    .foregroundColor(customTimeConfirmed ? .white : Color.text(for: colorScheme))

                                if customTimeConfirmed {
                                    Text("custom")
                                        .font(.montserrat(size: 10))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                customTimeConfirmed ?
                                LinearGradient(
                                    colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.background(for: colorScheme), Color.background(for: colorScheme)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(customTimeConfirmed ? Color(hex: "#8E9AAF") : Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                        .id(customTimeDisplay) // Force update when time changes
                    }

                    // Custom duration picker
                    if showCustomDuration {
                        VStack(spacing: 16) {
                            HStack(spacing: 0) {
                                Spacer()

                                // Hours picker
                                Picker("", selection: $customHours) {
                                    ForEach(hours, id: \.self) { hour in
                                        Text("\(hour)")
                                            .font(.montserrat(size: 20))
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()

                                Text("hours")
                                    .font(.montserrat(size: 16))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .padding(.horizontal, 8)

                                // Minutes picker
                                Picker("", selection: $customMinutes) {
                                    ForEach(minutes, id: \.self) { minute in
                                        Text("\(minute)")
                                            .font(.montserrat(size: 20))
                                            .tag(minute)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 80, height: 120)
                                .clipped()

                                Text("min")
                                    .font(.montserrat(size: 16))
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .padding(.horizontal, 8)

                                Spacer()
                            }

                            // Confirm button
                            Button(action: {
                                withAnimation {
                                    selectedDuration = customHours * 60 + customMinutes
                                    customTimeConfirmed = true
                                    showCustomDuration = false
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text("Confirm Time")
                                        .font(.montserrat(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(8)
                            }
                        }
                        .transition(.opacity)
                        .padding(.top, 8)
                    }
                }

                // Sound Picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Sound")
                        .font(.montserrat(size: 14))
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
                    }
                    .padding(.horizontal, 28)
                }

                // Start Button - Fixed at bottom
                Button(action: {
                    Task {
                        await viewModel.startSession(duration: selectedDuration, sound: selectedSound)
                        dismiss()
                    }
                }) {
                    Text("Start Focus")
                        .font(.montserrat(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blob)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
                .padding(.top, 12)
            }
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
                .font(.montserrat(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : Color.text(for: colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Color(hex: "#8E9AAF"), Color(hex: "#6B7A8F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.background(for: colorScheme), Color.background(for: colorScheme)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(hex: "#8E9AAF") : Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
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
                        .font(.montserrat(size: 14))
                        .foregroundColor(Color.text(for: colorScheme))
                } else {
                    Text("🔇")
                        .font(.system(size: 18))

                    Text("No Sound")
                        .font(.montserrat(size: 14))
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
