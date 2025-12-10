//
//  ClearGlassCIFilter.swift
//  ClearGlassEffect
//
//  Created by Enie Weiß on 10.12.25.
//

import CoreImage
import SwiftUI

extension CIImage {
    // Shared context to avoid creating new contexts on every frame
    private static let sharedContext = CIContext(options: [
        CIContextOption.workingColorSpace: kCFNull!,
        CIContextOption.useSoftwareRenderer: false  // Use GPU acceleration
    ])
    
    func convert() -> NSImage?
    {
        if let cgImage = Self.sharedContext.createCGImage(self, from: self.extent, format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!) {
            let image = NSImage(cgImage: cgImage, size: .zero)
            return image
        }
        return nil
    }
}

class ClearGlassCIFilter: CIFilter {
    private let kernel: CIKernel
    var inputImage: CIImage?

    // Glass effect parameters
    var radius: CGFloat = 5.0
    var strength: CGFloat = 2.0
    var warp: CGFloat = 0.25
    var frost: CGFloat = 0.0
    var highlight: CGFloat = 0.5
    var cornerRadius: CGFloat = 0.0

    override init() {
        // Try to load from .ci.metallib first (Core Image kernel), fallback to default.metallib
        var url = Bundle.main.url(forResource: "ClearGlassCIKernel.ci", withExtension: "metallib")
        if url == nil {
            url = Bundle.main.url(forResource: "default", withExtension: "metallib")
        }

        guard let metalURL = url else {
            fatalError("Could not find metallib file")
        }

        let data = try! Data(contentsOf: metalURL)
        // Use base CIKernel since the shader returns colors but isn't a pure color operation
        kernel = try! CIKernel(functionName: "ciClearGlass", fromMetalLibraryData: data)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var outputImage: CIImage? {
        guard let inputImage = self.inputImage else { return nil }
        let inputExtent = inputImage.extent

        let roiCallback: CIKernelROICallback = { _, rect -> CGRect in
            // Expand ROI to account for edge sampling and displacement (match SwiftUI version)
            let maxOffset = self.radius * self.strength * (1.0 + self.warp)
            return rect.insetBy(dx: -maxOffset, dy: -maxOffset)
        }

        let imageSize = CIVector(x: inputExtent.width, y: inputExtent.height)

        return self.kernel.apply(extent: inputExtent,
                                 roiCallback: roiCallback,
                                 arguments: [inputImage,
                                           radius,
                                           strength,
                                           warp,
                                           frost,
                                           highlight,
                                           cornerRadius,
                                           imageSize])
    }
}

