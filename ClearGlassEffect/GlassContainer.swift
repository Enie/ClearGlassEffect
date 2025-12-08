//
//  GlassContainer.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 08.12.25.
//

import SwiftUI

struct GlassContainer<Content: View>: View {
    let backgroundImage: Image
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let frost: CGFloat
    let highlight: CGFloat
    let chromaKeyColor: Color?
    let blobMergeRadius: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-size background image - stays visible
                backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Render background again for the shader to sample from
                backgroundImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .mask {
                        content
                            .compositingGroup()
                            .blur(radius: blobMergeRadius)
                    }
                    .layerEffect(
                        ShaderLibrary.clearGlass(
                            .float(radius),
                            .float(glassRadius),
                            .float(-strength),
                            .float(warp),
                            .float(frost),
                            .float(highlight),
                            .color(.clear)
                        ),
                        maxSampleOffset: CGSize(width: abs(glassRadius * strength), height: abs(glassRadius * strength))
                    )
                    .shadow(radius: glassRadius, x: glassRadius/2, y: glassRadius/2)
                    .shadow(radius: glassRadius/2, x: glassRadius/4, y: glassRadius/4)
                // Chroma key detection layer with optional blob merging
                content
                    .layerEffect(
                        ShaderLibrary.clearGlass(
                            .float(radius),
                            .float(glassRadius),
                            .float(-strength),
                            .float(warp),
                            .float(frost),
                            .float(highlight),
                            .color(chromaKeyColor ?? .clear)
                        ),
                        maxSampleOffset: CGSize(width: abs(glassRadius * strength), height: abs(glassRadius * strength))
                    )
            }
        }
    }
}
