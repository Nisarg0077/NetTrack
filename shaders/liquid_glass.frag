#include <flutter/runtime_effect.glsl>

// =============================================================================
//  Apple Vision Pro / macOS Style Crystal-Clear Liquid Glass Shader
//  - 100% Grain-Free & Noise-Free (Pure harmonic calculus, zero noise texture)
//  - Crystal Transparency: Center is optical-clear so background blur is pristine
//  - Precision Curved Bevel: Mathematical Rounded-Box SDF normals
//  - Signature Crisp Apple Top Rim Specular Glint
//  - Interactive Silky Hydrodynamic Water Ripples & Velocity Wake
//  - 100% Loop-Free, Array-Free SkSL for Windows & Android Impeller
// =============================================================================

// === Uniforms ===
uniform vec2 u_resolution;       // Container size in pixels [0, 1]
uniform float u_time;            // Simulation time in seconds [2]
uniform vec2 u_touch;            // Interactive pointer location [3, 4]
uniform vec4 u_base_color;       // Base tint RGBA [5, 6, 7, 8]
uniform float u_intensity;       // Master optical intensity [9]
uniform float u_corner_radius;   // Border radius in pixels [10]
uniform vec2 u_velocity;         // Pointer velocity vector [11, 12]
uniform float u_fluid_viscosity; // Damping parameter [13]

out vec4 fragColor;

