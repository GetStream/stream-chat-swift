//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Accelerate
import AVFoundation

/// An object with the purpose to prepare the provided audio data for visualisation or further processing.
internal class AudioSamplesProcessor {
    let noiseFloor: Float

    /// Creates a new instances with the desired noiseFloor value
    /// - Parameter noiseFloor: The value which we will use as noiseFloor. Any value greater than
    /// this one will be considered silence.
    /// - Note: Default value: -50
    init(noiseFloor: Float = -50) {
        self.noiseFloor = noiseFloor
    }

    /// The processing flow includes:
    /// - 1. Convert 16-bit integer audio samples to floating-point values
    /// - 2. Calculates the amplitude of each sample
    /// - 3. Convert the amplitude to decibels
    /// - 4. Downsample and average the values using a filter
    /// - Parameters:
    ///   - sampleBuffer: The buffer containing the all the samples (including the ones we will process)
    ///   - outputSamples: The array in which we will store the processed samples
    ///   - samplesToProcess: The number of samples we want to process
    ///   - downSampledLength: The number of the processed samples we will output
    ///   - downsamplingRate: An integer value that determines the downsampling rate
    ///   - filter: The filter to be used to smooth the result by applying a weighting function to the neighboring elements.
    /// - Returns: The resulting array of downsampled values.
    func processSamples(
        fromData sampleBuffer: inout Data,
        outputSamples: inout [Float],
        samplesToProcess: Int,
        downSampledLength: Int,
        downsamplingRate: Int,
        filter: [Float]
    ) {
        sampleBuffer.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            let processedSamples = self.process(
                body,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                downsamplingRate: downsamplingRate,
                filter: filter
            )

            guard !processedSamples.isEmpty else { return }

            sampleBuffer
                .removeFirst(samplesToProcess * MemoryLayout<Int16>.size)

            outputSamples += processedSamples
        }
    }

    // MARK: - Private Helpers

    private func process(
        _ body: UnsafeRawBufferPointer,
        samplesToProcess: Int,
        downSampledLength: Int,
        downsamplingRate: Int,
        filter: [Float]
    ) -> [Float] {
        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)

        /// This line declares a constant length that stores the count of the input array of
        /// samples converted to `vDSP_Length`, which is an integer type that the vDSP
        /// library uses to specify the length of arrays.
        let sampleCount = vDSP_Length(samplesToProcess)

        guard let samples = body.bindMemory(to: Int16.self).baseAddress else {
            return []
        }

        /// Apply the vDSP function vDSP_vflt16 to the samples array, converting the 16-bit integer
        /// samples to floating-point values.
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)

        /// Apply the vDSP function vDSP_vabs to the processingBuffer array, taking the absolute value
        /// of each sample to obtain its amplitude.
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)

        /// Convert the amplitudes of the processingBuffer array to decibel (dB) units and clip the result.
        getdB(from: &processingBuffer)

        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)

        /// Apply the vDSP function vDSP_desamp to the processingBuffer array, using the specified
        /// filter and parameters to downsample and average the array values.
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

    private func getdB(
        from normalizedSamples: inout [Float]
    ) {
        /// This line declares a constant length that stores the count of the input array of
        /// normalizedSamples converted to `vDSP_Length`, which is an integer type that the vDSP
        /// library uses to specify the length of arrays.
        let length = vDSP_Length(normalizedSamples.count)

        /// Α variable - representing zero - that is initialised with the reference level for dB calculation.
        var zero: Float = Float(Int16.max)

        /// Converts the linear scale of the input array to a logarithmic scale and stores the result
        /// in normalizedSamples.
        vDSP_vdbcon(
            normalizedSamples,
            1,
            &zero,
            &normalizedSamples,
            1,
            length,
            1
        )

        /// Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable = noiseFloor

        /// Clip into the range between noiseFloorMutable and ceil. This means that any sample value
        /// below noiseFloorMutable is set to noiseFloorMutable, and any sample value above ceil is set
        /// to ceil. The result is stored in normalizedSamples.
        /// - Note: `AVAudioRecorder` power meters have value in the range of -160 to 0.
        vDSP_vclip(
            normalizedSamples,
            1,
            &noiseFloorMutable,
            &ceil,
            &normalizedSamples,
            1,
            length
        )
    }
}
