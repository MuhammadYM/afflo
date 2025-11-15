#include <metal_stdlib>
using namespace metal;

// MARK: - Noise Functions
// Perlin-style noise for organic shapes
float hash(float2 p) {
    float3 p3 = fract(float3(p.x, p.y, p.x) * 0.13);
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion for more organic detail
float fbm(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// MARK: - Domain Warping Functions

// 2D rotation matrix
float2x2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2x2(c, -s, s, c);
}

// Enhanced FBM with rotation between octaves for more organic patterns
float fbm_with_rotation(float2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float2x2 m = rotate2D(0.5);

    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        p = m * p; // Rotate between octaves
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// Vector-returning FBM for domain warping
float2 fbm_vec(float2 p, int octaves) {
    float2 value = float2(0.0);
    float amplitude = 0.5;
    float frequency = 1.0;
    float2x2 m = rotate2D(0.5);

    for(int i = 0; i < octaves; i++) {
        value.x += amplitude * noise(p * frequency);
        value.y += amplitude * noise((p + float2(5.2, 1.3)) * frequency);
        p = m * p;
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return value;
}

// MARK: - Revolving Orb Shader
/// Creates an orb with organic, revolving shapes inside
/// Similar to the SVG with flowing, animated blob-like forms

[[ stitchable ]]
half4 revolvingOrb(float2 position,
                   half4 currentColor,
                   float2 size,
                   float time,
                   float speed,
                   float blobCount,
                   half4 color1,
                   half4 color2,
                   float complexity) {
    
    // Center position
    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);
    
    // Distance from center
    float dist = length(uv);
    
    // Create circular mask for the orb
    float orbRadius = 0.45;
    float orbMask = smoothstep(orbRadius + 0.05, orbRadius - 0.05, dist);
    
    // Create multiple revolving blobs
    float blobValue = 0.0;
    
    for(float i = 0.0; i < blobCount; i++) {
        // Each blob rotates at slightly different speed and offset
        float offset = i * (2.0 * M_PI_F / blobCount);
        float angle = time * speed + offset;
        
        // Revolving position
        float2 blobCenter = float2(
            cos(angle) * 0.15,
            sin(angle) * 0.15
        );
        
        // Add some wobble/organic motion
        float wobbleX = sin(time * speed * 1.3 + i) * 0.08;
        float wobbleY = cos(time * speed * 1.5 + i) * 0.08;
        blobCenter += float2(wobbleX, wobbleY);
        
        // Distance to blob center
        float2 toBlobCenter = uv - blobCenter;
        float blobDist = length(toBlobCenter);
        
        // Create organic blob shape using noise
        float angle2 = atan2(toBlobCenter.y, toBlobCenter.x);
        float noiseVal = fbm(float2(
            cos(angle2) * 3.0 + time * speed * 0.3,
            sin(angle2) * 3.0 + time * speed * 0.3
        ), int(complexity));
        
        // Blob size with organic variation
        float blobSize = 0.2 + noiseVal * 0.15;
        
        // Add blob contribution
        float blob = smoothstep(blobSize, blobSize - 0.1, blobDist);
        blobValue += blob;
    }
    
    // Clamp blob value
    blobValue = clamp(blobValue, 0.0, 1.0);
    
    // Add some overall rotation/swirl to the pattern
    float swirlAngle = atan2(uv.y, uv.x) + dist * 2.0 + time * speed * 0.2;
    float swirlNoise = fbm(float2(swirlAngle * 2.0, dist * 4.0 + time * speed * 0.5), 3);
    
    // Combine blob pattern with swirl
    float finalPattern = blobValue * 0.7 + swirlNoise * 0.3;
    
    // Create gradient based on pattern
    half4 orbColor = mix(color1, color2, half(finalPattern));
    
    // Add subtle glow effect at edges
    float edgeGlow = smoothstep(orbRadius - 0.1, orbRadius + 0.1, dist);
    orbColor = mix(orbColor, color2 * 1.3h, half(edgeGlow * 0.3));
    
    // Apply circular mask
    orbColor.a = half(orbMask);
    
    // Blend with original color
    return mix(currentColor, orbColor, orbColor.a);
}

// MARK: - Simplified Revolving Orb (Better Performance)
/// A more performant version with simpler calculations

[[ stitchable ]]
half4 simpleRevolvingOrb(float2 position,
                         half4 currentColor,
                         float2 size,
                         float time,
                         float speed,
                         half4 color1,
                         half4 color2) {
    
    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);
    float dist = length(uv);
    
    // Orb boundary
    float orbRadius = 0.45;
    float orbMask = smoothstep(orbRadius + 0.05, orbRadius - 0.05, dist);
    
    if(orbMask < 0.01) {
        return currentColor;
    }
    
    // Create 3 main revolving shapes (like the SVG)
    float shapeValue = 0.0;
    
    for(float i = 0.0; i < 3.0; i++) {
        // Rotation
        float offset = i * 2.094; // 120 degrees apart
        float angle = time * speed + offset;
        
        // Revolving position with elliptical orbit
        float2 shapePos = float2(
            cos(angle) * 0.18,
            sin(angle) * 0.12
        );
        
        // Add organic movement
        shapePos += float2(
            sin(time * speed * 1.4 + i * 2.0) * 0.06,
            cos(time * speed * 1.6 + i * 1.5) * 0.06
        );
        
        // Distance to shape
        float2 toShape = uv - shapePos;
        float shapeDist = length(toShape);
        
        // Create organic blob shape
        float shapeAngle = atan2(toShape.y, toShape.x);
        float shapeModulation = sin(shapeAngle * 3.0 + time * speed * 0.5) * 0.05;
        
        // Shape with smooth falloff
        float shapeSize = 0.25 + shapeModulation;
        float shape = smoothstep(shapeSize, shapeSize - 0.15, shapeDist);
        
        shapeValue = max(shapeValue, shape);
    }
    
    // Add rotating swirl pattern in background
    float swirlAngle = atan2(uv.y, uv.x) + time * speed * 0.3;
    float swirlPattern = sin(swirlAngle * 4.0 + dist * 8.0) * 0.5 + 0.5;
    swirlPattern *= (1.0 - dist * 1.5); // Fade with distance
    
    // Combine shape and swirl
    float finalPattern = shapeValue * 0.8 + swirlPattern * 0.2;
    finalPattern = clamp(finalPattern, 0.0, 1.0);
    
    // Apply gradient colors
    half4 orbColor = mix(color1, color2, half(finalPattern));
    
    // Add depth with radial gradient overlay
    float radialFade = 1.0 - (dist / orbRadius);
    orbColor = mix(orbColor * 0.7h, orbColor, half(radialFade));
    
    // Edge highlight
    float edgeHighlight = smoothstep(orbRadius - 0.15, orbRadius - 0.05, dist)
                        * smoothstep(orbRadius + 0.02, orbRadius - 0.02, dist);
    orbColor += half4(color2.rgb * edgeHighlight * 0.3, 0.0);
    
    orbColor.a = half(orbMask);
    
    return mix(currentColor, orbColor, orbColor.a);
}

// MARK: - Liquid Orb (Fluid Simulation Style)
/// Creates a more fluid, liquid-like effect inside the orb

[[ stitchable ]]
half4 liquidOrb(float2 position,
                half4 currentColor,
                float2 size,
                float time,
                float speed,
                float flowSpeed,
                half4 color1,
                half4 color2) {
    
    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);
    float dist = length(uv);
    
    float orbRadius = 0.45;
    float orbMask = smoothstep(orbRadius + 0.05, orbRadius - 0.05, dist);
    
    if(orbMask < 0.01) {
        return currentColor;
    }
    
    // Create flowing liquid effect
    float angle = atan2(uv.y, uv.x);
    
    // Multiple layers of flow
    float flow1 = sin(angle * 3.0 + time * speed - dist * 5.0) * 0.5 + 0.5;
    float flow2 = sin(angle * 5.0 - time * speed * 1.3 + dist * 3.0) * 0.5 + 0.5;
    float flow3 = sin(angle * 7.0 + time * speed * 0.7 - dist * 7.0) * 0.5 + 0.5;
    
    // Combine flows
    float liquidPattern = (flow1 * 0.4 + flow2 * 0.3 + flow3 * 0.3);
    
    // Add turbulence
    float turbulence = sin(uv.x * 10.0 + time * flowSpeed) *
                      cos(uv.y * 10.0 + time * flowSpeed * 1.2) * 0.1;
    liquidPattern += turbulence;
    
    // Add rotating blobs
    for(float i = 0.0; i < 3.0; i++) {
        float blobAngle = time * speed + i * 2.094;
        float2 blobPos = float2(cos(blobAngle) * 0.15, sin(blobAngle) * 0.15);
        float blobDist = length(uv - blobPos);
        float blob = smoothstep(0.2, 0.05, blobDist);
        liquidPattern = max(liquidPattern, blob);
    }
    
    liquidPattern = clamp(liquidPattern, 0.0, 1.0);
    
    // Apply colors
    half4 orbColor = mix(color1, color2, half(liquidPattern));
    
    // Add iridescent effect
    float iridescence = sin(liquidPattern * M_PI_F * 2.0 + time * speed * 0.5) * 0.2 + 0.8;
    orbColor.rgb *= half3(iridescence);
    
    // Vignette
    float vignette = 1.0 - (dist / orbRadius) * 0.5;
    orbColor.rgb *= half3(vignette);

    orbColor.a = half(orbMask);

    return mix(currentColor, orbColor, orbColor.a);
}

