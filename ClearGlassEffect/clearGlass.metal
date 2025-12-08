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

[[ stitchable ]] half4 clearGlass(float2 position, SwiftUI::Layer layer, float cornerRadius, float radius, float strength, float warp, float frost, float highlight, half4 chromaKey) {

    half4 currentPixel = layer.sample(position);

    // Check if chroma key is enabled (alpha > 0)
    bool useChromaKey = chromaKey.a > 0.5;

    bool isOnGlass;
    if (useChromaKey) {
        // Check if current pixel matches chroma key color (within tolerance)
        float colorDist = distance(currentPixel.rgb, chromaKey.rgb);
        isOnGlass = colorDist < 0.1 && currentPixel.a > 0.5;
    } else {
        // Use alpha channel
        isOnGlass = currentPixel.a > 0.5;
    }

    if (!isOnGlass) {
        return currentPixel;
    }

    // Find distance to nearest edge
    float edgeDistance = 50; // magic number which is larger than maximum radius
    float2 edgePosition = float2(0,0);

    for(int x = -radius; x <= radius; x++) {
        for(int y = -radius; y <= radius; y++) {
            float2 offset = float2(x,y);
            float2 testPosition = position + offset;
            half4 testPixel = layer.sample(testPosition);

            float distance = metal::distance(position, testPosition);

            bool isTestPixelGlass;
            if (useChromaKey) {
                // For chroma key: edge is where chroma transitions to TRANSPARENT only
                // Not where it transitions to other colors
                float testColorDist = metal::distance(testPixel.rgb, chromaKey.rgb);
                bool isChromaColor = testColorDist < 0.1 && testPixel.a > 0.5;
                bool isTransparent = testPixel.a < 0.5;

                // Edge is where we transition from chroma to transparent
                isTestPixelGlass = isChromaColor || !isTransparent;
            } else {
                // Use alpha channel
                isTestPixelGlass = testPixel.a > 0.5;
            }

            float newDistance = isTestPixelGlass
                            ? edgeDistance
                            : min(distance, edgeDistance);
            edgePosition = newDistance < edgeDistance
                            ? offset
                            : edgePosition;
            edgeDistance = newDistance;
        }
    }

    // Calculate surface normal based on edge direction
    // For individual letters, this creates a normal pointing toward the edge
    float2 surfaceNormal = edgeDistance < radius && length(edgePosition) > 0.0
                            ? normalize(edgePosition)
                            : normalize(position);
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

    // If using chroma key, the sampled color will be the chroma key color
    // We need to make it transparent so the background shows through
    if (useChromaKey) {
        float sampledColorDist = distance(refractedColor.rgb, chromaKey.rgb);
        if (sampledColorDist < 0.1 && refractedColor.a > 0.5) {
            // This pixel is the chroma key color, make it transparent
            // so the background image shows through with glass effect
            refractedColor = half4(0.0, 0.0, 0.0, 0.0);
        }
    }

    // Apply frosted glass effect across ENTIRE glass area using Gaussian blur
    if (frost > 0.0) {
        half4 blurredColor = half4(0.0);
        float frostRadius = frost * 40.0;
        float weightSum = 0.0;

        // Gaussian blur with proper weighting
        for(int y = -frostRadius/2; y <= frostRadius/2; y++) {
            for(int x = -frostRadius/2; x <= frostRadius/2; x++) {
                float2 offset = float2(x,y);
                float dist = length(offset);

                if(dist <= frostRadius) {
                    // Gaussian weight: e^(-(x^2 + y^2) / (2*sigma^2))
                    // Using cosine approximation for performance
                    float gauss = cos(float(x)/frostRadius) * cos(float(y)/frostRadius);
                    gauss = max(0.0, gauss); // Clamp to positive

                    half4 sample = layer.sample(readPosition + offset);

                    // Skip chroma key pixels in blur to avoid green bleeding
                    if (useChromaKey) {
                        float sampleColorDist = distance(sample.rgb, chromaKey.rgb);
                        if (sampleColorDist < 0.1 && sample.a > 0.5) {
                            // This is a chroma pixel, skip it
                            continue;
                        }
                    }

                    blurredColor += sample * gauss;
                    weightSum += gauss;
                }
            }
        }

        // Normalize by sum of weights for proper Gaussian
        if (weightSum > 0.0) {
            blurredColor /= weightSum;
            refractedColor = blurredColor;
        }
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

[[ stitchable ]] half4 blobMerge(float2 position, SwiftUI::Layer layer, float blurRadius, float threshold) {
    half4 currentPixel = layer.sample(position);

    // If blur radius is 0, just return the original pixel
    if (blurRadius <= 0.0) {
        return currentPixel;
    }

    // Apply Gaussian blur
    half4 blurredColor = half4(0.0);
    float weightSum = 0.0;

    for(int y = -blurRadius; y <= blurRadius; y++) {
        for(int x = -blurRadius; x <= blurRadius; x++) {
            float2 offset = float2(x, y);
            float dist = length(offset);

            if(dist <= blurRadius) {
                // Gaussian weight using cosine approximation
                float gauss = cos(float(x)/blurRadius) * cos(float(y)/blurRadius);
                gauss = max(0.0, gauss);

                half4 sample = layer.sample(position + offset);
                blurredColor += sample * gauss;
                weightSum += gauss;
            }
        }
    }

    // Normalize
    if (weightSum > 0.0) {
        blurredColor /= weightSum;
    }

    // Apply threshold to sharpen edges
    // If alpha is above threshold, make it fully opaque, otherwise transparent
    float alpha = blurredColor.a;
    if (alpha > threshold) {
        blurredColor.a = 1.0;
    } else {
        blurredColor.a = 0.0;
    }

    return blurredColor;
}
