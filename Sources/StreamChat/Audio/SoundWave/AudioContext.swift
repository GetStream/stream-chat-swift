//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Accelerate
import AVFoundation

public struct AudioAnalysisContextLoadFailedToLoadAVAssetTrack: Error {}
public struct AudioAnalysisContextLoadFailedToLoadFormatDescriptions: Error {}

public struct AudioAnalysisFactory {
    public let assetPropertiesLoader: AssetPropertyLoading

    public init(assetPropertiesLoader: AssetPropertyLoading) {
        self.assetPropertiesLoader = assetPropertiesLoader
    }

    public func buildAudioRenderer(
        fromAudioURL audioURL: URL,
        completionHandler: @escaping (Result<AudioRendering, Error>) -> Void
    ) {
        AudioAnalysisContext.build(
            fromAudioURL: audioURL,
            using: assetPropertiesLoader
        ) { result in
            switch result {
            case let .success(context):
                completionHandler(.success(
                    StreamAudioRenderer(
                        context,
                        audioSamplesProvider: StreamAudioSamplesProvider(),
                        audioSamplesProcessor: StreamAudioSamplesProcessor(),
                        audioSamplesTransformer: StreamAudioSamplesPercentageTransformer()
                    )))
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    public func buildAudioRenderer(
        fromLiveAudioURL audioURL: URL
    ) -> Result<AudioRendering, Error> {
        let result = AudioAnalysisContext.build(fromLiveAudioURL: audioURL)

        switch result {
        case let .success(context):
            return .success(
                StreamAudioRenderer(
                    context,
                    audioSamplesProvider: StreamAudioSamplesProvider(),
                    audioSamplesProcessor: StreamAudioSamplesProcessor(),
                    audioSamplesTransformer: StreamAudioSamplesPercentageTransformer()
                ))
        case let .failure(error):
            return .failure(error)
        }
    }
}

public struct AudioAnalysisContext {
    public let audioURL: URL
    public let totalSamples: Int
    public let asset: AVAsset
    public let assetTrack: AVAssetTrack

    public static func build(
        fromAudioURL audioURL: URL,
        using assetPropertiesLoader: AssetPropertyLoading,
        completionHandler: @escaping (Result<AudioAnalysisContext, Error>) -> Void
    ) {
        let asset = AVURLAsset(
            url: audioURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)
            ]
        )

        guard
            let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        else {
            completionHandler(.failure(AudioAnalysisContextLoadFailedToLoadAVAssetTrack()))
            return
        }

        assetPropertiesLoader.loadProperties(
            [.init(\.duration)],
            of: asset
        ) { result in
            switch result {
            case let .success(loadedAsset):
                guard
                    let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
                    let audioFormatDesc = formatDescriptions.first,
                    let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                else {
                    completionHandler(.failure(AudioAnalysisContextLoadFailedToLoadFormatDescriptions()))
                    return
                }

                // The total number of samples in the audio track is calculated
                // using the duration and the sample rate of the basic audio
                // format description.
                let totalSamples = Int(
                    (basicDescription.pointee.mSampleRate) * Float64(loadedAsset.duration.value) / Float64(loadedAsset.duration.timescale)
                )
                completionHandler(.success(.init(
                    audioURL: audioURL,
                    totalSamples: totalSamples,
                    asset: loadedAsset,
                    assetTrack: assetTrack
                )))

            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    public static func build(
        fromLiveAudioURL audioURL: URL
    ) -> Result<AudioAnalysisContext, Error> {
        let loadedAsset = AVURLAsset(
            url: audioURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)
            ]
        )

        guard
            let assetTrack = loadedAsset.tracks(withMediaType: AVMediaType.audio).first
        else {
            return .failure(AudioAnalysisContextLoadFailedToLoadAVAssetTrack())
        }

        guard
            let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
            let audioFormatDesc = formatDescriptions.first,
            let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
        else {
            return .failure(AudioAnalysisContextLoadFailedToLoadFormatDescriptions())
        }

        // The total number of samples in the audio track is calculated
        // using the duration and the sample rate of the basic audio
        // format description.
        let totalSamples = Int(
            (basicDescription.pointee.mSampleRate) * Float64(loadedAsset.duration.value) / Float64(loadedAsset.duration.timescale)
        )
        return .success(.init(
            audioURL: audioURL,
            totalSamples: totalSamples,
            asset: loadedAsset,
            assetTrack: assetTrack
        ))
    }

    private init(
        audioURL: URL,
        totalSamples: Int,
        asset: AVAsset, assetTrack: AVAssetTrack
    ) {
        self.audioURL = audioURL
        self.totalSamples = totalSamples
        self.asset = asset
        self.assetTrack = assetTrack
    }
}

public protocol AudioRendering {
    func render(targetSamples: Int) -> [Float]
}

public struct StreamAudioRendererFailedToReadAsset: Error {}
public struct StreamAudioRendererFailedToLoadFormatDescriptions: Error {}
public struct StreamAudioRendererFailedToReadAudioFile: Error {}

open class StreamAudioRenderer: AudioRendering {
    private let context: AudioAnalysisContext
    private let audioSamplesProvider: AudioSamplesProviding
    private let audioSamplesProcessor: AudioSamplesProcessing
    private let audioSamplesTransformer: AudioSamplesTransforming

    public init(
        _ audioAnalysisContext: AudioAnalysisContext,
        audioSamplesProvider: AudioSamplesProviding,
        audioSamplesProcessor: AudioSamplesProcessing,
        audioSamplesTransformer: AudioSamplesTransforming
    ) {
        context = audioAnalysisContext
        self.audioSamplesProvider = audioSamplesProvider
        self.audioSamplesProcessor = audioSamplesProcessor
        self.audioSamplesTransformer = audioSamplesTransformer
    }

    open var totalSamples: Int { context.totalSamples }
    open var sampleRange: CountableRange<Int> { 0..<(totalSamples / 3) }
    open var startTime: CMTime { CMTime(value: Int64(sampleRange.lowerBound), timescale: context.asset.duration.timescale) }
    open var duration: CMTime { CMTime(value: Int64(sampleRange.count), timescale: context.asset.duration.timescale) }
    open var outputSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }

    open func render(
        targetSamples: Int
    ) -> [Float] {
        guard let reader = try? AVAssetReader(asset: context.asset) else {
            log.error(StreamAudioRendererFailedToReadAsset())
            return []
        }

        reader.timeRange = CMTimeRange(start: startTime, duration: duration)

        let readerOutput = AVAssetReaderTrackOutput(
            track: context.assetTrack,
            outputSettings: outputSettings
        )
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)

        guard
            let formatDescriptions = context.assetTrack.formatDescriptions as? [CMAudioFormatDescription]
        else {
            log.error(StreamAudioRendererFailedToLoadFormatDescriptions())
            return []
        }

        let channelCount = formatDescriptions.reduce(0) { partialResult, formatDescription in
            guard
                let basicFormatDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
            else {
                return partialResult
            }
            return Int(basicFormatDescription.pointee.mChannelsPerFrame)
        }

        let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        var outputSamples = [Float]()
        var sampleBuffer = Data()

        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }

