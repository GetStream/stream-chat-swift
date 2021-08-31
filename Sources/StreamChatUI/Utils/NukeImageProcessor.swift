//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

public protocol ImageProcessor {
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

/// This class provides resizing operations for `UIImage`. It internally uses `Nuke` porcessors to implement operations on images.
open class NukeImageProcessor: ImageProcessor {
    open func crop(image: UIImage, to size: CGSize) -> UIImage? {
        let imageProccessor = ImageProcessors.Resize(size: size, crop: true)
        return imageProccessor.process(image)
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

/// Extension of `Nuke`'s `ImageProcessors`
extension ImageProcessors {
    /// Scales an image to a specified size.
    /// The getting of the size is offloaded via closure after the image is loaded.
    /// The View has time to layout and provide non-zero size.
    public struct LateResize: ImageProcessing {
        private var size: CGSize {
            var size: CGSize = .zero
            DispatchQueue.main.sync { size = sizeProvider() }
            return size
        }

        private let sizeProvider: () -> CGSize
        
        /// Initializes the processor with size providing closure.
        /// - Parameter sizeProvider: Closure to obtain size after the image is loaded.
        public init(sizeProvider: @escaping () -> CGSize) {
            self.sizeProvider = sizeProvider
        }

        public func process(_ image: PlatformImage) -> PlatformImage? {
            let size = self.size
            guard size != .zero else { return image }
            
            return ImageProcessors.Resize(
                size: size,
                unit: .points,
                contentMode: .aspectFill,
                upscale: false
            ).process(image)
        }

        public var identifier: String {
            "com.github.kean/nuke/lateResize"
        }
    }
}
