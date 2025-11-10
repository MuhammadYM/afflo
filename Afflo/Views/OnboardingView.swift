import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 0) {
                // Header with logo bar
                HStack {
                    Rectangle()
                        .fill(Color(hex: "#0F0F0F"))
                        .opacity(0.9)
                        .frame(width: 56, height: 10)
                        .cornerRadius(2)
                    Spacer()
                }
                .frame(height: 64)
                .padding(.top, 28)
                .padding(.horizontal, 24)

                // Middle content with blob
                VStack {
                    BlobDecoration()
                }
                .padding(.top, 36)

                // Question and answer section
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.currentQuestion.question)
                        .font(.custom("AnonymousPro-Italic", size: 18))
                        .foregroundColor(Color.text(for: colorScheme))

                    VStack(alignment: .leading, spacing: 4) {
                        TextEditor(text: Binding(
                            get: { viewModel.currentAnswer },
                            set: { viewModel.updateAnswer($0) }
                        ))
                        .font(.anonymousPro(size: 16))
                        .foregroundColor(Color.text(for: colorScheme))
                        .frame(minHeight: 100)
                        .padding(EdgeInsets(top: 16, leading: 14, bottom: 16, trailing: 14))
                        .background(Color.inputBackground)
                        .cornerRadius(10)
                        .disabled(viewModel.isSubmitting)
                        .scrollContentBackground(.hidden)

                        Text("\(viewModel.currentAnswer.count)/500")
                            .font(.anonymousPro(size: 12))
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        // TODO: Add voice recording functionality
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer()

                // Footer with navigation buttons
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.handleBack()
                    }) {
                        Text("Back")
                            .font(.anonymousPro(size: 16))
                            .foregroundColor(Color(hex: "#2B2B2B"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.buttonGray)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.stepIndex == 0 || viewModel.isSubmitting)
                    .opacity(viewModel.stepIndex == 0 || viewModel.isSubmitting ? 0.6 : 1.0)

                    Button(action: {
                        Task {
                            await viewModel.handleNext(onComplete: onComplete)
                        }
                    }) {
                        Text(viewModel.isSubmitting ? "Saving..." : (viewModel.isLastStep ? "Finish" : "Next"))
                            .font(.custom("AnonymousPro-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.buttonBlack)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.canProceed || viewModel.isSubmitting)
                    .opacity(!viewModel.canProceed || viewModel.isSubmitting ? 0.4 : 1.0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {
        print("Onboarding complete")
    })
}
