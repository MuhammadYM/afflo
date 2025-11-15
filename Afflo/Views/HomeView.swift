import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authViewModel = AuthViewModel()
    @State private var startTime = Date.now

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            BackgroundGridOverlay()

            VStack {
                // Orb with dark background
                ZStack {
                    // Dark circle background to make orb pop
                    Circle()
                        .fill(Color.black.opacity(0.9))
                        .frame(width: 280, height: 280)
                    
                    // Inline shader version for testing
                    TimelineView(.animation) { timeline in
                        let elapsedTime = Float(startTime.distance(to: timeline.date))
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 250, height: 250)
                            .colorEffect(
                                ShaderLibrary.simpleRevolvingOrb(
                                    .float2(250, 250),
                                    .float(elapsedTime),
                                    .float(0.5),
                                    .color(Color(red: 0.33, green: 0.51, blue: 1.0)),
                                    .color(Color(red: 0.32, green: 1.0, blue: 0.98))
                                )
                            )
                    }
                }
                .padding(.top, 40)
                
                Text("Home")
                    .font(.anonymousPro(size: 24))
                    .foregroundColor(Color.text(for: colorScheme))

                Spacer()

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
}

#Preview {
    HomeView()
}
