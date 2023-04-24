//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
import StreamChatTestTools
import XCTest

final class StreamAudioWaveformAnalyser_Tests: XCTestCase {
    private lazy var assetDuration: CMTime! = CMTime(seconds: 124, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

    private lazy var audioFilePath: String! = Bundle(for: type(of: self))
        .path(forResource: "test_audio_file", ofType: "m4a")!
    private lazy var audioSamplesExtractor: SpyAudioSamplesExtractor! = .init()
    private lazy var audioSamplesProcessor: SpyAudioSamplesProcessor! = .init()
    private lazy var audioSamplesPercentageTransformer: SpyAudioSamplesPercentageTransformer! = .init()
    private lazy var outputSettings: [String: Any]! = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsNonInterleaved: false
    ]
    private lazy var subject: StreamAudioWaveformAnalyser! = .init(
        audioSamplesExtractor: audioSamplesExtractor,
        audioSamplesProcessor: audioSamplesProcessor,
        audioSamplesPercentageTransformer: audioSamplesPercentageTransformer,
        outputSettings: outputSettings
    )

    override func tearDown() {
        subject = nil
        outputSettings = nil
        audioSamplesPercentageTransformer = nil
        audioSamplesProcessor = nil
        audioSamplesExtractor = nil
        audioFilePath = nil
        super.tearDown()
    }

    // MARK: - analyse(audioAnalysisContext:for:)

    func test_analyse_cannotReadAsset_throwsError() throws {
        assertThrowsClientError(
            { _ = try subject.analyse(audioAnalysisContext: makeAudioAnalysisContext(.unique()), for: 0) },
            AudioAnalysingError.failedToReadAsset()
        )
    }

    func test_analyse_assetTrackIsNil_throwsError() throws {
        let asset = MockAVURLAsset(url: .init(fileURLWithPath: audioFilePath))
        asset.stubProperty(\.duration, with: assetDuration)

        assertThrowsClientError(
            { _ = try subject.analyse(audioAnalysisContext: makeAudioAnalysisContext(asset: asset), for: 0) },
            AudioAnalysingError.failedToLoadFormatDescriptions()
        )
    }

    func test_analyse_completesSuccessfullyAndReturnsExpectedResult() throws {
        let asset = AVAsset(url: .init(fileURLWithPath: audioFilePath))
        let context = try AudioAnalysisContext(from: asset, audioURL: .init(fileURLWithPath: audioFilePath))
        let expected: [Float] = [
            0.40989828,
            0.039050672,
            0.23860154,
            0.39069766,
            0.18528144,
            0.0,
            0.12881927,
            0.20159021,
            0.030400243,
            1.0
        ]

        let actual = try subject.analyse(audioAnalysisContext: context, for: 10)

        for (offset, element) in actual.enumerated() {
            XCTAssertEqual(element, expected[offset], accuracy: 0.001)
        }
    }

    // MARK: - Private Helpers

    func makeAudioAnalysisContext(
        _ audioURL: URL? = nil,
        totalSamples: Int = 0,
        asset: AVAsset? = nil,
        assetTrack: AVAssetTrack? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> AudioAnalysisContext {
        let audioURL = audioURL ?? .init(fileURLWithPath: audioFilePath)
        let asset = asset ?? AVAsset(url: audioURL)
        let assetTrack = assetTrack
        return .init(
            audioURL: audioURL,
            totalSamples: totalSamples,
            asset: asset,
            assetTrack: assetTrack
        )
    }

    private func assertThrowsClientError(
        _ action: () throws -> Void,
        _ expectedError: @autoclosure () -> ClientError,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            try action()
            XCTFail(file: file, line: line)
        } catch {
            XCTAssertEqual(
                (error as? ClientError)?.message,
                expectedError().message,
                file: file,
                line: line
            )
        }
    }
}

private final class SpyAudioSamplesExtractor: AudioSamplesExtractor {
    private(set) var extractSamplesWasCalledWithReadSampleBuffer: CMSampleBuffer?
    private(set) var extractSamplesWasCalledWithSampleBuffer: Data?
    private(set) var extractSamplesWasCalledWithDownsamplingRate: Int?
    private(set) var timesExtractSamplesWasCalled = 0

    override func extractSamples(
        from readSampleBuffer: CMSampleBuffer?,
        sampleBuffer: inout Data,
        downsamplingRate: Int
    ) -> AudioSamplesExtractor.Result {
        extractSamplesWasCalledWithReadSampleBuffer = readSampleBuffer
        extractSamplesWasCalledWithSampleBuffer = sampleBuffer
        extractSamplesWasCalledWithDownsamplingRate = downsamplingRate
        timesExtractSamplesWasCalled += 1
        return super.extractSamples(
            from: readSampleBuffer,
            sampleBuffer: &sampleBuffer,
            downsamplingRate: downsamplingRate
        )
    }
}

private final class SpyAudioSamplesProcessor: AudioSamplesProcessor {
    private(set) var processSamplesWasCalledWithSampleBuffer: Data?
    private(set) var processSamplesWasCalledWithOutputSamples: [Float]?
    private(set) var processSamplesWasCalledWithSamplesToProcess: Int?
    private(set) var processSamplesWasCalledWithDownsamplesLength: Int?
    private(set) var processSamplesWasCalledWithDownsamplingRate: Int?
    private(set) var processSamplesWasCalledWithFilter: [Float]?
    private(set) var timesProcessSamplesWasCalled = 0

    override func processSamples(
        fromData sampleBuffer: inout Data,
        outputSamples: inout [Float],
        samplesToProcess: Int,
        downSampledLength: Int,
        downsamplingRate: Int,
        filter: [Float]
    ) {
        processSamplesWasCalledWithSampleBuffer = sampleBuffer
        processSamplesWasCalledWithOutputSamples = outputSamples
        processSamplesWasCalledWithSamplesToProcess = samplesToProcess
        processSamplesWasCalledWithDownsamplesLength = downSampledLength
        processSamplesWasCalledWithDownsamplingRate = downsamplingRate
        processSamplesWasCalledWithFilter = filter
        timesProcessSamplesWasCalled += 1

        super.processSamples(
            fromData: &sampleBuffer,
            outputSamples: &outputSamples,
            samplesToProcess: samplesToProcess,
            downSampledLength: downSampledLength,
            downsamplingRate: downsamplingRate,
            filter: filter
        )
    }
}

private final class SpyAudioSamplesPercentageTransformer: AudioSamplesPercentageTransformer {
    private(set) var transformWasCalledWithSamples: [Float]?
    private(set) var timesTransformWasCalled: Int = 0

    override func transform(
        _ samples: [Float]
    ) -> [Float] {
        transformWasCalledWithSamples = samples
        timesTransformWasCalled += 1
        return super.transform(samples)
    }
}
