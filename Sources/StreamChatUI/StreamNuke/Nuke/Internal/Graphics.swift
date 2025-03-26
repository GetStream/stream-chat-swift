// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

#if os(watchOS)
import ImageIO
import CoreGraphics
import WatchKit.WKInterfaceDevice
#endif

#if canImport(UIKit)
 import UIKit
 #endif

 #if canImport(AppKit)
 import AppKit
 #endif

extension PlatformImage {
    var processed: ImageProcessingExtensions {
        ImageProcessingExtensions(image: self)
    }
}

struct ImageProcessingExtensions {
    let image: PlatformImage

    func byResizing(to targetSize: CGSize,
                    contentMode: ImageProcessingOptions.ContentMode,
                    upscale: Bool) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
#if canImport(UIKit)
        let targetSize = targetSize.rotatedForOrientation(image.imageOrientation)
#endif
        let scale = cgImage.size.getScale(targetSize: targetSize, contentMode: contentMode)
        guard scale < 1 || upscale else {
            return image // The image doesn't require scaling
        }
        let size = cgImage.size.scaled(by: scale).rounded()
        return image.draw(inCanvasWithSize: size)
    }

    /// Crops the input image to the given size and resizes it if needed.
    /// - note: this method will always upscale.
    func byResizingAndCropping(to targetSize: CGSize) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
#if canImport(UIKit)
        let targetSize = targetSize.rotatedForOrientation(image.imageOrientation)
#endif
        let scale = cgImage.size.getScale(targetSize: targetSize, contentMode: .aspectFill)
        let scaledSize = cgImage.size.scaled(by: scale)
        let drawRect = scaledSize.centeredInRectWithSize(targetSize)
        return image.draw(inCanvasWithSize: targetSize, drawRect: drawRect)
    }

    func byDrawingInCircle(border: ImageProcessingOptions.Border?) -> PlatformImage? {
        guard let squared = byCroppingToSquare(), let cgImage = squared.cgImage else {
            return nil
        }
        let radius = CGFloat(cgImage.width) // Can use any dimension since image is a square
        return squared.processed.byAddingRoundedCorners(radius: radius / 2.0, border: border)
    }

    /// Draws an image in square by preserving an aspect ratio and filling the
    /// square if needed. If the image is already a square, returns an original image.
    func byCroppingToSquare() -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        guard cgImage.width != cgImage.height else {
            return image // Already a square
        }

        let imageSize = cgImage.size
        let side = min(cgImage.width, cgImage.height)
        let targetSize = CGSize(width: side, height: side)
        let cropRect = CGRect(origin: .zero, size: targetSize).offsetBy(
            dx: max(0, (imageSize.width - targetSize.width) / 2).rounded(.down),
            dy: max(0, (imageSize.height - targetSize.height) / 2).rounded(.down)
        )
        guard let cropped = cgImage.cropping(to: cropRect) else {
            return nil
        }
        return PlatformImage.make(cgImage: cropped, source: image)
    }

    /// Adds rounded corners with the given radius to the image.
    /// - parameter radius: Radius in pixels.
    /// - parameter border: Optional stroke border.
    func byAddingRoundedCorners(radius: CGFloat, border: ImageProcessingOptions.Border? = nil) -> PlatformImage? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        guard let ctx = CGContext.make(cgImage, size: cgImage.size, alphaInfo: .premultipliedLast) else {
            return nil
        }
        let rect = CGRect(origin: CGPoint.zero, size: cgImage.size)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.addPath(path)
        ctx.clip()
        ctx.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: cgImage.size))

        if let border {
            ctx.setStrokeColor(border.color.cgColor)
            ctx.addPath(path)
            ctx.setLineWidth(border.width)
            ctx.strokePath()
        }
        guard let outputCGImage = ctx.makeImage() else {
            return nil
        }
        return PlatformImage.make(cgImage: outputCGImage, source: image)
    }
}

