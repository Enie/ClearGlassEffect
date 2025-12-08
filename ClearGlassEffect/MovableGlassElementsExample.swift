//
//  MovableGlassElementsExample.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 04.12.25.
//

import SwiftUI

// Environment key to pass the background image
struct BackgroundImageKey: EnvironmentKey {
    static let defaultValue: Image? = nil
}

extension EnvironmentValues {
    var backgroundImage: Image? {
        get { self[BackgroundImageKey.self] }
        set { self[BackgroundImageKey.self] = newValue }
    }
}

struct TodoItem: Identifiable {
    let id = UUID()
    let text: String
    var isNew: Bool = false
}

struct MovableGlassElementsExample: View {
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let frost: CGFloat
    let highlight: CGFloat

    @State private var todoItems: [TodoItem] = [
        TodoItem(text: "Take a bath"),
        TodoItem(text: "Eat Yuzu"),
        TodoItem(text: "Befriend other animals")
    ]

    var body: some View {
        GeometryReader { geometry in
            GlassContainer(
                backgroundImage: Image("capybara"),
                radius: radius,
                glassRadius: glassRadius,
                strength: strength,
                warp: warp,
                frost: frost,
                highlight: highlight,
                chromaKeyColor: .green
            ) {
            VStack(spacing: 20) {
                Text("Todo List")
                    .font(.system(size: 36, weight: .bold))
                    .padding(.top, 40)
                    .foregroundStyle(.white)

                VStack(spacing: 12) {
                    ForEach(todoItems) { item in
                        HStack {
                            Text(item.text)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    todoItems.removeAll { $0.id == item.id }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .compositingGroup()
                        .background(Color.green)
                        .cornerRadius(radius)
                        .transition(.asymmetric(
                            insertion: item.isNew
                                ? .offset(y: -45)
                                : .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 40)

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        var newItem = TodoItem(text: "New Task \(todoItems.count + 1)")
                        newItem.isNew = true
                        todoItems.append(newItem)

                        // Reset isNew flag after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let index = todoItems.firstIndex(where: { $0.id == newItem.id }) {
                                todoItems[index].isNew = false
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Add Task")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(8)
                }
                .compositingGroup()
                .background(Color.green)
                .cornerRadius(radius)
                .padding(.top, 20)

                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct GlassContainer<Content: View>: View {
    let backgroundImage: Image
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let frost: CGFloat
    let highlight: CGFloat
    let chromaKeyColor: Color?
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
                        // Content on top with green chroma key
                        content
                            .compositingGroup()
                    }
//                    .compositingGroup() // Composite so shader sees both background and chroma
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

