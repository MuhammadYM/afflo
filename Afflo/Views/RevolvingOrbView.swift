import SwiftUI

// MARK: - Revolving Orb View
/// An animated orb with organic shapes revolving inside
/// Recreates the effect from the SVG with flowing, blob-like forms

struct RevolvingOrbView: View {
    // MARK: - Animation State
    @State private var startTime = Date.now
    
    // MARK: - Customization Properties
    var orbSize: CGFloat = 300
    var speed: CGFloat = 0.5
    var blobCount: CGFloat = 3
    var complexity: CGFloat = 3
    var color1: Color = Color(red: 0.33, green: 0.51, blue: 1.0) // #5481FF
    var color2: Color = Color(red: 0.32, green: 1.0, blue: 0.98) // #51FFF9
    var animationStyle: OrbAnimationStyle = .layeredBlob
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(startTime.distance(to: timeline.date))
            
            Circle()
                .fill(.white)
                .frame(width: orbSize, height: orbSize)
                .colorEffect(getShader(elapsedTime: elapsedTime))
        }
    }
    
    private func getShader(elapsedTime: Float) -> Shader {
        switch animationStyle {
        case .complex:
            return ShaderLibrary.revolvingOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .float(blobCount),
                .color(color1),
                .color(color2),
                .float(complexity)
            )
        case .simple:
            return ShaderLibrary.simpleRevolvingOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .liquid:
            return ShaderLibrary.liquidOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .float(speed * 2),
                .color(color1),
                .color(color2)
            )
        case .simplifiedDomainWarp:
            return ShaderLibrary.simplifiedDomainWarpOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .fullDomainWarp:
            return ShaderLibrary.fullDomainWarpOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .layeredBlob:
            return ShaderLibrary.layeredBlobOrb(
                .float2(orbSize, orbSize),
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        }
    }
}

// MARK: - Animation Style
enum OrbAnimationStyle {
    case simple                 // Best performance, smooth revolving blobs
    case complex                // More detail with noise, slightly heavier
    case liquid                 // Fluid, flowing effect
    case simplifiedDomainWarp   // Single-layer domain warping, water-like flow
    case fullDomainWarp         // Multi-layer domain warping, complex water effect
    case layeredBlob            // Three overlapping blobs, no border - matches design
}

// MARK: - Revolving Orb Modifier
/// View modifier to add the revolving orb effect to any view
struct RevolvingOrbModifier: ViewModifier {
    let speed: CGFloat
    let color1: Color
    let color2: Color
    let style: OrbAnimationStyle
    @State private var startTime = Date.now
    
    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = Float(startTime.distance(to: timeline.date))
            
            content
                .colorEffect(getShader(elapsedTime: elapsedTime))
        }
    }
    
    private func getShader(elapsedTime: Float) -> Shader {
        switch style {
        case .simple:
            return ShaderLibrary.simpleRevolvingOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .complex:
            return ShaderLibrary.revolvingOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .float(3),
                .color(color1),
                .color(color2),
                .float(3)
            )
        case .liquid:
            return ShaderLibrary.liquidOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .float(speed * 2),
                .color(color1),
                .color(color2)
            )
        case .simplifiedDomainWarp:
            return ShaderLibrary.simplifiedDomainWarpOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .fullDomainWarp:
            return ShaderLibrary.fullDomainWarpOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        case .layeredBlob:
            return ShaderLibrary.layeredBlobOrb(
                .boundingRect,
                .float(elapsedTime),
                .float(speed),
                .color(color1),
                .color(color2)
            )
        }
    }
}

extension View {
    /// Adds a revolving orb effect to the view
    /// - Parameters:
    ///   - speed: Animation speed multiplier (default: 0.5)
    ///   - color1: First gradient color (default: blue #5481FF)
    ///   - color2: Second gradient color (default: cyan #51FFF9)
    ///   - style: Animation style (default: .simple)
    func revolvingOrb(
        speed: CGFloat = 0.5,
        color1: Color = Color(red: 0.33, green: 0.51, blue: 1.0),
        color2: Color = Color(red: 0.32, green: 1.0, blue: 0.98),
        style: OrbAnimationStyle = .simple
    ) -> some View {
        modifier(RevolvingOrbModifier(speed: speed, color1: color1, color2: color2, style: style))
    }
}

