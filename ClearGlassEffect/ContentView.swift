//
//  ContentView.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 04.12.25.
//

import SwiftUI

struct ContentView: View {
    let startDate = Date()
    @State var radius: CGFloat = 100
    @State var glassRadius: CGFloat = 5
    @State var strength: CGFloat = 0
    @State var warp: CGFloat = 0
    @State var frost: CGFloat = 0
    @State var highlight: CGFloat = 0
    @State var shadow: CGFloat = 0
    
    var body: some View {
        VStack {
            Image("capybara")
                .resizable()
                .frame(width: 200, height: 200)
                .cornerRadius(radius)
                .layerEffect(ShaderLibrary.clearGlass(.float(radius),.float(glassRadius), .float(strength), .float(warp), .float(frost), .float(highlight), .float2(200,200)), maxSampleOffset: CGSize(width: abs(glassRadius * strength), height: abs(glassRadius * strength)))
                .padding(32)
                .shadow(radius: shadow*12, x: shadow*6, y: shadow*6)
                .shadow(radius: shadow*6, x: shadow*3, y: shadow*3)
            Slider(value: $radius, in: 0...100.0) {
                Text("radius")
            }
            .frame(width: 200)
            Slider(value: $glassRadius, in: 0...15.0) {
                Text("glass radius")
            }
            .frame(width: 200)
            Slider(value: $strength, in: -2...0.1) {
                Text("strength")
            }
            .frame(width: 200)
            Slider(value: $warp, in: 0...1) {
                Text("warp")
            }
            .frame(width: 200)
            Slider(value: $frost, in: 0...1) {
                Text("frost")
            }
            .frame(width: 200)
            Slider(value: $highlight, in: 0...1) {
                Text("highlight")
            }
            .frame(width: 200)
            Slider(value: $shadow, in: 0...1) {
                Text("shadow")
            }
            .frame(width: 200)

        }
        .padding()
    }
}

#Preview {
    ContentView()
}