// MARK: - Simplified Domain Warp Orb
/// Single-layer domain warping for water-like flow effect
/// Optimized for smooth performance on all devices

[[ stitchable ]]
half4 simplifiedDomainWarpOrb(float2 position,
                               half4 currentColor,
                               float2 size,
                               float time,
                               float speed,
                               half4 color1,
                               half4 color2) {

    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);
    float dist = length(uv);

    // Circular mask
    float orbRadius = 0.45;
    float orbMask = smoothstep(orbRadius + 0.05, orbRadius - 0.05, dist);

    if(orbMask < 0.01) {
        return currentColor;
    }

    // Single-layer domain warping (q layer)
    // Scale UV for warping
    float2 warpUV = uv * 3.0;

    // Create warping offset with time-based animation
    float2 q = fbm_vec(warpUV + time * speed * 0.15, 18);

    // Apply warping to create distorted gradient
    float2 warpedUV = uv + q * 0.4;

    // Create flowing pattern using the warped coordinates
    float pattern = fbm_with_rotation(warpedUV * 4.0 + time * speed * 0.1, 20);

    // Add secondary flow for more complexity
    float angle = atan2(warpedUV.y, warpedUV.x);
    float radial = length(warpedUV);
    float flow = sin(angle * 3.0 + radial * 5.0 - time * speed * 0.5) * 0.5 + 0.5;

    // Combine pattern and flow
    float finalPattern = pattern * 0.6 + flow * 0.4;
    finalPattern = clamp(finalPattern, 0.0, 1.0);

    // Apply gradient
    half4 orbColor = mix(color1, color2, half(finalPattern));

    // Add depth with radial gradient
    float vignette = 1.0 - (dist / orbRadius) * 0.3;
    orbColor.rgb *= half3(vignette);

    // Subtle edge glow
    float edgeGlow = smoothstep(orbRadius - 0.1, orbRadius, dist);
    orbColor = mix(orbColor, color2 * 1.2h, half(edgeGlow * 0.15));

    orbColor.a = half(orbMask);

    return mix(currentColor, orbColor, orbColor.a);
}

