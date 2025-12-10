//
//  ClearGlassCIKernel.ci.metal
//  ClearGlassEffect
//
//  Created by Enie Weiß on 10.12.25.
//

using namespace metal;
#include <CoreImage/CoreImage.h>

// Helper function to calculate signed distance to rounded rectangle
// p: point position relative to center
// size: half-size (width/2, height/2) of the rectangle
// cornerRadius: radius of the rounded corners
float sdRoundedRect(float2 p, float2 size, float cornerRadius) {
    // Distance from point to the rectangle (without rounding)
    float2 q = abs(p) - size + cornerRadius;
    // Outside distance + inside distance - corner radius
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - cornerRadius;
}

extern "C" {
    namespace coreimage {
        float4 ciClearGlass(sampler src,
                            float radius,
                            float strength,
                            float warp,
                            float frost,
                            float highlight,
                            float cornerRadius,
                            float2 imageSize) {
            float2 position = src.coord();
            
            // Calculate position relative to center of image
            float2 center = imageSize * 0.5;
            float2 relativePos = position - center;
            
            // Calculate signed distance to the rounded rectangle edge
            float2 halfSize = imageSize * 0.5;
            float sdf = sdRoundedRect(relativePos, halfSize, cornerRadius);
            
            // If we're outside the rounded rectangle, return transparent
            if (sdf > 0.0) {
                return float4(0.0, 0.0, 0.0, 0.0);
            }
            
            // Edge distance is how far we are from the edge (sdf is negative inside, so abs gives distance)
            float edgeDistance = abs(sdf);
            
            // Default: sample without displacement
            float2 readPosition = position;
            
            // Only apply glass effect if we're within radius distance of the edge
            bool inGlassZone = edgeDistance <= radius;
            
            // Find nearest edge point (optimized for performance)
            float2 surfaceNormal = float2(0.0);
            if (inGlassZone) {
                float2 edgePosition = float2(0.0);
                float nearestEdgeDist = edgeDistance;

                // Adaptive search: smaller radius for better performance
                // Search only in the direction toward the edge
                int searchRadius = min(int(edgeDistance) + 5, 10);

                for (int y = -searchRadius; y <= searchRadius; y++) {
                    for (int x = -searchRadius; x <= searchRadius; x++) {
                        float2 offset = float2(x, y);
                        float offsetDist = length(offset);

                        if (offsetDist > float(searchRadius)) continue;

                        float2 testPos = position + offset;
                        float2 testRelativePos = testPos - center;
                        float testSdf = sdRoundedRect(testRelativePos, halfSize, cornerRadius);

                        // Find point closer to the edge (sdf closer to 0)
                        if (abs(testSdf) < nearestEdgeDist) {
                            nearestEdgeDist = abs(testSdf);
                            edgePosition = offset;
                        }
                    }
                }

                if (length(edgePosition) > 0.0) {
                    // Keep original direction (toward edge) for highlight calculation
                    surfaceNormal = normalize(edgePosition);
                }
            }

            // Apply refraction near edges (when we're within radius distance of the edge)
            if (inGlassZone && length(surfaceNormal) > 0.0) {
                float refractionFalloff = pow(1.0 - edgeDistance / radius, 2.0);
                float refractionMultiplier = 1.0 + warp;
                // Invert normal for displacement (point inward) to avoid out-of-bounds sampling
                float2 displacementNormal = -surfaceNormal;
                float2 displacement = displacementNormal * strength * refractionFalloff * radius * refractionMultiplier;
                readPosition += displacement;
            }
            
            // Sample refracted color
            float4 refractedColor = src.sample(readPosition);
            
            // Edge highlights
            if (highlight > 0.0 && inGlassZone && length(surfaceNormal) > 0.0) {
                float edgeHighlight = pow(1.0 - edgeDistance / radius, 3.0);
                float lightAngle = atan2(surfaceNormal.y, surfaceNormal.x);
                float lightDirection = 0.785;
                float angleDiff = abs(lightAngle - lightDirection);
                float fresnel = 1.0 - cos(angleDiff);
                
                float3 highlightColor = float3(1.0, 1.0, 1.0);
                float highlightStrength = edgeHighlight * fresnel * highlight * 0.5;
                
                refractedColor.rgb = mix(refractedColor.rgb, highlightColor, highlightStrength);
            }
            
            // Ensure we preserve full opacity for pixels inside the shape
            refractedColor.a = 1.0;
            
            return refractedColor;
        }
    }
}
