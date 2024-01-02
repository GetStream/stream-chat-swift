//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Accelerate
import Foundation

extension Array where Element == Float {
    /// Downsamples an array of Float values by reducing the number of samples in the input signal while
    /// maintaining its shape and information content.
    /// - Parameter downSampledLength: The length will be used to calculate the downsampling rate
    /// as the maximum of 1 and the ratio of the length of the input signal to downSampledLength.
    /// - Returns: It uses the `vDSP_desamp` to perform the downsampling operation using the
    /// processingBuffer, filter, downSampledData, and the lengths of the input and output signals and return
    /// the downsampled result.
    public func downsample(to downSampledLength: Int) -> [Element] {
        guard count > downSampledLength, downSampledLength > 0 else {
            return self
        }

        let processingBuffer = self
        let downsamplingRate = Swift.max(Float(1), Float(count) / Float(downSampledLength))
        var downSampledData: [Float] = [Float](repeating: 0.0, count: downSampledLength)
        let filter = [Float](repeating: 1.0 / downsamplingRate, count: Int(downsamplingRate))

        vDSP_desamp(
            processingBuffer,
            vDSP_Stride(downsamplingRate),
            filter,
            &downSampledData,
            vDSP_Length(downSampledLength),
            vDSP_Length(downsamplingRate)
        )

        return downSampledData
    }

    /// Upsamples an array of Float values by increasing the number of samples in the input signal by a
    /// factor while maintaining its shape and information content (by applying a linear interpolation).
    /// - Parameter upsampledLength: The length will be used to calculate  the upsampling rate
    ///  as the ratio of the upsampledLength parameter to the length of the input signal.
    /// - Returns: Calculates the index of the closest sample in the input signal to the corresponding
    /// index in the output signal, and returns an array of upsampled Float values that have the specified length.
    /// - Note: If upsampledLength is not greater than zero or the length of the input signal is greater
    /// than or equal to upsampledLength, the input array is returned as is.
    public func upsample(to upsampledLength: Int) -> [Element] {
        let size = count
        guard !isEmpty, upsampledLength > 0, size < upsampledLength else {
            return self
        }

        var upsampled = [Float](repeating: 0.0, count: upsampledLength)
        let factor = Float(upsampledLength) / Float(size)

        // Linear interpolation
        for i in 0..<upsampledLength {
            let index = Float(i) / factor
            let lowerIndex = Int(index.rounded(.down))
            let upperIndex = Swift.min(lowerIndex + 1, size - 1)

            let weight = index - Float(lowerIndex)
            let interpolatedValue = (1 - weight) * self[lowerIndex] + weight * self[upperIndex]
            upsampled[i] = interpolatedValue
        }

        return upsampled
    }
}
