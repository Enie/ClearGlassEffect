//
//  VideoWithGlassExample.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 08.12.25.
//

import SwiftUI
import AVKit
import AppKit

// AppKit AVPlayerView wrapper
struct AppKitVideoPlayer: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .none
        playerView.videoGravity = .resizeAspectFill
        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

struct VideoWithGlassExample: View {
    let radius: CGFloat
    let glassRadius: CGFloat
    let strength: CGFloat
    let warp: CGFloat
    let frost: CGFloat
    let highlight: CGFloat

    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video background using AppKit
                if let player = player {
                    AppKitVideoPlayer(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            player.play()
                            player.isMuted = true
                            // Loop video
                            NotificationCenter.default.addObserver(
                                forName: .AVPlayerItemDidPlayToEndTime,
                                object: player.currentItem,
                                queue: .main
                            ) { _ in
                                player.seek(to: .zero)
                                player.play()
                            }
                        }
                } else {
                    Color.black
                        .onAppear {
                            loadVideo()
                        }
                }

                // Glass effect text overlay
                Text("BLENDER")
                    .font(.system(size: 120, weight: .black))
                    .foregroundStyle(.clear)
                    .overlay {
                        ZStack {
                            // Background video layer for sampling
                            if let player = player {
                                AppKitVideoPlayer(player: player)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .allowsHitTesting(false)
                                    .mask {
                                        Text("BLENDER")
                                            .font(.system(size: 120, weight: .black))
                                    }
                                    .layerEffect(
                                        ShaderLibrary.clearGlass(
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
                        }
                    }
            }
        }
    }

    private func loadVideo() {
        // Blender Foundation's "Coffee Run" (2020) - Creative Commons
        // Hosted on Wikimedia Commons
        guard let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3f/Coffee_Run_-_Blender_Open_Movie-full_movie.webm") else {
            return
        }

        player = AVPlayer(url: url)
        player?.isMuted = true
    }
}