// MARK: - Full Domain Warp Orb
/// Multi-layer domain warping (q → r → f) for complex water-like flow
/// Matches the reference implementation with nested warping layers

[[ stitchable ]]
half4 fullDomainWarpOrb(float2 position,
                        half4 currentColor,
                        float2 size,
                        float time,
                        float speed,
                        half4 color1,
                        half4 color2) {

    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);
    float dist = length(uv);

    // Circular mask
    float orbRadius = 0.45;
    float orbMask = smoothstep(orbRadius + 0.05, orbRadius - 0.05, dist);

    if(orbMask < 0.01) {
        return currentColor;
    }

    // Multi-layer domain warping (inspired by Book of Shaders Ch. 13)
    // Scale UV for warping
    float2 warpUV = uv * 3.0;

    // First warping layer (q) - base distortion
    float2 q = fbm_vec(warpUV + time * speed * 0.0, 15);

    // Second warping layer (r) - warp the warp using q
    float2 r = fbm_vec(warpUV + q * 4.0 + float2(1.7, 9.2) + time * speed * 0.15, 15);

    // Final pattern (f) - warp again using r
    float2 finalWarpedUV = uv + r * 0.5;

    // Create flowing pattern using the heavily warped coordinates
    float pattern = fbm_with_rotation(finalWarpedUV * 5.0 + time * speed * 0.126, 35);

    // Add additional detail from the warping layers themselves
    float qContribution = length(q) * 0.15;
    float rContribution = length(r) * 0.15;

    // Combine all layers
    float finalPattern = pattern * 0.7 + qContribution + rContribution;
    finalPattern = clamp(finalPattern, 0.0, 1.0);

    // Apply gradient
    half4 orbColor = mix(color1, color2, half(finalPattern));

    // Add depth and dimension
    float vignette = 1.0 - (dist / orbRadius) * 0.25;
    orbColor.rgb *= half3(vignette);

    // Enhanced edge with warped distortion
    float edgeDist = abs(dist - orbRadius);
    float edge = smoothstep(0.1, 0.0, edgeDist);
    float edgePattern = fbm_with_rotation(uv * 8.0 + r * 0.3 + time * speed * 0.1, 10);
    orbColor += half4(color2.rgb * edge * edgePattern * 0.2, 0.0);

    orbColor.a = half(orbMask);

    return mix(currentColor, orbColor, orbColor.a);
}

