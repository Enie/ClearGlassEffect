//
//  StreamView.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 10.12.25.
//

import SwiftUI
import AppKit
import Photos

struct PreviewHolder: NSViewRepresentable {
    typealias NSViewType = Stream
    
    var stream: Stream
    
    func makeNSView(context: NSViewRepresentableContext<PreviewHolder>) -> Stream {
        stream
    }

    func updateNSView(_ nsView: Stream, context: NSViewRepresentableContext<PreviewHolder>) {
    }
}

struct StreamView: View {
    @State var stream = Stream()
    
    var captureView: some View {
        VStack(alignment: .center) {
            if let frame = stream.streamFrame {
                Image(frame, scale: 1.0, label: Text("Camera Feed"))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 256, height: 224, alignment: .center)
                    .padding(EdgeInsets(top: 32, leading: 32, bottom: 0, trailing: 34))
                    .scaleEffect(CGSize(width: stream.devicePosition == .back ? 1 : -1, height: 1))
            } else {
                // Invisible placeholder to ensure view renders and onAppear fires
                Color.clear
                    .frame(width: 256, height: 224, alignment: .center)
                    .padding(EdgeInsets(top: 32, leading: 32, bottom: 0, trailing: 34))
            }
        }
            .frame(width: 320, height: 288)
            .edgesIgnoringSafeArea([.all])
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(spacing: 0) {
                if stream.hasVideoAccess {
                    ZStack {
                        captureView
                            .onAppear(perform: {
                                // add filter parameters
                                // stream.radius =
                                stream.start()

                                #if os(iOS)
                                // Set initial orientation before starting stream
                                let currentOrientation = UIDevice.current.orientation
                                if currentOrientation != .unknown {
                                    orientation = currentOrientation
                                    stream.orientation = currentOrientation
                                } else {
                                    // Fallback to interface orientation if device orientation is unknown
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        switch windowScene.interfaceOrientation {
                                        case .portrait:
                                            orientation = .portrait
                                            stream.orientation = .portrait
                                        case .portraitUpsideDown:
                                            orientation = .portraitUpsideDown
                                            stream.orientation = .portraitUpsideDown
                                        case .landscapeLeft:
                                            orientation = .landscapeLeft
                                            stream.orientation = .landscapeLeft
                                        case .landscapeRight:
                                            orientation = .landscapeRight
                                            stream.orientation = .landscapeRight
                                        default:
                                            orientation = .portrait
                                            stream.orientation = .portrait
                                        }
                                    } else {
                                        orientation = .portrait
                                        stream.orientation = .portrait
                                    }
                                }
                                #endif
                            })
                            .onDisappear(perform: {
                                stream.stop()
                            })
                            .animation(.spring(), value: 10)

                    }
#if os(iOS)
                    .rotationEffect(Angle(degrees: orientation == .landscapeRight ? -90 : (orientation == .landscapeLeft ? 90 : 0)))
                    .transformEffect(CoreGraphics.CGAffineTransform(translationX: 0, y: [.portrait,.portraitUpsideDown,.faceDown,.faceUp,.unknown].contains(orientation) ? 0 : 30))
#endif
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 0, bottom: 32, trailing: 0))
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
#if os(iOS)
        .onRotate { newOrientation in
            orientation = newOrientation
            stream.orientation = newOrientation
        }
#endif
    }
}


struct ContentView_StreamView: PreviewProvider {
    static var previews: some View {
        StreamView()
    }
}
