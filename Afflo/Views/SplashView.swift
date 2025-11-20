import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showLogo = false
    @State private var showText = false

    var body: some View {
        ZStack {
            Color.background(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Group {
                    if colorScheme == .dark {
                        AffloLogo(width: 100, height: 100)
                            .colorInvert()
                    } else {
                        AffloLogo(width: 100, height: 100)
                    }
                }
                .opacity(showLogo ? 1 : 0)

                Text("Its starts with the mind")
                    .font(.anonymousPro(size: 16))
                    .foregroundColor(Color.text(for: colorScheme))
                    .opacity(showText ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                showLogo = true
            }
            withAnimation(.easeIn(duration: 1.0).delay(0.9)) {
                showText = true
            }
        }
    }
}

#Preview {
    SplashView()
}
