//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

public protocol ImageProcessor: Sendable {
    /// Crop the image to a given size. The image is center-cropped
    /// - Parameters:
    ///   - image: The image to crop
    ///   - size: The size to which the image needs to be cropped
    /// - Returns: The cropped image
    func crop(image: UIImage, to size: CGSize) -> UIImage?

    /// Scale an image to a given size maintaing the aspect ratio.
    /// - Parameters:
    ///   - image: The image to scale
    ///   - size: The size to which the image needs to be scaled
    /// - Returns: The scaled image
    func scale(image: UIImage, to size: CGSize) -> UIImage
}

/// This class provides resizing operations for `UIImage`.
open class StreamImageProcessor: ImageProcessor, @unchecked Sendable {
    open func crop(image: UIImage, to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0,
              image.size.width > 0, image.size.height > 0 else {
            return nil
        }
        // Aspect-fill: scale so the image covers the target, then center-crop to it.
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(
            x: (size.width - scaledSize.width) / 2,
            y: (size.height - scaledSize.height) / 2
        )
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }

    open func scale(image: UIImage, to size: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height

        let scaleFactor = min(widthRatio, heightRatio)

        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: image.size.width * scaleFactor,
            height: image.size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize)

        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }

        return scaledImage
    }
}
