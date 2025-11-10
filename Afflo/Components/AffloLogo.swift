import SwiftUI

struct AffloLogo: View {
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 56, height: CGFloat = 56) {
        self.width = width
        self.height = height
    }

    var body: some View {
        Image("afflo-logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        AffloLogo()
        AffloLogo(width: 100, height: 100)
        AffloLogo(width: 200, height: 200)
    }
    .padding()
}
