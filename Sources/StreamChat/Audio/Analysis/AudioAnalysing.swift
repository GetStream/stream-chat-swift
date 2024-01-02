//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Describes an object that given an `AudioAnalysisContext` will analyse and process it in order to
/// generate a set of data points that describe some characteristics of the audio track provided from the
/// context.
protocol AudioAnalysing {
    /// Analyse and process the provided context and provide data points limited to the number of the
    /// targetSamples.
    /// - Parameters:
    ///   - context: The `AudioAnalysisContext` which we want to analyse
    ///   - targetSamples: The number of expected data points we want the analyser to output
    /// - Returns: The processed samples limited by the number of targetSamples
    func analyse(
        audioAnalysisContext context: AudioAnalysisContext,
        for targetSamples: Int
    ) throws -> [Float]
}

/// An implementation of `AudioAnalysing` that processes an `AudioAnalysisContext` in order
/// to provide information for the visualisation of the audio's waveform.
final class StreamAudioWaveformAnalyser: AudioAnalysing {
    private let audioSamplesExtractor: AudioSamplesExtractor
    private let audioSamplesProcessor: AudioSamplesProcessor
    private let audioSamplesPercentageNormaliser: AudioValuePercentageNormaliser
    private let outputSettings: [String: Any]

    init(
        audioSamplesExtractor: AudioSamplesExtractor,
        audioSamplesProcessor: AudioSamplesProcessor,
        audioSamplesPercentageNormaliser: AudioValuePercentageNormaliser,
        outputSettings: [String: Any]
    ) {
        self.audioSamplesExtractor = audioSamplesExtractor
        self.audioSamplesProcessor = audioSamplesProcessor
        self.audioSamplesPercentageNormaliser = audioSamplesPercentageNormaliser
        self.outputSettings = outputSettings
    }

    func analyse(
        audioAnalysisContext context: AudioAnalysisContext,
        for targetSamples: Int
    ) throws -> [Float] {
        guard
            let reader = try? AVAssetReader(asset: context.asset)
        else {
            throw AudioAnalysingError.failedToReadAsset()
        }

        let totalSamples = context.totalSamples
        let sampleRange = 0..<totalSamples
        let startTime = CMTime(value: Int64(sampleRange.lowerBound), timescale: context.asset.duration.timescale)
        let duration = CMTime(value: Int64(sampleRange.count), timescale: context.asset.duration.timescale)

        guard
            let assetTrack = context.assetTrack
        else {
            throw AudioAnalysingError.failedToReadAsset()
        }

        let readerOutput = AVAssetReaderTrackOutput(
            track: assetTrack,
            outputSettings: outputSettings
        )
        readerOutput.alwaysCopiesSampleData = false

        reader.timeRange = CMTimeRange(start: startTime, duration: duration)
        reader.add(readerOutput)

        /// Calculate the downsampling rate, which is the factor by which the sample rate will be reduced
        /// to achieve the desired target sample rate. The channelCount variable is the number of audio
        /// channels, and sampleRange.count is the number of audio samples in the selected range.
        /// The max(1, ...) part ensures that the downsampling rate is always at least 1, which means that
        /// the audio will be processed at the original sample rate if the target sample rate is higher than
        /// the current one.
        let downsamplingRate = max(1, sampleRange.count / targetSamples)

        /// The filter array is a low-pass filter kernel that emphasises lower frequencies and attenuates
        /// higher frequencies, to remove high-frequency noise and avoid aliasing artifacts during the
        /// downsampling process.
        let filter = [Float](repeating: 1.0 / Float(downsamplingRate), count: downsamplingRate)
        var outputSamples = [Float]()
        var sampleBuffer = Data()

        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }

        while reader.status == .reading {
            /// Extract the audio samples from the next sample buffer read by the reader, downsample
            /// them using the specified downsampling rate, and store them in the sampleBuffer variable.
            /// The extractionResult variable returned by the method contains information about the
            /// number of samples extracted and the length of the downsampled audio.
            let extractionResult = audioSamplesExtractor.extractSamples(
                from: readerOutput.copyNextSampleBuffer(),
                sampleBuffer: &sampleBuffer,
                downsamplingRate: downsamplingRate
            )

            /// Skip the current iteration of the loop if no samples were extracted from the current
            /// sample buffer.
            guard extractionResult.samplesToProcess > 0 else { continue }

            /// Process the audio samples stored in sampleBuffer, apply the low-pass filter, downsample
            /// them further, and store them in the outputSamples array.
            audioSamplesProcessor.processSamples(
                fromData: &sampleBuffer,
                outputSamples: &outputSamples,
                samplesToProcess: extractionResult.samplesToProcess,
                downSampledLength: extractionResult.downSampledLength,
                downsamplingRate: downsamplingRate,
                filter: filter
            )
        }

        /// Process the remaining samples at the end which didn't fit into samplesPerPixel.  This is
        /// necessary to ensure that all audio data is processed.
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](
                repeating: 1.0 / Float(samplesPerPixel),
                count: samplesPerPixel
            )

            audioSamplesProcessor.processSamples(
                fromData: &sampleBuffer,
                outputSamples: &outputSamples,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                downsamplingRate: samplesPerPixel,
                filter: filter
            )
        }

        guard reader.status == .completed || true else {
            throw AudioAnalysingError.failedToReadAudioFile()
        }

        /// Return the output samples after applying a final transformation into percentages.
        return audioSamplesPercentageNormaliser.normalise(outputSamples)
    }
}

// MARK: - Errors

final class AudioAnalysingError: ClientError {
    /// Failed to read the asset provided by the `AudioAnalysisContext`
    static func failedToReadAsset(file: StaticString = #file, line: UInt = #line) -> AudioAnalysingError {
        .init("Failed to read AVAsset.", file, line)
    }

    /// Failed to read the data from the provided Audio file
    static func failedToReadAudioFile(file: StaticString = #file, line: UInt = #line) -> AudioAnalysingError {
        .init("Failed to read audio file.", file, line)
    }
}