        while reader.status == .reading {
            let (samplesToProcess, downSampledLength) = audioSamplesProvider
                .samplesToProcess(
                    from: readerOutput.copyNextSampleBuffer(),
                    sampleBuffer: &sampleBuffer,
                    samplesPerPixel: samplesPerPixel
                )

            guard samplesToProcess > 0 else { continue }

            audioSamplesProcessor.processSamples(
                fromData: &sampleBuffer,
                outputSamples: &outputSamples,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                samplesPerPixel: samplesPerPixel,
                filter: filter
            )
        }

        // Process the remaining samples at the end which didn't fit into samplesPerPixel
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
                samplesPerPixel: samplesPerPixel,
                filter: filter
            )
        }

        guard reader.status == .completed || true else {
            log.error(StreamAudioRendererFailedToReadAudioFile())
            return []
        }

        return audioSamplesTransformer.transform(outputSamples)
    }
}

public protocol AudioSamplesProcessing {
    func processSamples(
        fromData sampleBuffer: inout Data,
        outputSamples: inout [Float],
        samplesToProcess: Int,
        downSampledLength: Int,
        samplesPerPixel: Int,
        filter: [Float]
    )
}

open class StreamAudioSamplesProcessor: AudioSamplesProcessing {
    open func processSamples(
        fromData sampleBuffer: inout Data,
        outputSamples: inout [Float],
        samplesToProcess: Int,
        downSampledLength: Int,
        samplesPerPixel: Int,
        filter: [Float]
    ) {
        sampleBuffer.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            let processedSamples = self.process(
                body,
                samplesToProcess: samplesToProcess,
                downSampledLength: downSampledLength,
                samplesPerPixel: samplesPerPixel,
                filter: filter
            )

            guard !processedSamples.isEmpty else { return }

            sampleBuffer
                .removeFirst(samplesToProcess * MemoryLayout<Int16>.size)

            outputSamples += processedSamples
        }
    }

    private func process(
        _ body: UnsafeRawBufferPointer,
        samplesToProcess: Int,
        downSampledLength: Int,
        samplesPerPixel: Int,
        filter: [Float]
    ) -> [Float] {
        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
        let sampleCount = vDSP_Length(samplesToProcess)

        guard let samples = body.bindMemory(to: Int16.self).baseAddress else {
            return []
        }

        // Convert 16bit int samples to floats
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)

        // Take the absolute values to get amplitude
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)

        // Get the corresponding dB, and clip the results
        getdB(from: &processingBuffer)

        // Downsample and average
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)

        vDSP_desamp(
            processingBuffer,
            vDSP_Stride(samplesPerPixel),
            filter,
            &downSampledData,
            vDSP_Length(downSampledLength),
            vDSP_Length(samplesPerPixel)
        )

        return downSampledData
    }

    private func getdB(
        from normalizedSamples: inout [Float]
    ) {
        let length = vDSP_Length(normalizedSamples.count)
        // Convert samples to a log scale
        var zero: Float = 32768.0
        vDSP_vdbcon(
            normalizedSamples,
            1,
            &zero,
            &normalizedSamples,
            1,
            length,
            1
        )

        // Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable: Float = -80.0 // TODO: CHANGE THIS VALUE
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

public protocol AudioSamplesProviding {
    func samplesToProcess(
        from readSampleBuffer: CMSampleBuffer?,
        sampleBuffer: inout Data,
        samplesPerPixel: Int
    ) -> (samplesToProcess: Int, downSampledLength: Int)
}

open class StreamAudioSamplesProvider: AudioSamplesProviding {
    open func samplesToProcess(
        from readSampleBuffer: CMSampleBuffer?,
        sampleBuffer: inout Data,
        samplesPerPixel: Int
    ) -> (samplesToProcess: Int, downSampledLength: Int) {
        guard
            let readSampleBuffer = readSampleBuffer,
            let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer)
        else {
            return (0, 0)
        }

        // Append audio sample buffer into our current sample buffer
        var readBufferLength = 0
        var readBufferPointer: UnsafeMutablePointer<Int8>?

        CMBlockBufferGetDataPointer(
            readBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &readBufferLength,
            totalLengthOut: nil,
            dataPointerOut: &readBufferPointer
        )

        sampleBuffer.append(
            UnsafeBufferPointer(
                start: readBufferPointer,
                count: readBufferLength
            )
        )

        CMSampleBufferInvalidate(readSampleBuffer)

        let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
        let downSampledLength = totalSamples / samplesPerPixel
        let samplesToProcess = downSampledLength * samplesPerPixel

        return (samplesToProcess, downSampledLength)
    }
}

public protocol AudioSamplesTransforming {
    func transform(_ samples: [Float]) -> [Float]
}

open class StreamAudioSamplesPercentageTransformer: AudioSamplesTransforming {
    public func transform(_ samples: [Float]) -> [Float] {
        guard let firstElement = samples.first else {
            return []
        }

        let absArray = samples.map { abs($0) }
        let minValue = absArray.reduce(firstElement) { min($0, $1) }
        let maxValue = absArray.reduce(firstElement) { max($0, $1) }
        let delta = maxValue - minValue
        return absArray.map { abs(1 - (delta / ($0 - minValue))) }
    }
}
