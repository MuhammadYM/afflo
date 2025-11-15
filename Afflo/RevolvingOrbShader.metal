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

