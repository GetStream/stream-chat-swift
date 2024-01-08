//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The normaliser computes the percentage values or value of the provided array or value.
internal class AudioValuePercentageNormaliser {
    internal let valueRange: ClosedRange<Float> = -50...0

    /// Compute the range between the min and max values
    internal lazy var delta: Float = valueRange.upperBound - valueRange.lowerBound

    internal init() {}

    /// Computes the percentage value of each sample with respect to the maximum
    /// and minimum values in the provided range. The result is will be in the range `0...1`.
    /// - Parameter samples: The array containing the values to be transformed to percentages
    /// relative to the provided valueRange
    /// - Returns: an array of normalised Float values
    internal func normalise(_ values: [Float]) -> [Float] {
        values.map(normalise)
    }

    internal func normalise(_ value: Float) -> Float {
        if value < valueRange.lowerBound {
            return 0
        } else if value > valueRange.upperBound {
            return 1
        } else {
            return abs((value - valueRange.lowerBound) / delta)
        }
    }
}