extension PlatformImage {
    /// Draws the image in a `CGContext` in a canvas with the given size using
    /// the specified draw rect.
    ///
    /// For example, if the canvas size is `CGSize(width: 10, height: 10)` and
    /// the draw rect is `CGRect(x: -5, y: 0, width: 20, height: 10)` it would
    /// draw the input image (which is horizontal based on the known draw rect)
    /// in a square by centering it in the canvas.
    ///
    /// - parameter drawRect: `nil` by default. If `nil` will use the canvas rect.
    func draw(inCanvasWithSize canvasSize: CGSize, drawRect: CGRect? = nil) -> PlatformImage? {
        guard let cgImage else {
            return nil
        }
        guard let ctx = CGContext.make(cgImage, size: canvasSize) else {
            return nil
        }
        ctx.draw(cgImage, in: drawRect ?? CGRect(origin: .zero, size: canvasSize))
        guard let outputCGImage = ctx.makeImage() else {
            return nil
        }
        return PlatformImage.make(cgImage: outputCGImage, source: self)
    }

    /// Decompresses the input image by drawing in the the `CGContext`.
    func decompressed(isUsingPrepareForDisplay: Bool) -> PlatformImage? {
#if os(iOS) || os(tvOS) || os(visionOS)
        if isUsingPrepareForDisplay, #available(iOS 15.0, tvOS 15.0, *) {
            return preparingForDisplay()
        }
#endif
        guard let cgImage else {
            return nil
        }
        return draw(inCanvasWithSize: cgImage.size, drawRect: CGRect(origin: .zero, size: cgImage.size))
    }
}

private extension CGContext {
    static func make(_ image: CGImage, size: CGSize, alphaInfo: CGImageAlphaInfo? = nil) -> CGContext? {
        if let ctx = CGContext.make(image, size: size, alphaInfo: alphaInfo, colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()) {
            return ctx
        }
        // In case the combination of parameters (color space, bits per component, etc)
        // is nit supported by Core Graphics, switch to default context.
        // - Quartz 2D Programming Guide
        // - https://github.com/kean/Nuke/issues/35
        // - https://github.com/kean/Nuke/issues/57
        return CGContext.make(image, size: size, alphaInfo: alphaInfo, colorSpace: CGColorSpaceCreateDeviceRGB())
    }

    static func make(_ image: CGImage, size: CGSize, alphaInfo: CGImageAlphaInfo?, colorSpace: CGColorSpace) -> CGContext? {
        CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: (alphaInfo ?? preferredAlphaInfo(for: image, colorSpace: colorSpace)).rawValue
        )
    }

    /// - See https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
    private static func preferredAlphaInfo(for image: CGImage, colorSpace: CGColorSpace) -> CGImageAlphaInfo {
        guard image.isOpaque else {
            return .premultipliedLast
        }
        if colorSpace.numberOfComponents == 1 && image.bitsPerPixel == 8 {
            return .none // The only pixel format supported for grayscale CS
        }
        return .noneSkipLast
    }
}

extension CGFloat {
    func converted(to unit: ImageProcessingOptions.Unit) -> CGFloat {
        switch unit {
        case .pixels: return self
        case .points: return self * Screen.scale
        }
    }
}

extension CGSize {
    func getScale(targetSize: CGSize, contentMode: ImageProcessingOptions.ContentMode) -> CGFloat {
        let scaleHor = targetSize.width / width
        let scaleVert = targetSize.height / height

        switch contentMode {
        case .aspectFill:
            return max(scaleHor, scaleVert)
        case .aspectFit:
            return min(scaleHor, scaleVert)
        }
    }

    /// Calculates a rect such that the output rect will be in the center of
    /// the rect of the input size (assuming origin: .zero)
    func centeredInRectWithSize(_ targetSize: CGSize) -> CGRect {
        // First, resize the original size to fill the target size.
        CGRect(origin: .zero, size: self).offsetBy(
            dx: -(width - targetSize.width) / 2,
            dy: -(height - targetSize.height) / 2
        )
    }
}

#if canImport(UIKit)
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

extension UIImage.Orientation {
    init(_ cgOrientation: CGImagePropertyOrientation) {
        switch cgOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

private extension CGSize {
    func rotatedForOrientation(_ imageOrientation: CGImagePropertyOrientation) -> CGSize {
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: height, height: width) // Rotate 90 degrees
        case .up, .upMirrored, .down, .downMirrored:
            return self
        }
    }

    func rotatedForOrientation(_ imageOrientation: UIImage.Orientation) -> CGSize {
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: height, height: width) // Rotate 90 degrees
        case .up, .upMirrored, .down, .downMirrored:
            return self
        @unknown default:
            return self
        }
    }
}
#endif

