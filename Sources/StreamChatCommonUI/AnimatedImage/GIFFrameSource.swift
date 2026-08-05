//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Frame metadata and on-demand frame decoding for a single GIF.
///
/// The metadata is parsed once at init and immutable afterwards. `decodeFrame(at:)` is
/// confined to ``GIFFrameBuffer``'s serial queue, which is its only caller.
final class GIFFrameSource: @unchecked Sendable {
    /// The number of frames in the animation.
    let frameCount: Int
    /// The display duration of each frame, in seconds.
    let frameDelays: [TimeInterval]
    /// The number of loops the file asks for: `0` means infinite, and files without a looping
    /// extension are reported as `1` by ImageIO. Unused while playback always loops forever.
    let loopCount: Int
    /// The size of one decoded frame in bytes.
    let bytesPerFrame: Int

    /// The delay used when a frame carries no usable timing information.
    private static let defaultDelay: TimeInterval = 0.1
    /// Delays at or below this are treated as "as fast as possible" by browsers, which cap them.
    private static let minimumDelay: TimeInterval = 0.01
    /// The largest frame we are willing to decode at native size.
    private static let maximumPixelSize = 4096

    private let source: CGImageSource
    private let maxPixelSize: Int?

    init?(data: Data, targetPixelSize: CGSize?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              Self.isGIF(source) else { return nil }
        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        self.source = source
        self.frameCount = frameCount
        frameDelays = (0..<frameCount).map { Self.delay(of: source, at: $0) }
        loopCount = Self.loopCount(of: source)

        let pixelSize = Self.pixelSize(of: source) ?? .zero
        maxPixelSize = Self.maxPixelSize(pixelSize: pixelSize, targetPixelSize: targetPixelSize)
        let decodedSize = Self.decodedSize(pixelSize: pixelSize, maxPixelSize: maxPixelSize)
        bytesPerFrame = Int(decodedSize.width * decodedSize.height) * 4
    }

    /// Decodes the frame at the given index, or returns `nil` when it cannot be decoded.
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

    private static func loopCount(of source: CGImageSource) -> Int {
        guard let properties = CGImageSourceCopyProperties(source, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any],
              let loopCount = (gifProperties[kCGImagePropertyGIFLoopCount] as? NSNumber)?.intValue else {
            return 1
        }
        return loopCount
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

    /// The longest side the decoded frames may have, or `nil` to decode at native size.
    private static func maxPixelSize(pixelSize: CGSize, targetPixelSize: CGSize?) -> Int? {
        let nativeLongestSide = max(pixelSize.width, pixelSize.height)
        guard nativeLongestSide > 0 else { return nil }
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
