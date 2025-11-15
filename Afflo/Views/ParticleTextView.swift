import SwiftUI

// MARK: - Particle Data Model
struct Particle: Identifiable {
    let id = UUID()
    let targetPosition: CGPoint
    let startPosition: CGPoint
    let color: Color
    let size: CGFloat

    init(targetPosition: CGPoint, color: Color, size: CGFloat = 2.0, canvasSize: CGSize) {
        self.targetPosition = targetPosition
        self.color = color
        self.size = size

        // Start at random position within canvas bounds
        self.startPosition = CGPoint(
            x: CGFloat.random(in: -50...(canvasSize.width + 50)),
            y: CGFloat.random(in: -50...(canvasSize.height + 50))
        )
    }
}

// MARK: - Particle Text View
/// Minimal, fascinating particle-to-text animation
/// Particles converge from random positions to form text
struct ParticleTextView: View {
    let text: String
    let font: Font
    let particleColor: Color
    let backgroundColor: Color

    @State private var particles: [Particle] = []
    @State private var animationProgress: CGFloat = 0
    @State private var hasAnimated = false

    init(
        text: String,
        font: Font = .system(size: 80, weight: .bold),
        particleColor: Color = .white,
        backgroundColor: Color = .black
    ) {
        self.text = text
        self.font = font
        self.particleColor = particleColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                TimelineView(.animation) { _ in
                    Canvas { context, size in
                        let progress = min(animationProgress, 1.0)
                        let eased = easeInOutCubic(progress)

                        for particle in particles {
                            // Interpolate between start and target position
                            let x = particle.startPosition.x + (particle.targetPosition.x - particle.startPosition.x) * eased
                            let y = particle.startPosition.y + (particle.targetPosition.y - particle.startPosition.y) * eased

                            let position = CGPoint(x: x, y: y)

                            // Draw particle with glow effect (multiple layers for stronger glow)
                            let glowSize1 = particle.size * 4
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: position.x - glowSize1 / 2,
                                    y: position.y - glowSize1 / 2,
                                    width: glowSize1,
                                    height: glowSize1
                                )),
                                with: .color(particle.color.opacity(0.1))
                            )

                            let glowSize2 = particle.size * 2
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: position.x - glowSize2 / 2,
                                    y: position.y - glowSize2 / 2,
                                    width: glowSize2,
                                    height: glowSize2
                                )),
                                with: .color(particle.color.opacity(0.3))
                            )

                            // Bright core
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: position.x - particle.size / 2,
                                    y: position.y - particle.size / 2,
                                    width: particle.size,
                                    height: particle.size
                                )),
                                with: .color(particle.color)
                            )
                        }
                    }
                }
            }
            .onAppear {
                generateParticles(canvasSize: geometry.size)
                startAnimation()
            }
            .onChange(of: geometry.size) { _, newSize in
                if particles.isEmpty {
                    generateParticles(canvasSize: newSize)
                }
            }
        }
    }

    // MARK: - Particle Generation
    private func generateParticles(canvasSize: CGSize) {
        let renderer = ImageRenderer(content: Text(text).font(font).foregroundStyle(Color.white))
        renderer.scale = 2.0

        guard let image = renderer.cgImage else {
            print("Failed to generate image from text")
            return
        }

        let width = image.width
        let height = image.height

        print("Image size: \(width)x\(height), Canvas size: \(canvasSize)")

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("Failed to create CGContext")
            return
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            print("Failed to get pixel data")
            return
        }
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        var newParticles: [Particle] = []
        let samplingRate = 3 // Sample every 3rd pixel for better detail

        // Calculate centering offset
        let imageWidth = CGFloat(width) / renderer.scale
        let imageHeight = CGFloat(height) / renderer.scale
        let offsetX = (canvasSize.width - imageWidth) / 2
        let offsetY = (canvasSize.height - imageHeight) / 2

        for y in stride(from: 0, to: height, by: samplingRate) {
            for x in stride(from: 0, to: width, by: samplingRate) {
                let offset = (y * width + x) * 4
                let alpha = data[offset + 3]

                if alpha > 50 { // Lower threshold to catch more pixels
                    // Vary particle size for organic feel
                    let size = CGFloat.random(in: 1.5...2.5)

                    let particle = Particle(
                        targetPosition: CGPoint(
                            x: CGFloat(x) / renderer.scale + offsetX,
                            y: CGFloat(y) / renderer.scale + offsetY
                        ),
                        color: particleColor,
                        size: size,
                        canvasSize: canvasSize
                    )
                    newParticles.append(particle)
                }
            }
        }

        print("Generated \(newParticles.count) particles")
        particles = newParticles
    }

    // MARK: - Animation
    private func startAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        // Delay before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 2.5)) {
                animationProgress = 1.0
            }
        }
    }

    // Easing function
    private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let p = 2 * t - 2
            return 1 + p * p * p / 2
        }
    }
}

// MARK: - Interactive Demo View
struct ParticleTextDemo: View {
    @State private var currentText = "AFFLO"
    @State private var key = UUID()
    @State private var selectedColor: Color = .cyan

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Particle animation area
                ParticleTextView(
                    text: currentText,
                    font: .system(size: 60, weight: .black),
                    particleColor: selectedColor,
                    backgroundColor: .black
                )
                .id(key)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Controls
                VStack(spacing: 20) {
                    Text("Particle Text")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top)

                    // Text input
                    TextField("Enter text", text: $currentText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .onSubmit {
                            regenerate()
                        }

                    // Color picker
                    HStack {
                        Text("Color")
                            .foregroundStyle(.white)
                        Spacer()
                        ColorPicker("", selection: $selectedColor)
                    }
                    .padding(.horizontal)

                    // Preset colors
                    HStack(spacing: 15) {
                        ForEach([Color.cyan, Color.blue, Color.purple, Color.pink, Color.orange], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    regenerate()
                                }
                        }
                    }
                    .padding(.horizontal)

                    // Regenerate button
                    Button(action: regenerate) {
                        Text("Regenerate")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [selectedColor, selectedColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(height: 280)
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
    }

    private func regenerate() {
        key = UUID()
    }
}

// MARK: - Minimal Usage Example
struct MinimalParticleText: View {
    var body: some View {
        ParticleTextView(
            text: "HELLO",
            font: .system(size: 100, weight: .black),
            particleColor: Color(red: 0.32, green: 1.0, blue: 0.98),
            backgroundColor: .black
        )
    }
}

// MARK: - Previews
#Preview("Interactive Demo") {
    ParticleTextDemo()
}

#Preview("Minimal") {
    MinimalParticleText()
}
