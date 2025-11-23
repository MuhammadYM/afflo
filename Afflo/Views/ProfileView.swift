import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Profile")
                        .font(.anonymousPro(size: 32, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))
                        .padding(.top, 60)

                    if profileViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if let profile = profileViewModel.userProfile {
                        // User Goals Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Manifestation")
                                .font(.anonymousPro(size: 20, weight: .bold))
                                .foregroundColor(Color.text(for: colorScheme))

                            ProfileInfoCard(
                                label: "What you want to manifest",
                                value: profile.manifestGoal ?? "Not set"
                            )

                            ProfileInfoCard(
                                label: "Why it matters",
                                value: profile.why ?? "Not set"
                            )

                            ProfileInfoCard(
                                label: "What's holding you back",
                                value: profile.obstacle ?? "Not set"
                            )
                        }

                        // Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Settings")
                                .font(.anonymousPro(size: 20, weight: .bold))
                                .foregroundColor(Color.text(for: colorScheme))
                                .padding(.top, 8)

                            Button(
                                action: {
                                    Task {
                                        await authViewModel.signOut()
                                    }
                                },
                                label: {
                                    HStack {
                                        Text("Sign Out")
                                            .font(.anonymousPro(size: 16))
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                    }
                                    .padding(16)
                                    .background(Color.background(for: colorScheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                                }
                            )

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
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            )
                            #endif
                        }
                    } else if let error = profileViewModel.errorMessage {
                        Text(error)
                            .font(.anonymousPro(size: 14))
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }
                .padding(.horizontal, 28)
            }
        }
        .task {
            await profileViewModel.fetchUserProfile()
        }
    }
}

struct ProfileInfoCard: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.anonymousPro(size: 12))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

            Text(value)
                .font(.anonymousPro(size: 16))
                .foregroundColor(Color.text(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
}
