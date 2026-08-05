//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import UIKit

/// Generated image fixtures for the animated image tests.
enum GIFFixtures {
    /// The colors used for consecutive frames, so a delivered frame can be identified by its pixels.
    static let frameColors: [UIColor] = [.red, .green, .blue, .yellow, .magenta, .cyan]

    static let corruptData = Data("this is not an image".utf8)

    /// A GIF built with `CGImageDestination`, one solid color frame per delay.
    static func gifData(
        frameDelays: [TimeInterval],
        size: CGSize = CGSize(width: 4, height: 4),
        loopCount: Int = 0
    ) -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "com.compuserve.gif" as CFString,
            frameDelays.count,
            nil
        ) else {
            return Data()
        }
        let containerProperties = [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]
        ]
        CGImageDestinationSetProperties(destination, containerProperties as CFDictionary)
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

    /// A GIF header without any complete frame.
    static func truncatedGIFData() -> Data {
        Data(gifData(frameDelays: [0.1, 0.1]).prefix(24))
    }

    static func pngData(size: CGSize = CGSize(width: 4, height: 4)) -> Data {
        solidColorImage(size: size, color: .red).pngData() ?? Data()
    }

    /// A hand-built two frame GIF: `CGImageDestination` always writes the Netscape looping
    /// extension, so the only way to get a file without a loop count is to assemble the bytes.
    static let gifDataWithoutLoopExtension: Data = {
        var bytes: [UInt8] = []
        // Header and logical screen descriptor: 1x1, global color table with two entries.
        bytes += Array("GIF89a".utf8)
        bytes += [0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00]
        // Global color table: red, green.
        bytes += [0xff, 0x00, 0x00, 0x00, 0xff, 0x00]
        // Frame 1: 0.1s delay, one pixel using color index 0.
        bytes += [0x21, 0xf9, 0x04, 0x00, 0x0a, 0x00, 0x00, 0x00]
        bytes += [0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00]
        bytes += [0x02, 0x02, 0x44, 0x01, 0x00]
        // Frame 2: 0.1s delay, one pixel using color index 1.
        bytes += [0x21, 0xf9, 0x04, 0x00, 0x0a, 0x00, 0x00, 0x00]
        bytes += [0x2c, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00]
        bytes += [0x02, 0x02, 0x4c, 0x01, 0x00]
        bytes += [0x3b]
        return Data(bytes)
    }()

    /// The color of the top left pixel, used to tell frames apart.
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

    /// Whether the image is filled with the frame color at the given index.
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
