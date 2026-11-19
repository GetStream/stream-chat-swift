//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import UIKit

enum GIFFixtures {
    // Consecutive frames get different colors, so a delivered frame can be identified by its pixels.
    static let frameColors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan]

    static let corruptData = Data("this is not an image".utf8)

    static func gifData(frameDelays: [TimeInterval], size: CGSize = CGSize(width: 4, height: 4)) -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif" as CFString,
            frameDelays.count,
            nil
        ) else {
            return Data()
        }
        for (index, delay) in frameDelays.enumerated() {
            guard let frame = solidColorImage(size: size, color: frameColors[index % frameColors.count]).cgImage else {
                continue
            }
            let frameProperties = [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]
            ]
            CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
        }
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    static func singleFrameGIFData(size: CGSize = CGSize(width: 4, height: 4)) -> Data {
        gifData(frameDelays: [0.1], size: size)
    }

    // A GIF header without any complete frame.
    static func truncatedGIFData() -> Data {
        Data(gifData(frameDelays: [0.1, 0.1]).prefix(24))
    }

    static func pngData(size: CGSize = CGSize(width: 4, height: 4)) -> Data {
        solidColorImage(size: size, color: .red).pngData() ?? Data()
    }

    // A zero logical screen width: ImageIO still counts the frames but reports no pixel size.
    static func gifDataWithoutPixelSize() -> Data {
        var data = gifData(frameDelays: [0.1, 0.1])
        data[6] = 0
        data[7] = 0
        return data
    }

    static func pixel(of image: UIImage) -> (red: UInt8, green: UInt8, blue: UInt8)? {
        guard let cgImage = image.cgImage else { return nil }
        var bytes = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(
            data: &bytes,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return (bytes[0], bytes[1], bytes[2])
    }

    static func isFrame(_ image: UIImage, at index: Int) -> Bool {
        let expectedColor = frameColors[index % frameColors.count]
        guard let actual = pixel(of: image),
              let expected = pixel(of: solidColorImage(size: CGSize(width: 1, height: 1), color: expectedColor)) else {
            return false
        }
        return actual == expected
    }

    static func solidColorImage(size: CGSize, color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
