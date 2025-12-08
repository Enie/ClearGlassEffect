//
//  ImageWithCornerRadiusExample.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 04.12.25.
//

import SwiftUI

struct ImageWithCornerRadiusExample: View {
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let frost: CGFloat
    let highlight: CGFloat

    var body: some View {
        VStack {
            Image("capybara")
                .resizable()
                .frame(width: 200, height: 200)
                .cornerRadius(radius)
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
        }
        .padding()
    }
}
