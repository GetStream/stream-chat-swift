//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// An object responsible to coordinate the audio analysis pipeline
public struct AudioAnalysisEngine {
    /// The loader that will be called to when loading asset properties is required
    private let assetPropertiesLoader: AssetPropertyLoading

    /// The analyser that will be used to analyse an audio file
    private let audioAnalyser: AudioAnalysing

    public init() throws {
        try self.init(assetPropertiesLoader: StreamAssetPropertyLoader())
    }

    public init(
        assetPropertiesLoader: AssetPropertyLoading
    ) throws {
        self.init(
            assetPropertiesLoader: assetPropertiesLoader,
            audioAnalyser: StreamAudioWaveformAnalyser(
                audioSamplesExtractor: .init(),
                audioSamplesProcessor: .init(),
                audioSamplesPercentageNormaliser: .init(),
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsNonInterleaved: false
                ]
            )
        )
    }

    init(
        assetPropertiesLoader: AssetPropertyLoading,
        audioAnalyser: AudioAnalysing
    ) {
        self.assetPropertiesLoader = assetPropertiesLoader
        self.audioAnalyser = audioAnalyser
    }

    /// Analyses the file located in the audioURL and calculates its waveform representation limited to the
    /// number of requested targetSamples.
    /// - Parameters:
    ///   - audioURL: The path to the audio file
    ///   - targetSamples: The number of waveform points to be returned
    ///   - completionHandler: The completion handler to call once the analysis has been completed
    public func waveformVisualisation(
        fromAudioURL audioURL: URL,
        for targetSamples: Int,
        completionHandler: @escaping (Result<[Float], Error>) -> Void
    ) {
        let asset = AVURLAsset(
            url: audioURL,
            options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)
            ]
        )

        assetPropertiesLoader.loadProperties(
            [.init(\.duration)],
            of: asset
        ) { result in
            switch result {
            case let .success(loadedAsset):
                do {
                    let audioAnalysisContext = AudioAnalysisContext(from: loadedAsset, audioURL: audioURL)
                    let result = try audioAnalyser.analyse(
                        audioAnalysisContext: audioAnalysisContext,
                        for: targetSamples
                    )
                    completionHandler(.success(result))
                } catch {
                    completionHandler(.failure(error))
                }
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    /// Analyses the live recording file located in the audioURL and calculates its waveform representation
    /// limited to the number of requested targetSamples.
    /// - Parameters:
    ///   - audioURL: The path to the audio file
    ///   - targetSamples: The number of waveform points to be returned
    /// - Returns: The waveform points
    public func waveformVisualisation(
        fromLiveAudioURL audioURL: URL,
        for targetSamples: Int
    ) throws -> [Float] {
        let asset = AVURLAsset(
            url: audioURL,
            options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)
            ]
        )

        let audioAnalysisContext = AudioAnalysisContext(from: asset, audioURL: audioURL)

        return try audioAnalyser.analyse(
            audioAnalysisContext: audioAnalysisContext,
            for: targetSamples
        )
    }
}

// MARK: - Errors

public final class AudioAnalysisEngineError: ClientError {
    /// An error occurred when the Audio track cannot be loaded from the AudioFile provided.
    public static func failedToLoadAVAssetTrack(file: StaticString = #file, line: UInt = #line) -> AudioAnalysisEngineError {
        .init("Failed to load AVAssetTrack.", file, line)
    }

    /// An error occurred when the AudioFormatDescriptions cannot be loaded from the AudioFile provided.
    public static func failedToLoadFormatDescriptions(file: StaticString = #file, line: UInt = #line) -> AudioAnalysisEngineError {
        .init("Failed to load format descriptions.", file, line)
    }
}
