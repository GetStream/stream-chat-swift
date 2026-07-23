//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Stateless ImageIO helpers for decoding and downscaling images.
///
/// Downscaling uses aspect fill without upscaling and bakes EXIF
/// orientation into the output pixels, so JPEG/HEIC photos carrying a portrait or
/// landscape orientation tag are decoded upright and sized from their display size.
enum ImageDownsampler {
    enum DecodedImage {
        case image(UIImage)
        case animated
    }

    /// Decodes image data into a still image, or reports that it is animated (GIF).
    ///
    /// - Parameters:
    ///   - data: The encoded image bytes.
    ///   - resize: Optional target size in points. When set, the image is downscaled to
    ///     *fill* the target box (aspect ratio preserved, never upscaled). When `nil`, the
    ///     image is decoded at full size.
    ///   - scale: The display scale used to convert `resize` points to pixels and to wrap
    ///     the resized output so its point size matches the requested size.
    static func decode(_ data: Data, resize: CGSize?, scale: CGFloat) -> DecodedImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data).map(DecodedImage.image)
        }
        if isGIF(source) {
            return .animated
        }

        var options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        if let resize, resize != .zero,
           let maxPixelSize = maxPixelSize(source: source, targetPoints: resize, scale: scale) {
            options[kCGImageSourceThumbnailMaxPixelSize] = maxPixelSize
        }

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data).map(DecodedImage.image)
        }
        let outputScale = resize == nil ? 1 : scale
        return .image(UIImage(cgImage: cgImage, scale: outputScale, orientation: .up))
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

    private static func maxPixelSize(source: CGImageSource, targetPoints: CGSize, scale: CGFloat) -> Int? {
        guard let displaySize = sourcePixelSize(source: source),
              displaySize.width > 0, displaySize.height > 0 else {
            return nil
        }
        let targetPixels = CGSize(width: targetPoints.width * scale, height: targetPoints.height * scale)
        // Aspect-fill: scale to cover the target box without upscaling.
        let fillScale = min(1, max(targetPixels.width / displaySize.width, targetPixels.height / displaySize.height))
        let longestSide = max(displaySize.width, displaySize.height) * fillScale
        return max(1, Int(longestSide.rounded()))
    }

    /// The source's pixel size in display orientation (dimensions swapped for 90°/270° EXIF
    /// orientations), so the aspect-fill math matches the upright output.
    private static func sourcePixelSize(source: CGImageSource) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue else {
            return nil
        }
        let raw = CGSize(width: width, height: height)
        if let rawOrientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value,
           let orientation = CGImagePropertyOrientation(rawValue: rawOrientation),
           isSwappingDimensions(orientation) {
            return CGSize(width: raw.height, height: raw.width)
        }
        return raw
    }

    private static func isSwappingDimensions(_ orientation: CGImagePropertyOrientation) -> Bool {
        switch orientation {
        case .left, .right, .leftMirrored, .rightMirrored:
            return true
        default:
            return false
        }
    }
}
