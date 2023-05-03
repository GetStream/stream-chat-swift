//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// The transformer computes the percentage value of each sample with respect to the maximum
/// and minimum sample values in the input array. The result is an array of transformed Float values,
/// where each element is between 0 and 1.
internal class AudioSamplesPercentageTransformer {
    init() {}

    func transform(_ samples: [Float]) -> [Float] {
        /// Compute the absolute values of each sample
        let absArray = samples.map(abs)

        guard
            let (minValue, maxValue) = absArray.minMax()
        else {
            return []
        }

        /// Compute the range between the min and max values
        let delta = maxValue - minValue

        guard delta != 0 else {
            /// delta is `0` when the array contains the same value `n times` where `n >= 1`.
            return [Float](repeating: 1, count: absArray.count)
        }

        /// Map each absolute sample value to a transformed value between 0 and 1
        return absArray.map { abs(($0 - minValue) / delta) }
    }
}

extension Array where Element: Comparable {
    /// Returns the minimum and maximum element in the sequence, or `nil` if the sequence is empty.
    /// - Returns: a tuple containing the `min` and the `max` elements in the array.
    /// - Note: `O(n)` time complexity
    fileprivate func minMax() -> (Element, Element)? {
        guard var min = first else { return nil }
        var max = min
        for element in self {
            if element < min {
                min = element
            }

            if element > max {
                max = element
            }
        }
        return (min, max)
    }
}