// MARK: - Layered Blob Orb
/// Three overlapping blob layers rotating in different directions
/// Matches the design - no circular border, organic wavy shape

[[ stitchable ]]
half4 layeredBlobOrb(float2 position,
                     half4 currentColor,
                     float2 size,
                     float time,
                     float speed,
                     half4 color1,
                     half4 color2) {

    float2 center = size * 0.5;
    float2 uv = (position - center) / min(size.x, size.y);

    // Three blob layers with different rotation speeds and directions
    float blob1 = 0.0;
    float blob2 = 0.0;
    float blob3 = 0.0;

    // Layer 1: Clockwise rotation
    {
        float angle1 = time * speed * 0.3;
        float2x2 rot1 = rotate2D(angle1);
        float2 rotatedUV = rot1 * uv;

        // Create organic blob with domain warping
        float2 warpOffset = fbm_vec(rotatedUV * 2.0 + time * speed * 0.1, 12);
        float2 warpedUV = rotatedUV + warpOffset * 0.3;

        // Distance with warped edges
        float d = length(warpedUV);
        blob1 = smoothstep(0.55, 0.2, d); // Large blob, soft edges
    }

    // Layer 2: Counter-clockwise rotation (opposite direction)
    {
        float angle2 = -time * speed * 0.25; // Negative for opposite direction
        float2x2 rot2 = rotate2D(angle2);
        float2 rotatedUV = rot2 * uv;

        // Different warp offset for variety
        float2 warpOffset = fbm_vec(rotatedUV * 2.5 + float2(5.2, 1.3) + time * speed * 0.12, 12);
        float2 warpedUV = rotatedUV + warpOffset * 0.35;

        float d = length(warpedUV);
        blob2 = smoothstep(0.5, 0.15, d);
    }

    // Layer 3: Slower clockwise rotation
    {
        float angle3 = time * speed * 0.18;
        float2x2 rot3 = rotate2D(angle3);
        float2 rotatedUV = rot3 * uv;

        float2 warpOffset = fbm_vec(rotatedUV * 2.2 + float2(2.8, 7.1) + time * speed * 0.08, 12);
        float2 warpedUV = rotatedUV + warpOffset * 0.28;

        float d = length(warpedUV);
        blob3 = smoothstep(0.52, 0.18, d);
    }

    // Combine blobs with overlay/max blending
    float combinedBlobs = max(blob1, max(blob2, blob3));

    // Add some flow between the layers
    float flowPattern = fbm_with_rotation(uv * 3.0 + time * speed * 0.15, 15);
    combinedBlobs = mix(combinedBlobs, combinedBlobs * flowPattern, 0.3);

    // Early exit if no blob visible
    if(combinedBlobs < 0.01) {
        return currentColor;
    }

    // Apply gradient based on blob intensity and position
    float gradientFactor = combinedBlobs * (0.5 + blob1 * 0.3 + blob2 * 0.2);
    half4 orbColor = mix(color1, color2, half(gradientFactor));

    // Add subtle internal variation
    float internalPattern = fbm_with_rotation(uv * 6.0 + time * speed * 0.2, 10);
    orbColor = mix(orbColor, orbColor * 1.1h, half(internalPattern * 0.2));

    // Use combined blob intensity as alpha (no circular mask)
    orbColor.a = half(combinedBlobs);

    return mix(currentColor, orbColor, orbColor.a);
}

