//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

/// This class provides resizing operations for `UIImage`
open class StreamImageProcessor {
    /// Crop the image to a given size. The image is center-cropped
    /// - Parameters:
    ///   - image: The image to crop
    ///   - size: The size to which the image needs to be cropped
    /// - Returns: The cropped image
    open func crop(image: UIImage, to size: CGSize) -> UIImage? {
        let imageProccessor = ImageProcessors.Resize(size: size, crop: true)
        return imageProccessor.process(image)
    }
    
    /// Scale an image to a given size maintaing the aspect ratio.
    /// - Parameters:
    ///   - image: The image to scale
    ///   - size: The size to which the image needs to be scaled
    /// - Returns: The scaled image
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
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}
