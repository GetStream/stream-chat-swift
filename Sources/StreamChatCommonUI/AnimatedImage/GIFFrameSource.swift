//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import UIKit
import UniformTypeIdentifiers

// The metadata is parsed once at init and immutable afterwards. `decodeFrame(at:)` runs only
// on `GIFFrameBuffer`'s serial queue.
final class GIFFrameSource: @unchecked Sendable {
    let frameCount: Int
    let frameDelays: [TimeInterval]
    let bytesPerFrame: Int

    private static let defaultDelay: TimeInterval = 0.1
    // Browsers treat delays at or below this as "as fast as possible" and replace them.
    private static let minimumDelay: TimeInterval = 0.01
    private static let maximumPixelSize = 4096

    private let source: CGImageSource
    private let maxPixelSize: Int?

    init?(data: Data, targetPixelSize: CGSize?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              Self.isGIF(source),
              let pixelSize = Self.pixelSize(of: source) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        self.source = source
        self.frameCount = frameCount
        frameDelays = (0..<frameCount).map { Self.delay(of: source, at: $0) }

        maxPixelSize = Self.maxPixelSize(pixelSize: pixelSize, targetPixelSize: targetPixelSize)
        let decodedSize = Self.decodedSize(pixelSize: pixelSize, maxPixelSize: maxPixelSize)
        bytesPerFrame = Int(decodedSize.width * decodedSize.height) * 4
    }

    func decodeFrame(at index: Int) -> UIImage? {
        guard index >= 0, index < frameCount else { return nil }
        let cgImage: CGImage?
        if let maxPixelSize {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]
            cgImage = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary)
        } else {
            let options: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
            cgImage = CGImageSourceCreateImageAtIndex(source, index, options as CFDictionary)
        }
        guard let cgImage else { return nil }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    // MARK: - Private

    private static func isGIF(_ source: CGImageSource) -> Bool {
        guard let uti = CGImageSourceGetType(source) as String? else { return false }
        if #available(iOS 14, *) {
            return uti == UTType.gif.identifier
        } else {
            return uti == "com.compuserve.gif"
        }
    }

    private static func delay(of source: CGImageSource, at index: Int) -> TimeInterval {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let gifProperties = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        let unclamped = (gifProperties?[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue
        let clamped = (gifProperties?[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue
        guard let delay = unclamped ?? clamped, delay > minimumDelay else { return defaultDelay }
        return delay
    }

    private static func pixelSize(of source: CGImageSource) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue,
              width > 0, height > 0 else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    // The longest side the decoded frames may have, or `nil` to decode at native size.
    private static func maxPixelSize(pixelSize: CGSize, targetPixelSize: CGSize?) -> Int? {
        let nativeLongestSide = max(pixelSize.width, pixelSize.height)
        guard let targetPixelSize, targetPixelSize != .zero else {
            return nativeLongestSide > CGFloat(maximumPixelSize) ? maximumPixelSize : nil
        }
        let targetLongestSide = max(targetPixelSize.width, targetPixelSize.height)
        return max(1, Int(min(targetLongestSide, nativeLongestSide).rounded()))
    }

    private static func decodedSize(pixelSize: CGSize, maxPixelSize: Int?) -> CGSize {
        guard let maxPixelSize else { return pixelSize }
        let longestSide = max(pixelSize.width, pixelSize.height)
        guard longestSide > CGFloat(maxPixelSize) else { return pixelSize }
        let scale = CGFloat(maxPixelSize) / longestSide
        return CGSize(width: (pixelSize.width * scale).rounded(), height: (pixelSize.height * scale).rounded())
    }
}
