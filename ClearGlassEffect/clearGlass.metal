//
//  clear_glass.metal
//  ClearGlassEffect
//
//  Created by Enie Weiß on 04.12.25.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

float2 rotateAroundPoint(float2 point2, float2 point1, float theta) {
    float2 translated = point2 - point1;

    float cosTheta = cos(theta);
    float sinTheta = sin(theta);

    float2 rotated;
    rotated.x = translated.x * cosTheta - translated.y * sinTheta;
    rotated.y = translated.x * sinTheta + translated.y * cosTheta;

    return rotated + point1;
}

[[ stitchable ]] half4 clearGlass(float2 position, SwiftUI::Layer layer, float cornerRadius, float radius, float strength, float warp, float frost, float highlight, float2 size) {

    float edgeDistance = size.x;
    float2 edgePosition = float2(0,0);

    for(int x = -radius; x <= radius; x++) {
        for(int y = -radius; y <= radius; y++) {
            float2 offset = float2(x,y);
            float2 testPosition = position + offset;

            float distance = metal::distance(position, testPosition);
            float isOpaque = layer.sample(testPosition).a > 0.5;
            float newDistance = isOpaque
                            ? edgeDistance
                            : min(distance,edgeDistance);
            edgePosition = newDistance < edgeDistance
                            ? offset
                            : edgePosition;
            edgeDistance = newDistance;
        }
    }

    bool isOnGlass = layer.sample(position).a > 0.5;

    if (!isOnGlass) {
        return layer.sample(position);
    }

    float2 centerToPixel = position - size/2.0;
    float2 surfaceNormal = normalize(centerToPixel);
    float2 readPosition = position;

    // Apply refraction only near edges
    if (edgeDistance <= radius) {
        // Calculate refraction amount based on distance from edge
        float refractionFalloff = pow(1.0 - edgeDistance / radius, 2.0);

        // Warp multiplier - increases the effective refractive index
        float refractionMultiplier = 1.0 + warp;

        // Apply refraction displacement along the surface normal
        float2 displacement = surfaceNormal * strength * refractionFalloff * radius * refractionMultiplier;
        readPosition += displacement;
    }

    // Sample the refracted color
    half4 refractedColor = layer.sample(readPosition);

    // Apply frosted glass effect across ENTIRE glass area
    if (frost > 0.0) {
        // Create grainy noise pattern for frosted texture
        float noise = fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453);
        float noise2 = fract(sin(dot(position, float2(93.9898, 67.345))) * 28653.1234);

        // Use noise to create random sample offsets for grainy blur
        half4 blurredColor = half4(0.0);
        float frostRadius = frost * 20.0;
        int samples = 0;

        // Fewer samples but with random jitter for grain
        for(float fx = -frostRadius; fx <= frostRadius; fx += 2.0) {
            for(float fy = -frostRadius; fy <= frostRadius; fy += 2.0) {
                // Add random jitter to sample positions for grain
                float jitterX = fract(sin(fx * noise + fy * noise2) * 43758.5) * 2.0 - 1.0;
                float jitterY = fract(sin(fy * noise2 + fx * noise) * 28653.1) * 2.0 - 1.0;

                float2 frostOffset = float2(fx + jitterX, fy + jitterY);
                if (length(frostOffset) <= frostRadius) {
                    blurredColor += layer.sample(readPosition + frostOffset);
                    samples++;
                }
            }
        }

        blurredColor /= float(samples);

        // Add subtle grain to the final result
        float grain = (noise - 0.5) * 0.05 * frost;
        refractedColor = mix(refractedColor, blurredColor, frost);
        refractedColor.rgb += half3(grain);
    }

    // Add specular highlight on the edge only
    if (highlight > 0.0 && edgeDistance <= radius) {
        float edgeHighlight = pow(1.0 - edgeDistance / radius, 3.0);

        float lightAngle = atan2(surfaceNormal.y, surfaceNormal.x);
        float lightDirection = 0.785;
        float angleDiff = abs(lightAngle - lightDirection);
        float fresnel = 1.0 - cos(angleDiff);

        half3 highlightColor = half3(1.0, 1.0, 1.0);
        float highlightStrength = edgeHighlight * fresnel * highlight * 0.5;

        refractedColor.rgb = mix(refractedColor.rgb, highlightColor, highlightStrength);
    }

    return refractedColor;
}
