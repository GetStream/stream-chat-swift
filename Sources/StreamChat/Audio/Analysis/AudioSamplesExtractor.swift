//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// An object responsible for: 1. extracting audio samples into the provided buffer, 2. calculating the number
/// of samples to process based on the provided downsamplingRate.
///
/// - Note: Audio samples are expected to be stored in Int16 format.
internal class AudioSamplesExtractor {
    /// A struct to represent the result of the extractSamples method
    struct Result: Equatable { var samplesToProcess, downSampledLength: Int }

    init() {}

    /// Extracts samples from the provided buffer and calculates the number of samples to process
    /// based on the provided `samplesPerPixel` (downsample).
    /// - Parameters:
    ///   - readSampleBuffer: An optional CMSampleBuffer containing audio samples
    ///   - sampleBuffer: An inout parameter of type Data representing the current buffer of audio samples
    ///   - downsamplingRate: An integer value that determines the downsampling rate
    /// - Returns: a struct containing the information regarding processing and downsampling
    func extractSamples(
        from readSampleBuffer: CMSampleBuffer?,
        sampleBuffer: inout Data,
        downsamplingRate: Int
    ) -> Result {
        guard
            let readSampleBuffer = readSampleBuffer,
            let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer)
        else {
            /// If either of them is nil, return a Result with both properties set to 0
            return .init(samplesToProcess: 0, downSampledLength: 0)
        }

        /// Append the audio sample buffer into our current sample buffer
        var readBufferLength = 0
        var readBufferPointer: UnsafeMutablePointer<Int8>?

        /// Get the data pointer for the readBuffer
        CMBlockBufferGetDataPointer(
            readBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &readBufferLength,
            totalLengthOut: nil,
            dataPointerOut: &readBufferPointer
        )

        /// Append the samples in readBuffer to the end of our sampleBuffer
        sampleBuffer.append(
            UnsafeBufferPointer(
                start: readBufferPointer,
                count: readBufferLength
            )
        )

        /// Invalidate readSampleBuffer to mark it as processed
        CMSampleBufferInvalidate(readSampleBuffer)

        /// Dividing the length of the buffer (in bytes) by the size of an Int16 (also in bytes) gives us the
        /// number of `Int16` values in the buffer, which is equivalent to the number of audio samples.
        /// This calculation gives us the total number of samples in sampleBuffer, which is needed to
        /// determine the length of the downsampled buffer and the number of samples to process.
        let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size

        /// Calculate the length of the downsampled buffer
        let downSampledLength = totalSamples / downsamplingRate

        /// The downsampledLength calculated earlier tells us how many samples are kept in the
        /// downsampled buffer. But since we're only keeping every downsamplingRate'th sample, we
        /// need to multiply the downsampledLength by downsamplingRate to get the total number of
        /// samples that will be processed.
        ///
        /// - Note: This is expected in most cases to be equal to the `totalSamples` that we
        /// calculated above.
        let samplesToProcess = downSampledLength * downsamplingRate

        /// Return a Result with the samplesToProcess and downSampledLength properties
        return .init(samplesToProcess: samplesToProcess, downSampledLength: downSampledLength)
    }
}
