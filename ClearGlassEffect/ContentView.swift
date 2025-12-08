//
//  ContentView.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 04.12.25.
//

import SwiftUI

enum ExampleType: String, CaseIterable {
    case imageWithCornerRadius = "Image with Corner Radius"
    case textWithImage = "Text with Image"
    case glassUI = "Glass UI (Todo List)"
}

struct ContentView: View {
    let startDate = Date()
    @State var radius: CGFloat = 100
    @State var glassRadius: CGFloat = 5
    @State var strength: CGFloat = 2.0
    @State var warp: CGFloat = 0.25
    @State var frost: CGFloat = 0
    @State var highlight: CGFloat = 0.5
    @State var blobMerge: CGFloat = 4
    @State var selectedExample: ExampleType = .imageWithCornerRadius

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Picker("Example", selection: $selectedExample) {
                        ForEach(ExampleType.allCases, id: \.self) { example in
                            Text(example.rawValue).tag(example)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Divider()
                    
                    Slider(value: $radius, in: 0...100.0) {
                        Text("Corner Radius")
                    }
                    
                    Slider(value: $glassRadius, in: 0...15.0) {
                        Text("Glass Radius")
                    }
                    
                    Slider(value: $strength, in: 0.1...3) {
                        Text("Strength")
                    }
                    
                    Slider(value: $warp, in: 0...1) {
                        Text("Warp")
                    }
                    
                    Slider(value: $frost, in: 0...1) {
                        Text("Frost")
                    }
                    
                    Slider(value: $highlight, in: 0...1) {
                        Text("Highlight")
                    }

                    if selectedExample == .glassUI {
                        Slider(value: $blobMerge, in: 0...15) {
                            Text("Blob Merge")
                        }
                    }

                    Button("Randomize") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                            radius = CGFloat.random(in: 0...100)
                            glassRadius = CGFloat.random(in: 0...15)
                            strength = CGFloat.random(in: 0.1...3)
                            warp = CGFloat.random(in: 0...1)
                            frost = CGFloat.random(in: 0...1)
                            highlight = CGFloat.random(in: 0...1)
                        }
                    }
                }
                Spacer()
            }
            .frame(width: 240)
            .padding()
            .listStyle(.sidebar)

            VStack(spacing: 0) {
                switch selectedExample {
                case .imageWithCornerRadius:
                    ImageWithCornerRadiusExample(
                        radius: radius,
                        glassRadius: glassRadius,
                        strength: strength,
                        warp: warp,
                        frost: frost,
                        highlight: highlight
                    )
                case .textWithImage:
                    TextWithImageExample(
                        radius: radius,
                        glassRadius: glassRadius,
                        strength: strength,
                        warp: warp,
                        frost: frost,
                        highlight: highlight
                    )
                case .glassUI:
                    MovableGlassElementsExample(
                        radius: radius,
                        glassRadius: glassRadius,
                        strength: strength,
                        warp: warp,
                        frost: frost,
                        highlight: highlight,
                        blobMerge: blobMerge
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
