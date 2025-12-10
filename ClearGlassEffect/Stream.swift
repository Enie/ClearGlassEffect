//
//  Stream.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 10.12.25.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import AVFoundation

@Observable
class Stream: NSView, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice?
    var devicePosition: AVCaptureDevice.Position = .back
    
    // Shared context for CGImage conversion to avoid creating new contexts
    private static let sharedContext = CIContext(options: [
        CIContextOption.workingColorSpace: kCFNull!,
        CIContextOption.useSoftwareRenderer: false  // Use GPU acceleration
    ])
    public var hasVideoAccess: Bool = false
    public var streamFrame: CGImage?

//    private var needsUpdate = false
    private var contrast: Double = 1
    private var exposureValue: Float = 1
    private var zoom: CGFloat = 1

    // Glass effect parameters
    public var glassRadius: CGFloat = 5.0
    public var glassStrength: CGFloat = 2.0
    public var glassWarp: CGFloat = 0.25
    public var glassFrost: CGFloat = 0.0
    public var glassHighlight: CGFloat = 0.5
    public var glassCornerRadius: CGFloat = 0.0
    
    init() {
        super.init(frame: .zero)
        
        hasVideoAccess = false
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { flag in
                DispatchQueue.main.async {
                    self.hasVideoAccess = flag
                }
            }
        } else if status == .authorized {
            hasVideoAccess = true
        }
    }
    
#if os(iOS)
    var orientation = UIDeviceOrientation.unknown {
        didSet {
            set(orientation: orientation)
        }
    }

    func set(orientation: UIDeviceOrientation) {
        var avOrientation = AVCaptureVideoOrientation.portrait
        if orientation == .landscapeLeft {
            avOrientation = .landscapeRight
        } else if orientation == .landscapeRight {
            avOrientation = .landscapeLeft
        } else if orientation == .portraitUpsideDown {
            avOrientation = .portraitUpsideDown
        }
        
        // Safely set orientation on all video connections
        guard let session = captureSession else { return }
        for connection in session.connections {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = avOrientation
            }
        }
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
#endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        print("START")
        // setup session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Set lower resolution to reduce processing load and heat
        session.sessionPreset = .vga640x480  // Much lower than default (often 1920x1080+)
        
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                              for: .video, position: .back) //alternate AVCaptureDevice.default(for: .video)
        guard videoDevice != nil, let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!), session.canAddInput(videoDeviceInput) else {
            print("!!! NO CAMERA DETECTED")
            let ciImage = CIImage(cgImage: (NSImage(named: "capybara")?.cgImage(forProposedRect: nil, context: nil, hints: nil)!)!)
            filter(ciImage: ciImage)
            return
        }
        session.addInput(videoDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "gamegirlcamera.processing.queue"))
        
        session.addOutput(videoOutput)
        
        // Try to set device frame rate to reduce processing load
        if let device = videoDevice {
            do {
                try device.lockForConfiguration()
                
                // Find a format that supports lower frame rates
                if let format = device.formats.first(where: { format in
                    let ranges = format.videoSupportedFrameRateRanges
                    return ranges.contains { $0.minFrameRate <= 10 && $0.maxFrameRate >= 6 }
                }) {
                    device.activeFormat = format
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 8) // 10 fps
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 8)  // 8 fps
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Could not set device frame rate: \(error)")
            }
        }
        
        session.commitConfiguration()
        self.captureSession = session

#if os(iOS)
        // Set initial orientation based on current device orientation
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation != .unknown {
            self.orientation = currentOrientation
        } else {
            // Fallback to interface orientation if device orientation is unknown
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                switch windowScene.interfaceOrientation {
                case .portrait:
                    self.orientation = .portrait
                case .portraitUpsideDown:
                    self.orientation = .portraitUpsideDown
                case .landscapeLeft:
                    self.orientation = .landscapeLeft
                case .landscapeRight:
                    self.orientation = .landscapeRight
                default:
                    self.orientation = .portrait
                }
            } else {
                self.orientation = .portrait
            }
        }
#endif
        
        self.captureSession?.startRunning()
    }
    
    func stop() {
        print("STOP")
        self.captureSession?.stopRunning()
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
#if os(iOS)
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if nil != self.superview {
            self.videoPreviewLayer.session = self.captureSession
            self.videoPreviewLayer.videoGravity = .resizeAspect
            self.captureSession?.startRunning()
        } else {
            self.captureSession?.stopRunning()
        }
    }
#endif

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("No frame available D:")
            return
        }
        
        // process image here
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: frame, options: attachments as? [CIImageOption : Any])
        
        filter(ciImage: ciImage)
    }
    
    func filter(ciImage: CIImage) {
        // Flip the image horizontally for mirror effect
        let flippedImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            .transformed(by: CGAffineTransform(translationX: ciImage.extent.width, y: 0))

        let glassyImage = ClearGlassCIFilter()
        glassyImage.inputImage = flippedImage

        // Apply glass effect parameters
        glassyImage.radius = glassRadius
        glassyImage.strength = glassStrength
        glassyImage.warp = glassWarp
        glassyImage.frost = glassFrost
        glassyImage.highlight = glassHighlight
        glassyImage.cornerRadius = glassCornerRadius

        if let resultImage = glassyImage.outputImage {
            DispatchQueue.main.async {
                self.streamFrame = Self.sharedContext.createCGImage(resultImage, from: resultImage.extent)
            }
        }
    }
    
    func switchCamera() {
        if let captureSession = self.captureSession {
            captureSession.beginConfiguration()
            
            let currentInput: AVCaptureInput = captureSession.inputs[0]
            devicePosition = videoDevice?.position == .back ? .front : .back
            captureSession.removeInput(currentInput)
            
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition)
            guard let device = videoDevice, let videoDeviceInput = try? AVCaptureDeviceInput(device: device), captureSession.canAddInput(videoDeviceInput) else {
                print("!!! NO CAMERA DETECTED")
                return
            }
            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: device))
            } catch {
                print("Error adding video input device")
            }
            do {
                try device.lockForConfiguration()
            } catch {
                print("Error locking focus for configuration")
            }
#if os(iOS)
            device.setExposureTargetBias(exposureValue, completionHandler: nil)
            device.videoZoomFactor = zoom
#endif
            device.unlockForConfiguration()
            captureSession.commitConfiguration()
            // Set orientation after camera switch
            
#if os(iOS)
            set(orientation: self.orientation)
#endif
        }
    }
}
