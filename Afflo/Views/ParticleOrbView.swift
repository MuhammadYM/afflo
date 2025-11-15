import SwiftUI

// MARK: - Particle Orb View
/// Creates a beautiful particle orb with elegantly flowing particles
/// Particles move smoothly within a confined spherical boundary

struct ParticleOrbView: View {
    let particleCount: Int
    let orbRadius: CGFloat
    let particleColor: Color
    let backgroundColor: Color
    let flowSpeed: Double

    @State private var particles: [OrbParticle] = []
    @State private var startTime = Date()

    init(
        particleCount: Int = 2000,
        orbRadius: CGFloat = 150,
        particleColor: Color = .white,
        backgroundColor: Color = .black,
        flowSpeed: Double = 0.3
    ) {
        self.particleCount = particleCount
        self.orbRadius = orbRadius
        self.particleColor = particleColor
        self.backgroundColor = backgroundColor
        self.flowSpeed = flowSpeed
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startTime)
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)

                        for particle in particles {
                            // Calculate flowing position within orb
                            let position = calculateParticlePosition(
                                particle: particle,
                                time: elapsed,
                                center: center
                            )

                            // Multi-layer glow effect
                            let glowSize1 = particle.size * 4
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: position.x - glowSize1 / 2,
                                    y: position.y - glowSize1 / 2,
                                    width: glowSize1,
                                    height: glowSize1
                                )),
                                with: .color(particle.color.opacity(0.08))
                            )

                            let glowSize2 = particle.size * 2
                            context.fill(
                                Path(ellipseIn: CGRect(
                                    x: position.x - glowSize2 / 2,
                                    y: position.y - glowSize2 / 2,
                                    width: glowSize2,
                                    height: glowSize2
                                )),
                                with: .color(particle.color.opacity(0.25))
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
                generateOrbParticles(canvasSize: geometry.size)
                startTime = Date()
            }
            .onChange(of: geometry.size) { _, newSize in
                if particles.isEmpty {
                    generateOrbParticles(canvasSize: newSize)
                    startTime = Date()
                }
            }
        }
    }

    // MARK: - Particle Generation
    private func generateOrbParticles(canvasSize: CGSize) {
        var newParticles: [OrbParticle] = []

        for _ in 0..<particleCount {
            // Generate random point within sphere using spherical coordinates
            let theta = CGFloat.random(in: 0...(2 * .pi))
            let phi = acos(CGFloat.random(in: -1...1))
            let r = orbRadius * pow(CGFloat.random(in: 0...1), 1.0/3.0)

            // Convert to Cartesian coordinates (initial position in orb)
            let x = r * sin(phi) * cos(theta)
            let y = r * sin(phi) * sin(theta)

            // Random flow parameters for elegant movement
            let flowAngle = CGFloat.random(in: 0...(2 * .pi))
            let flowSpeed = CGFloat.random(in: 0.5...1.5)
            let phaseOffset = CGFloat.random(in: 0...(2 * .pi))

            // Vary particle size
            let size = CGFloat.random(in: 1.2...2.5)

            let particle = OrbParticle(
                baseX: x,
                baseY: y,
                flowAngle: flowAngle,
                flowSpeed: flowSpeed,
                phaseOffset: phaseOffset,
                color: particleColor,
                size: size
            )
            newParticles.append(particle)
        }

        print("Generated \(newParticles.count) flowing orb particles")
        particles = newParticles
    }

    // MARK: - Particle Position Calculation
    private func calculateParticlePosition(particle: OrbParticle, time: Double, center: CGPoint) -> CGPoint {
        let t = CGFloat(time) * CGFloat(flowSpeed) * particle.flowSpeed

        // Create elegant flowing motion using sine waves
        let flowX = sin(t + particle.phaseOffset) * 8 * cos(particle.flowAngle)
        let flowY = cos(t + particle.phaseOffset * 1.3) * 8 * sin(particle.flowAngle)

        // Add orbital rotation
        let rotationSpeed = 0.1
        let angle = t * CGFloat(rotationSpeed)
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)

        // Rotate the base position slightly
        let rotatedX = particle.baseX * cosAngle - particle.baseY * sinAngle
        let rotatedY = particle.baseX * sinAngle + particle.baseY * cosAngle

        // Combine base position with flow
        var x = rotatedX + flowX
        var y = rotatedY + flowY

        // Constrain to orb boundary (soft constraint)
        let dist = sqrt(x * x + y * y)
        if dist > orbRadius {
            let scale = orbRadius / dist
            x *= scale * 0.98 // Slightly inside boundary
            y *= scale * 0.98
        }

        return CGPoint(
            x: center.x + x,
            y: center.y + y
        )
    }
}

