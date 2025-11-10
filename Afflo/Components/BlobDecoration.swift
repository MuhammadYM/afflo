import SwiftUI

struct BlobDecoration: View {
    var body: some View {
        Circle()
            .fill(Color.blob)
            .frame(width: 220, height: 220)
            .opacity(0.5)
    }
}

#Preview {
    ZStack {
        Color.lightBackground
        BlobDecoration()
    }
}
