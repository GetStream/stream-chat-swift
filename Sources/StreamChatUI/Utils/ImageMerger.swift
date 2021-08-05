//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// The orientation to be used for merge the images
public enum ImageMergeOrientation {
    /// Merge the given images in horizontal orientation.
    /// The width of the resulting images will be the addition of the widths of all the images,
    /// whereas the height of the resulting image will be equal to the max of heights in the images
    case horizontal
    
    /// Merge the given images in vertical orientation.
    /// The width of the resulting images will be equal to the max of widths in the images,
    /// whereas the height of the resulting image will be the addition of the heights of all the images
    case vertical
}

public protocol ImageMerging {
    /// Merges the images provided in the array
    /// - Parameters:
    ///   - images: The images to combine
    ///   - orientation: The orientation to be used for combining the images
    /// - Returns: A combined image
    func merge(
        images: [UIImage],
        orientation: ImageMergeOrientation
    ) -> UIImage?
}

open class DefaultImageMerger: ImageMerging {
    // Initializer required for subclasses
    public init() {}
    
    open func merge(
        images: [UIImage],
        orientation: ImageMergeOrientation
    ) -> UIImage? {
        orientation == .horizontal ? mergeSideToSide(images: images) : mergeTopToBottom(images: images)
    }
    
    /// Merges images in top to bottom fashion
    /// - Parameter images: The images
    /// - Returns: The merged image
    open func mergeTopToBottom(images: [UIImage]) -> UIImage? {
        var dimensions = CGSize(width: 0.0, height: 0.0)
        for image in images {
            dimensions.width = max(dimensions.width, image.size.width)
            dimensions.height += max(dimensions.height, image.size.height)
        }

        UIGraphicsBeginImageContext(dimensions)

        var lastY = CGFloat(0.0)
        for image in images {
            image.draw(in: CGRect(x: 0, y: lastY, width: dimensions.width, height: image.size.height))
            lastY += image.size.height
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }
    
    /// Merges images in top to side to side order (left -> right)
    /// - Parameter images: The images
    /// - Returns: The merged image
    open func mergeSideToSide(images: [UIImage]) -> UIImage? {
        var dimensions = CGSize.zero
        
        for image in images {
            dimensions.width += image.size.width
            dimensions.height = max(dimensions.height, image.size.height)
        }

        UIGraphicsBeginImageContext(dimensions)

        var lastX = CGFloat(0.0)
        for image in images {
            image.draw(in: CGRect(x: lastX, y: 0, width: image.size.width, height: image.size.height))
            lastX += image.size.width
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage
    }
}
