import SwiftUI

struct MomentumLineGraph: View {
    @Environment(\.colorScheme) var colorScheme

    let dataPoints: [MomentumDataPoint]
    let isExpanded: Bool

    private var graphHeight: CGFloat {
        isExpanded ? 200 : 120
    }

    private var minValue: Double {
        dataPoints.map { $0.value }.min() ?? 0
    }

    private var maxValue: Double {
        dataPoints.map { $0.value }.max() ?? 100
    }

    var body: some View {
        VStack(spacing: 8) {
            // Graph area
            GeometryReader { geometry in
                ZStack {
                    // Horizontal gridlines
                    ForEach(0..<3, id: \.self) { index in
                        let yPosition = geometry.size.height * CGFloat(index) / 2
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: yPosition))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: yPosition))
                        }
                        .stroke(
                            colorScheme == .light ? Color.lightGridLine : Color.darkGridLine,
                            lineWidth: 1
                        )
                    }

                    // Gradient fill under curve
                    gradientPath(in: geometry.size)
                        .fill(
                            LinearGradient(
                                colors: [Color.blob.opacity(0.25), Color.blob.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Line path
                    linePath(in: geometry.size)
                        .stroke(Color.blob, lineWidth: 2.5)

                    // Data point markers
                    ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, _ in
                        let position = pointPosition(for: index, in: geometry.size)
                        Circle()
                            .fill(Color.blob)
                            .frame(width: 6, height: 6)
                            .position(position)
                    }
                }
            }
            .frame(height: graphHeight)

            // X-axis labels
            HStack(spacing: 0) {
                ForEach(dataPoints) { point in
                    Text(point.day)
                        .font(.anonymousPro(size: 11))
                        .foregroundColor(Color.icon(for: colorScheme).opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: - Path Helpers

    private func linePath(in size: CGSize) -> Path {
        var path = Path()

        guard dataPoints.count > 1 else { return path }

        let points = dataPoints.indices.map { index in
            pointPosition(for: index, in: size)
        }

        // Start at first point
        path.move(to: points[0])

        // Create smooth curve through points
        if points.count == 2 {
            path.addLine(to: points[1])
        } else {
            for idx in 0..<points.count - 1 {
                let current = points[idx]
                let next = points[idx + 1]

                // Calculate control points for smooth curve
                let controlPoint1 = CGPoint(
                    x: current.x + (next.x - current.x) * 0.5,
                    y: current.y
                )
                let controlPoint2 = CGPoint(
                    x: current.x + (next.x - current.x) * 0.5,
                    y: next.y
                )

                path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
            }
        }

        return path
    }

    private func gradientPath(in size: CGSize) -> Path {
        var path = linePath(in: size)

        // Close the path to create filled area
        let lastX = size.width * CGFloat(dataPoints.count - 1) / CGFloat(max(dataPoints.count - 1, 1))
        path.addLine(to: CGPoint(x: lastX, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        return path
    }

    private func pointPosition(for index: Int, in size: CGSize) -> CGPoint {
        let value = dataPoints[index].value
        let valueRange = maxValue - minValue

        // When all values are the same, use absolute positioning (0-100 scale)
        let normalizedValue: Double
        if valueRange > 0 {
            normalizedValue = (value - minValue) / valueRange
        } else if maxValue > 0 {
            // All values same and non-zero, show at their proportional height (0-100 scale)
            normalizedValue = value / 100.0
        } else {
            // All values are 0, show at bottom
            normalizedValue = 0.0
        }

        let xPosition = size.width * CGFloat(index) / CGFloat(max(dataPoints.count - 1, 1))
        let yPosition = size.height * (1 - normalizedValue) // Invert Y (0 at top, height at bottom)

        return CGPoint(x: xPosition, y: yPosition)
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Collapsed")
            .font(.anonymousPro(size: 16))
        MomentumLineGraph(
            dataPoints: [
                MomentumDataPoint(day: "Mon", value: 75, date: Date()),
                MomentumDataPoint(day: "Tue", value: 68, date: Date()),
                MomentumDataPoint(day: "Wed", value: 72, date: Date()),
                MomentumDataPoint(day: "Thu", value: 85, date: Date()),
                MomentumDataPoint(day: "Fri", value: 88, date: Date()),
                MomentumDataPoint(day: "Sat", value: 92, date: Date()),
                MomentumDataPoint(day: "Sun", value: 95, date: Date())
            ],
            isExpanded: false
        )
        .padding()

        Text("Expanded")
            .font(.anonymousPro(size: 16))
        MomentumLineGraph(
            dataPoints: [
                MomentumDataPoint(day: "Mon", value: 75, date: Date()),
                MomentumDataPoint(day: "Tue", value: 68, date: Date()),
                MomentumDataPoint(day: "Wed", value: 72, date: Date()),
                MomentumDataPoint(day: "Thu", value: 85, date: Date()),
                MomentumDataPoint(day: "Fri", value: 88, date: Date()),
                MomentumDataPoint(day: "Sat", value: 92, date: Date()),
                MomentumDataPoint(day: "Sun", value: 95, date: Date())
            ],
            isExpanded: true
        )
        .padding()
    }
    .background(Color.lightBackground)
}
