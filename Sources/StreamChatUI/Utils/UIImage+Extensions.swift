//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init?(named name: String, in bundle: Bundle) {
        self.init(named: name, in: bundle, compatibleWith: nil)
    }
}

extension UIImage {
    func tinted(with fillColor: UIColor) -> UIImage? {
        let image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        fillColor.set()
        image.draw(in: CGRect(origin: .zero, size: size))

        guard let imageColored = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        UIGraphicsEndImageContext()
        return imageColored
    }
}

extension UIImage {
    func asAlphaMask() -> UIImage? {
        guard
            let image = cgImage,
            !image.isMask,
            let alphaOffset = alphaChannelOffset,
            let imageData = image.dataProvider?.data,
            let pixelData = CFDataGetBytePtr(imageData)
        else { return nil }

        let bytesPerPixel = image.bitsPerPixel / 8

        var alphaChannel = [UInt8](
            repeating: 0,
            count: image.height * image.width
        )

        for y in 0..<image.height {
            for x in 0..<image.width {
                let pixelIndex = y * image.width + x
                let pixelOffset = y * image.bytesPerRow + x * bytesPerPixel
                let alphaComponentOffset = pixelOffset + alphaOffset
                alphaChannel[pixelIndex] = pixelData[alphaComponentOffset]
            }
        }

        guard
            let data = CFDataCreate(nil, alphaChannel, alphaChannel.count),
            let dataProvider = CGDataProvider(data: data),
            let mask = CGImage(
                maskWidth: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bitsPerPixel: 8,
                bytesPerRow: image.width,
                provider: dataProvider,
                decode: nil,
                shouldInterpolate: false
            )
        else { return nil }

        return UIImage(
            cgImage: mask,
            scale: scale,
            orientation: imageOrientation
        )
    }

    private var alphaChannelOffset: Int? {
        switch cgImage?.alphaInfo {
        case .alphaOnly, .first, .premultipliedFirst:
            return 0
        case .last, .premultipliedLast:
            return 3
        default:
            return nil
        }
    }
}
