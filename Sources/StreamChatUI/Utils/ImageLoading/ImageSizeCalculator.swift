//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// Responsible to calculate the image size in points given the original resolution and the max desirable
///  resolution. In case the original resolution is already below the maximum, it uses the
///  original resolution and converts it to points.
struct ImageSizeCalculator {
    /// Calculates the image size in points given the original resolution and the max desirable
    ///  resolution. In case the original resolution is already below the maximum, it uses the
    ///  original resolution and converts it to points.
    ///
    /// - Parameters:
    ///   - originalWidthInPixels: The original width in pixels.
    ///   - originalHeightInPixels: The original height in pixels.
    ///   - maxResolutionTotalPixels: The maximum resolution of the new size.
    /// - Returns: Returns the original resolution in points or the max resolution in points
    /// in case the original resolution is bigger than the maximum.
    func calculateSize(
        originalWidthInPixels: Double,
        originalHeightInPixels: Double,
        maxResolutionTotalPixels: Double
    ) -> CGSize {
        let scale = UIScreen.main.scale

        let originalResolutionTotalPixels = originalWidthInPixels * originalHeightInPixels
        guard originalResolutionTotalPixels > maxResolutionTotalPixels else {
            let widthInPoints = originalWidthInPixels / scale
            let heightInPoints = originalHeightInPixels / scale
            let originalSizeInPoints = CGSize(width: widthInPoints, height: heightInPoints)
            return originalSizeInPoints
        }

        /// The formula to calculate the new resolution is based on the max pixels and
        /// the original aspect ratio. To get the formula, a system of equations is needed.
        ///
        /// { w * h = maxResolutionTotalPixels }
        /// { w / h = originalRatio }
        /// ->
        /// { w = maxResolutionTotalPixels / h
        /// { h = w / originalRatio
        /// ->
        /// { w = maxResolutionTotalPixels / (w / originalRatio)
        /// { h = w / originalRatio
        /// ->
        /// { wˆ2 / originalRatio = maxResolutionTotalPixels
        /// { h = w / originalRatio
        /// ->
        /// { w = sqrt(maxResolutionTotalPixels * originalRatio)
        /// { h = w / originalRatio
        ///
        let originalRatio = originalWidthInPixels / originalHeightInPixels
        let newWidthInPixels = sqrt(maxResolutionTotalPixels * originalRatio)
        let newHeightInPixels = newWidthInPixels / originalRatio
        let newWidthInPoints = newWidthInPixels / scale
        let newHeightInPoints = newHeightInPixels / scale
        let newSize = CGSize(width: newWidthInPoints, height: newHeightInPoints)
        return newSize
    }
}
