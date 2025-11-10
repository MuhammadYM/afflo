import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = AuthViewModel()
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack(spacing: 0) {
                Spacer()

                // Middle content with tagline
                VStack {
                    Text("Its starts with the mind")
                        .font(.anonymousPro(size: 18))
                        .foregroundColor(Color(hex: "#333333"))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Footer with buttons
                VStack(spacing: 15) {
                    // Google Sign Up button (placeholder)
                    Button(action: {
                        // TODO: Implement Google sign-in
                    }) {
                        Text("SIGN UP WITH GOOGLE")
                            .font(.anonymousPro(size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.black)
                            .cornerRadius(8)
                    }

                    // Apple Sign In button
                    SignInWithAppleButton(.signUp) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAppleSignIn(authorization: authorization)
                        case .failure(let error):
                            print("Apple Sign In failed: \(error.localizedDescription)")
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
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

    private func handleAppleSignIn(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8),
              let nonce = currentNonce else {
            return
        }

        Task {
            await viewModel.signInWithApple(idToken: idTokenString, nonce: nonce)
        }
    }

    // MARK: - Nonce generation for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

#Preview {
    AuthView()
}
