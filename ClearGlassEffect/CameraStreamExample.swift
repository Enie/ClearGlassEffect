//
//  CameraStreamExample.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 10.12.25.
//

import SwiftUI

struct CameraStreamExample: View {
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let highlight: CGFloat

    @State private var stream = Stream()

    var body: some View {
        VStack {
            if stream.hasVideoAccess {
                if let frame = stream.streamFrame {
                    Image(frame, scale: 1.0, label: Text("Camera Feed"))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    Text("Loading camera...")
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Camera Access Required")
                        .font(.title)
                    Text("Please grant camera access in System Preferences")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(radius: glassRadius)
        .shadow(radius: glassRadius/2)
        .onAppear {
            // Configure glass effect parameters
            stream.glassCornerRadius = radius
            stream.glassRadius = glassRadius
            stream.glassStrength = strength
            stream.glassWarp = warp
            stream.glassHighlight = highlight

            stream.start()
        }
        .onDisappear {
            stream.stop()
        }
        .onChange(of: radius) { _, newValue in
            stream.glassCornerRadius = newValue * 5
        }
        .onChange(of: glassRadius) { _, newValue in
            stream.glassRadius = newValue * 20
        }
        .onChange(of: strength) { _, newValue in
            stream.glassStrength = newValue
        }
        .onChange(of: warp) { _, newValue in
            stream.glassWarp = newValue
        }
        .onChange(of: highlight) { _, newValue in
            stream.glassHighlight = newValue
        }
    }
}