#if os(macOS)
extension NSImage {
    var cgImage: CGImage? {
        cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    var ciImage: CIImage? {
        cgImage.map { CIImage(cgImage: $0) }
    }

    static func make(cgImage: CGImage, source: NSImage) -> NSImage {
        NSImage(cgImage: cgImage, size: .zero)
    }

    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
}
#else
extension UIImage {
    static func make(cgImage: CGImage, source: UIImage) -> UIImage {
        UIImage(cgImage: cgImage, scale: source.scale, orientation: source.imageOrientation)
    }
}
#endif

extension CGImage {
    /// Returns `true` if the image doesn't contain alpha channel.
    var isOpaque: Bool {
        let alpha = alphaInfo
        return alpha == .none || alpha == .noneSkipFirst || alpha == .noneSkipLast
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

extension CGSize {
    func scaled(by scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }

    func rounded() -> CGSize {
        CGSize(width: CGFloat(round(width)), height: CGFloat(round(height)))
    }
}

enum Screen {
#if os(iOS) || os(tvOS)
    /// Returns the current screen scale.
    static let scale: CGFloat = UITraitCollection.current.displayScale
#elseif os(watchOS)
    /// Returns the current screen scale.
    static let scale: CGFloat = WKInterfaceDevice.current().screenScale
#else
    /// Always returns 1.
    static let scale: CGFloat = 1
#endif
}

#if os(macOS)
typealias Color = NSColor
#else
typealias Color = UIColor
#endif

extension Color {
    /// Returns a hex representation of the color, e.g. "#FFFFAA".
    var hex: String {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let components = [r, g, b, a < 1 ? a : nil]
        return "#" + components
            .compactMap { $0 }
            .map { String(format: "%02lX", lroundf(Float($0) * 255)) }
            .joined()
    }
}

/// Creates an image thumbnail. Uses significantly less memory than other options.
/// - parameter data: Data object from which to read the image.
/// - parameter options: Image loading options.
/// - parameter scale: The scale factor to assume when interpreting the image data, defaults to 1.
func makeThumbnail(data: Data, options: ImageRequest.ThumbnailOptions, scale: CGFloat = 1.0) -> PlatformImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary) else {
        return nil
    }

    let maxPixelSize = getMaxPixelSize(for: source, options: options)
    let options = [
        kCGImageSourceCreateThumbnailFromImageAlways: options.createThumbnailFromImageAlways,
        kCGImageSourceCreateThumbnailFromImageIfAbsent: options.createThumbnailFromImageIfAbsent,
        kCGImageSourceShouldCacheImmediately: options.shouldCacheImmediately,
        kCGImageSourceCreateThumbnailWithTransform: options.createThumbnailWithTransform,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize] as [CFString: Any]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }

#if canImport(UIKit)
    var orientation: UIImage.Orientation = .up
    if let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any],
       let orientationValue = imageProperties[kCGImagePropertyOrientation as String] as? UInt32,
       let cgOrientation = CGImagePropertyOrientation(rawValue: orientationValue) {
        orientation = UIImage.Orientation(cgOrientation)
    }
    return PlatformImage(cgImage: image, scale: scale, orientation: orientation)
#else
    return PlatformImage(cgImage: image)
#endif
}

private func getMaxPixelSize(for source: CGImageSource, options thumbnailOptions: ImageRequest.ThumbnailOptions) -> CGFloat {
    switch thumbnailOptions.targetSize {
    case .fixed(let size):
        return CGFloat(size)
    case let .flexible(size, contentMode):
        var targetSize = size.cgSize
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, options) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return max(targetSize.width, targetSize.height)
        }

        let orientation = (properties[kCGImagePropertyOrientation] as? UInt32).flatMap(CGImagePropertyOrientation.init) ?? .up
#if canImport(UIKit)
        targetSize = targetSize.rotatedForOrientation(orientation)
#endif

        let imageSize = CGSize(width: width, height: height)
        let scale = imageSize.getScale(targetSize: targetSize, contentMode: contentMode)
        let size = imageSize.scaled(by: scale).rounded()
        return max(size.width, size.height)
    }
}
