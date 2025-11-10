import SwiftUI

struct BackgroundGridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal lines (3 lines)
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gridLine)
                        .frame(height: 1)
                        .offset(y: horizontalLineOffset(index: index, height: geometry.size.height))
                }

                // Vertical lines (2 lines)
                ForEach(0..<2, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gridLine)
                        .frame(width: 1)
                        .offset(x: verticalLineOffset(index: index, width: geometry.size.width))
                }
            }
        }
        .ignoresSafeArea()
    }

    private func horizontalLineOffset(index: Int, height: CGFloat) -> CGFloat {
        // Distribute 3 horizontal lines evenly
        let spacing = height / 4
        return spacing * CGFloat(index + 1) - height / 2
    }

    private func verticalLineOffset(index: Int, width: CGFloat) -> CGFloat {
        // Distribute 2 vertical lines evenly
        let spacing = width / 3
        return spacing * CGFloat(index + 1) - width / 2
    }
}

#Preview {
    ZStack {
        Color.lightBackground
        BackgroundGridOverlay()
    }
}
