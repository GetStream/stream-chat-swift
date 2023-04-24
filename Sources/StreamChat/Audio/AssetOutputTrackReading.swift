//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Accelerate
import AVFoundation
import Foundation

public protocol AssetOutputTrackReading {
    static func build() -> AssetOutputTrackReading

    func outputSamples<Asset: AVAsset>(
        from asset: Asset,
        targetSampleCount: Int,
        completion: @escaping (Result<[Float], Error>) -> Void
    )
}

public struct AssetOutputTrackReadingNoAudioTrackFound: Error {}
public struct AssetOutputTrackReadingNoAudioSamplesFound: Error {}
public struct AssetOutputTrackReadingNoAudioTrackOutputFound: Error {}

open class StreamAssetOutputTrackReader: AssetOutputTrackReading {
    private let assetPropertyLoader: AssetPropertyLoading
    private let noiseFloorDecibelCutoff: Float
    private let outputSettings: [String: Any]
    private let dispatchQueue: DispatchQueue

    public static func build() -> AssetOutputTrackReading {
        StreamAssetOutputTrackReader(
            assetPropertyLoader: StreamAssetPropertyLoader(),
            noiseFloorDecibelCutoff: -50.0,
            outputSettings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsNonInterleaved: false
            ],
            dispatchQueue: .global(qos: .userInteractive)
        )
    }

    public init(
        assetPropertyLoader: AssetPropertyLoading,
        noiseFloorDecibelCutoff: Float,
        outputSettings: [String: Any],
        dispatchQueue: DispatchQueue
    ) {
        self.assetPropertyLoader = assetPropertyLoader
        self.noiseFloorDecibelCutoff = noiseFloorDecibelCutoff
        self.outputSettings = outputSettings
        self.dispatchQueue = dispatchQueue
    }

    open func outputSamples<Asset: AVAsset>(
        from asset: Asset,
        targetSampleCount: Int,
        completion: @escaping (Result<[Float], Error>) -> Void
    ) {
        guard targetSampleCount > 0 else {
            completion(.success([]))
            return
        }

        assetPropertyLoader.loadProperties([.init(\.duration)], of: asset) { [weak self] result in
            switch result {
            case let .success(asset):
                self?.dispatchQueue.async {
                    self?.process(
                        asset: asset,
                        targetSampleCount: targetSampleCount,
                        completion: completion
                    )
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    open func process<Asset: AVAsset>(
        asset: Asset,
        targetSampleCount: Int,
        completion: @escaping (Result<[Float], Error>) -> Void
    ) {
        guard
            let audioTrack = asset.tracks(withMediaType: .audio).first
        else {
            completion(.failure(AssetOutputTrackReadingNoAudioTrackFound()))
            return
        }

        let totalSamples = audioTrack.totalNumberOfSamples

        guard totalSamples > 0 else {
            completion(.failure(AssetOutputTrackReadingNoAudioSamplesFound()))
            return
        }

        do {
            let outputSamples = try processOutputSamples(
                asset,
                audioTrack: audioTrack,
                totalSamples: totalSamples,
                targetSampleCount: targetSampleCount
            )

            let targetSamples = Array(outputSamples[0..<targetSampleCount])
            completion(.success(normalizeOutputSamples(targetSamples)))
        } catch {
            completion(.failure(error))
        }
    }

    open func processOutputSamples<Asset: AVAsset>(
        _ asset: Asset,
        audioTrack: AVAssetTrack,
        totalSamples: Int,
        targetSampleCount: Int
    ) throws -> [Float] {
        var outputSamples = [Float]()
        var sampleBuffer: Data = .init()
        let assetReader = try AVAssetReader(asset: asset)
        // read upfront to avoid frequent re-calculation (and memory bloat
        // from C-bridging).
        let samplesPerPixel = max(1, totalSamples / targetSampleCount)

        let trackOutput = AVAssetReaderTrackOutput(
            track: audioTrack,
            outputSettings: outputSettings
        )
        assetReader.add(trackOutput)

        assetReader.startReading()
        while assetReader.status == .reading {
            guard
                let trackOutput = assetReader.outputs.first,
                let nextSampleBuffer = trackOutput.copyNextSampleBuffer(),
                let blockBuffer = CMSampleBufferGetDataBuffer(nextSampleBuffer)
            else {
                break
            }
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?

            CMBlockBufferGetDataPointer(
                blockBuffer,
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

            CMSampleBufferInvalidate(nextSampleBuffer)

            let processesBufferSamples = processSampleBuffer(
                sampleBuffer,
                downSampleTo: samplesPerPixel
            )
            outputSamples += processesBufferSamples

            if !processesBufferSamples.isEmpty {
                // vDSP_desamp uses strides of samplesPerPixel; remove only
                // the processed ones
                sampleBuffer.removeFirst(
                    processesBufferSamples.count * samplesPerPixel * MemoryLayout<Int16>.size
                )

                // this takes care of a memory leak where Memory continues to
                // increase even though it should clear after calling
                // .removeFirst(…) above.
                sampleBuffer = Data(sampleBuffer)
            }
        }

        // if we don't have enough pixels yet,
        // process leftover samples with padding (to reach multiple of
        // samplesPerPixel for vDSP_desamp)
        if outputSamples.count < targetSampleCount {
            let missingSampleCount = (targetSampleCount - outputSamples.count) * samplesPerPixel
            let backfillPaddingSampleCount = missingSampleCount - (sampleBuffer.count / MemoryLayout<Int16>.size)
            let backfillPaddingSampleCount16 = backfillPaddingSampleCount * MemoryLayout<Int16>.size
            let backfillPaddingSamples = [UInt8](repeating: 0, count: backfillPaddingSampleCount16)
            sampleBuffer.append(backfillPaddingSamples, count: backfillPaddingSampleCount16)
            let processedSamples = processSampleBuffer(sampleBuffer, downSampleTo: samplesPerPixel)
            outputSamples += processedSamples
        }

        return outputSamples
    }

    open func processSampleBuffer(
        _ sampleBuffer: Data,
        downSampleTo noOfSamples: Int
    ) -> [Float] {
        var downSampledData = [Float]()
        let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size

        // guard for crash in very long audio files
        guard sampleLength / noOfSamples > 0 else {
            return downSampledData
        }

        sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
            let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)

            guard let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress else {
                return
            }

            var loudestClipValue: Float = 0.0
            var quietestClipValue = noiseFloorDecibelCutoff
            var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
            let samplesToProcess = vDSP_Length(sampleLength)

            var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
            vDSP_vflt16(unsafeSamplesPointer, 1, &processingBuffer, 1, samplesToProcess) // convert 16bit int to float (
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess) // absolute amplitude value
            vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1) // convert to DB
            vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

            let filter = [Float](repeating: 1.0 / Float(noOfSamples), count: noOfSamples)
            let downSampledLength = sampleLength / noOfSamples
            downSampledData = [Float](repeating: 0.0, count: downSampledLength)

            vDSP_desamp(
                processingBuffer,
                vDSP_Stride(noOfSamples),
                filter,
                &downSampledData,
                vDSP_Length(downSampledLength),
                vDSP_Length(noOfSamples)
            )
        }

        return downSampledData
    }

    open func normalizeOutputSamples(
        _ outputSamples: [Float]
    ) -> [Float] {
        outputSamples
            .map { min(1, $0 / noiseFloorDecibelCutoff) }
            .map { 1 - $0 }
    }
}

extension AVAssetTrack {
    var totalNumberOfSamples: Int {
        guard
            let descriptions = formatDescriptions as? [CMFormatDescription],
            let asset = asset
        else {
            return 0
        }

        return descriptions
            .compactMap { CMAudioFormatDescriptionGetStreamBasicDescription($0) }
            .reduce(0) { _, formatDescription in
                let channelCount = Int(formatDescription.pointee.mChannelsPerFrame)
                let sampleRate = formatDescription.pointee.mSampleRate
                let duration = Double(asset.duration.value)
                let timescale = Double(asset.duration.timescale)
                let totalDuration = duration / timescale
                return Int(sampleRate * totalDuration) * channelCount
            }
    }
}