// MARK: - Orb Particle Model
struct OrbParticle: Identifiable {
    let id = UUID()
    let baseX: CGFloat // Base position in orb-relative coordinates
    let baseY: CGFloat
    let flowAngle: CGFloat // Direction of flow movement
    let flowSpeed: CGFloat // Speed multiplier for this particle
    let phaseOffset: CGFloat // Phase offset for sine waves
    let color: Color
    let size: CGFloat

    init(
        baseX: CGFloat,
        baseY: CGFloat,
        flowAngle: CGFloat,
        flowSpeed: CGFloat,
        phaseOffset: CGFloat,
        color: Color,
        size: CGFloat
    ) {
        self.baseX = baseX
        self.baseY = baseY
        self.flowAngle = flowAngle
        self.flowSpeed = flowSpeed
        self.phaseOffset = phaseOffset
        self.color = color
        self.size = size
    }
}

// MARK: - Interactive Demo
struct ParticleOrbDemo: View {
    @State private var key = UUID()
    @State private var particleCount: Double = 2000
    @State private var orbRadius: Double = 150
    @State private var selectedColor: Color = .white
    @State private var flowSpeed: Double = 0.3

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Particle orb animation area
                ParticleOrbView(
                    particleCount: Int(particleCount),
                    orbRadius: orbRadius,
                    particleColor: selectedColor,
                    backgroundColor: .black,
                    flowSpeed: flowSpeed
                )
                .id(key)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Controls
                VStack(spacing: 20) {
                    Text("Particle Orb")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.top)

                    ScrollView {
                        VStack(spacing: 15) {
                            // Particle count
                            VStack(alignment: .leading) {
                                Text("Particles: \(Int(particleCount))")
                                    .foregroundStyle(.white)
                                Slider(value: $particleCount, in: 500...4000, step: 100)
                            }

                            // Orb radius
                            VStack(alignment: .leading) {
                                Text("Radius: \(Int(orbRadius))")
                                    .foregroundStyle(.white)
                                Slider(value: $orbRadius, in: 80...200)
                            }

                            // Flow speed
                            VStack(alignment: .leading) {
                                Text("Flow Speed: \(String(format: "%.1f", flowSpeed))")
                                    .foregroundStyle(.white)
                                Slider(value: $flowSpeed, in: 0.1...1.0, step: 0.1)
                            }

                            // Preset colors
                            HStack(spacing: 15) {
                                ForEach([Color.white, Color.cyan, Color.blue, Color.purple, Color.pink], id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }

                            // Color picker
                            HStack {
                                Text("Custom Color")
                                    .foregroundStyle(.white)
                                Spacer()
                                ColorPicker("", selection: $selectedColor)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 200)

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
                .frame(height: 350)
                .background(Color(.systemBackground).opacity(0.95))
            }
        }
    }

    private func regenerate() {
        key = UUID() // This will recreate the ParticleOrbView, resetting startTime
    }
}

// MARK: - Minimal Usage
struct MinimalParticleOrb: View {
    var body: some View {
        ParticleOrbView(
            particleCount: 2000,
            orbRadius: 150,
            particleColor: .white,
            backgroundColor: .black,
            flowSpeed: 0.3
        )
    }
}

// MARK: - Previews
#Preview("Orb Demo") {
    ParticleOrbDemo()
}

#Preview("Minimal Orb") {
    MinimalParticleOrb()
}