// MARK: - Demo View with Controls
struct RevolvingOrbDemo: View {
    @State private var speed: CGFloat = 0.5
    @State private var orbSize: CGFloat = 300
    @State private var blobCount: CGFloat = 3
    @State private var complexity: CGFloat = 3
    @State private var selectedStyle: OrbAnimationStyle = .layeredBlob
    @State private var useCustomColors = false
    @State private var customColor1 = Color(red: 0.33, green: 0.51, blue: 1.0)
    @State private var customColor2 = Color(red: 0.32, green: 1.0, blue: 0.98)
    
    var body: some View {
        VStack(spacing: 0) {
            // Orb Display Area
            ZStack {
                // Dark background to showcase the orb
                Color.black
                    .ignoresSafeArea()
                
                RevolvingOrbView(
                    orbSize: orbSize,
                    speed: speed,
                    blobCount: blobCount,
                    complexity: complexity,
                    color1: useCustomColors ? customColor1 : Color(red: 0.33, green: 0.51, blue: 1.0),
                    color2: useCustomColors ? customColor2 : Color(red: 0.32, green: 1.0, blue: 0.98),
                    animationStyle: selectedStyle
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Control Panel
            VStack(spacing: 20) {
                Text("Revolving Orb Controls")
                    .font(.headline)
                    .padding(.top)
                
                // Style Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Style")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Style", selection: $selectedStyle) {
                        Text("Layered Blob (Design Match)").tag(OrbAnimationStyle.layeredBlob)
                        Text("Simple").tag(OrbAnimationStyle.simple)
                        Text("Complex").tag(OrbAnimationStyle.complex)
                        Text("Liquid").tag(OrbAnimationStyle.liquid)
                        Text("Domain Warp (Simple)").tag(OrbAnimationStyle.simplifiedDomainWarp)
                        Text("Domain Warp (Full)").tag(OrbAnimationStyle.fullDomainWarp)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Speed Control
                        VStack(alignment: .leading) {
                            Text("Speed: \(String(format: "%.2f", speed))")
                            Slider(value: $speed, in: 0.1...2.0)
                        }
                        
                        // Size Control
                        VStack(alignment: .leading) {
                            Text("Size: \(Int(orbSize))")
                            Slider(value: $orbSize, in: 100...400)
                        }
                        
                        if selectedStyle == .complex {
                            // Blob Count (Complex only)
                            VStack(alignment: .leading) {
                                Text("Blob Count: \(Int(blobCount))")
                                Slider(value: $blobCount, in: 2...6, step: 1)
                            }
                            
                            // Complexity (Complex only)
                            VStack(alignment: .leading) {
                                Text("Complexity: \(Int(complexity))")
                                Slider(value: $complexity, in: 2...5, step: 1)
                            }
                        }
                        
                        // Color Customization
                        Toggle("Custom Colors", isOn: $useCustomColors)
                        
                        if useCustomColors {
                            HStack {
                                ColorPicker("Color 1", selection: $customColor1)
                                ColorPicker("Color 2", selection: $customColor2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 300)
            }
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Simple Integration Example
struct SimpleOrbExample: View {
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // The revolving orb
                RevolvingOrbView(orbSize: 250)
                
                // Your UI elements
                VStack(spacing: 20) {
                    Text("Sign Up")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Button(action: {}) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.33, green: 0.51, blue: 1.0),
                                        Color(red: 0.32, green: 1.0, blue: 0.98)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Multiple Orbs Example
struct MultipleOrbsExample: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background orb (slower)
            RevolvingOrbView(
                orbSize: 400,
                speed: 0.3,
                color1: Color.blue.opacity(0.3),
                color2: Color.cyan.opacity(0.3),
                animationStyle: .liquid
            )
            .blur(radius: 20)
            
            // Main orb
            RevolvingOrbView(
                orbSize: 250,
                speed: 0.5,
                animationStyle: .simple
            )
            
            // Foreground content
            VStack {
                Spacer()
                Text("Layered Orb Effects")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }
        }
    }
}

// MARK: - Button with Orb Background
struct OrbButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Orb background
                RevolvingOrbView(
                    orbSize: 200,
                    speed: 0.4,
                    animationStyle: .liquid
                )
                
                // Button text
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 200, height: 200)
    }
}

// MARK: - Previews
#Preview("Demo with Controls") {
    RevolvingOrbDemo()
}

#Preview("Simple Integration") {
    SimpleOrbExample()
}

#Preview("Multiple Orbs") {
    MultipleOrbsExample()
}

#Preview("Orb Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        OrbButton(title: "Click Me") {
            print("Orb button tapped!")
        }
    }
}