// 2D Rounded Rectangle Signed Distance Field
float sdRoundedBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Smooth harmonic liquid height field (Zero noise, zero grain)
float sampleLiquidHeight(vec2 p, vec2 res, float time, vec2 touch, vec2 vel) {
    vec2 uv = p / res;
    
    // 1. Gentle macroscopic breathing waves (smooth sinusoidal harmonics)
    float wave1 = sin(uv.x * 3.5 + time * 0.7) * cos(uv.y * 2.8 - time * 0.5);
    float wave2 = sin((uv.x + uv.y) * 3.0 - time * 0.4) * 0.5;
    float ambientFluid = (wave1 + wave2) * 0.06;
    
    // 2. Interactive Hydrodynamic Wave Propagation
    vec2 toTouch = p - touch;
    float r = length(toTouch);
    float speed = length(vel);
    
    // Clean damped sinusoidal water ripple:
    float ripple = sin(r * 0.065 - time * 7.5) * exp(-r * 0.016) * 0.45;
    
    // Velocity wake trailing behind moving pointer:
    vec2 velDir = (speed > 0.1) ? normalize(vel) : vec2(0.0);
    float alongWake = dot(-toTouch, velDir);
    float acrossWake = length(-toTouch - velDir * max(0.0, alongWake));
    float wake = exp(-acrossWake * acrossWake / (900.0 + speed * 15.0)) * 
                 exp(-max(0.0, -alongWake) / (45.0 + speed * 5.0)) * 
                 smoothstep(120.0 + speed * 8.0, 0.0, alongWake) * (speed * 0.025);
    
    // Center indentation & splash ring:
    float touchIndent = -exp(-r * r / 1600.0) * 0.5;
    float splashRing = exp(-pow(r - 36.0, 2.0) / 120.0) * 0.35;
    
    float interactiveWave = (ripple + wake + touchIndent + splashRing) * smoothstep(550.0, 0.0, r);
    
    return ambientFluid + interactiveWave;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 res = u_resolution;
    float time = u_time;
    
    // Exact Rounded Rectangle SDF
    vec2 center = res * 0.5;
    vec2 halfSize = res * 0.5;
    float radius = clamp(u_corner_radius, 0.0, min(halfSize.x, halfSize.y));
    float dist = sdRoundedBox(fragCoord - center, halfSize, radius);
    
    // Outside container bounds
    if (dist > 1.0) {
        fragColor = vec4(0.0);
        return;
    }
    
    // -------------------------------------------------------------------------
    // 1. Analytical Bevel Normal Calculation (Smooth, zero noise)
    // -------------------------------------------------------------------------
    const float eps = 1.0;
    float dX = sdRoundedBox(fragCoord + vec2(eps, 0.0) - center, halfSize, radius) -
               sdRoundedBox(fragCoord - vec2(eps, 0.0) - center, halfSize, radius);
    float dY = sdRoundedBox(fragCoord + vec2(0.0, eps) - center, halfSize, radius) -
               sdRoundedBox(fragCoord - vec2(0.0, eps) - center, halfSize, radius);
    vec2 edgeNormal = normalize(vec2(dX, dY) + vec2(1e-5));
    
    // 4.5px outer beveled edge
    float bevelWidth = 4.5;
    float edgeFactor = clamp(-dist / bevelWidth, 0.0, 1.0);
    float bevelSlope = (1.0 - edgeFactor);
    float bevelZ = sqrt(max(0.001, 1.0 - bevelSlope * bevelSlope));
    vec3 glassNormal = normalize(vec3(edgeNormal * bevelSlope * 2.4, bevelZ));
    
    // -------------------------------------------------------------------------
    // 2. Liquid Surface Ripple Normal (Central difference)
    // -------------------------------------------------------------------------
    float hL = sampleLiquidHeight(fragCoord - vec2(eps, 0.0), res, time, u_touch, u_velocity);
    float hR = sampleLiquidHeight(fragCoord + vec2(eps, 0.0), res, time, u_touch, u_velocity);
    float hD = sampleLiquidHeight(fragCoord - vec2(0.0, eps), res, time, u_touch, u_velocity);
    float hU = sampleLiquidHeight(fragCoord + vec2(0.0, eps), res, time, u_touch, u_velocity);
    vec2 rippleSlope = vec2(hR - hL, hU - hD) / (2.0 * eps);
    
    // Composite smooth normal: glass bevel at edge, liquid waves across body
    vec3 normal = glassNormal;
    normal.xy += rippleSlope * 1.6 * edgeFactor;
    normal = normalize(normal);
    
    // -------------------------------------------------------------------------
    // 3. Apple-Grade Optical Reflections & Glints
    // -------------------------------------------------------------------------
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    
    // A. Signature Crisp Top Rim Glint (The Apple glass white hairline highlight)
    float rimDepth = clamp(-dist / 2.8, 0.0, 1.0);
    float rimMask = (1.0 - rimDepth) * step(dist, 0.0);
    float topFacing = clamp(-edgeNormal.y, 0.0, 1.0);
    float topRim = pow(topFacing, 1.6) * rimMask * 1.0;
    
    // Subtle bottom ambient bounce glint
    float bottomFacing = clamp(edgeNormal.y, 0.0, 1.0);
    float bottomRim = pow(bottomFacing, 2.0) * rimMask * 0.22;
    
    // B. Studio Overhead Key Light Specular
    vec3 keyLightDir = normalize(vec3(-0.35, -0.65, 0.65));
    vec3 keyHalf = normalize(keyLightDir + viewDir);
    float keySpec = pow(max(0.0, dot(normal, keyHalf)), 48.0);
    
    // C. Total Internal Reflection (Fresnel) at grazing edges
    float NdotV = max(0.0, dot(normal, viewDir));
    float fresnel = pow(1.0 - NdotV, 3.5);
    
    // D. Interactive Touch Illumination & Water Glow
    vec2 toTouch = fragCoord - u_touch;
    float rTouch = length(toTouch);
    float touchGlow = exp(-rTouch * rTouch / 2400.0) * 0.75;
    float touchAura = exp(-rTouch * rTouch / 14000.0) * 0.25;
    float interactiveLight = (touchGlow + touchAura);
    
    // -------------------------------------------------------------------------
    // 4. Clean Composition (Crystal Transparent in Center)
    // -------------------------------------------------------------------------
    float intensity = clamp(u_intensity, 0.0, 1.0);
    vec3 baseCol = u_base_color.rgb;
    
    // Pure crystal highlights (clean white light + subtle tint blend)
    vec3 col = vec3(1.0, 1.0, 1.0) * (topRim + bottomRim);
    col += vec3(1.0, 1.0, 1.0) * keySpec * 0.85;
    col += mix(vec3(1.0), baseCol + vec3(0.2), 0.3) * interactiveLight * 0.85;
    col += mix(vec3(0.95, 0.98, 1.0), baseCol, 0.2) * fresnel * 0.4;
    col *= intensity;
    
    // Alpha transparency:
    // Notice: in the center, fresnel is 0, rim is 0, spec is 0.
    // So alpha is virtually 0 in center -> 100% CRYSTAL TRANSPARENT!
    // No noise, no dark veil, no grain!
    float alpha = 0.0;
    alpha += topRim * 0.85 * intensity;
    alpha += bottomRim * 0.25 * intensity;
    alpha += keySpec * 0.65 * intensity;
    alpha += fresnel * 0.30 * intensity;
    alpha += interactiveLight * 0.30 * intensity;
    
    // Subpixel border anti-aliasing
    float edgeAA = clamp(-dist, 0.0, 1.0);
    alpha *= edgeAA;
    alpha = clamp(alpha, 0.0, 1.0);
    
    // Pre-multiplied alpha output
    fragColor = vec4(col * alpha, alpha);
}
