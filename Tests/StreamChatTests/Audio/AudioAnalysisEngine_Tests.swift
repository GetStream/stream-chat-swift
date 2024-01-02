//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AudioAnalysisEngine_Tests: XCTestCase {
    private lazy var assetPropertiesLoader: MockAssetPropertyLoader! = .init()
    private lazy var audioAnalyser: MockAudioAnalyser! = .init()
    private lazy var audioFilePath: String! = Bundle(for: type(of: self))
        .path(forResource: "test_audio_file", ofType: "m4a")!
    private lazy var audioURL: URL! = .init(fileURLWithPath: audioFilePath)
    private lazy var subject: AudioAnalysisEngine! = .init(assetPropertiesLoader: assetPropertiesLoader, audioAnalyser: audioAnalyser)

    override func tearDown() {
        subject = nil
        audioFilePath = nil
        audioURL = nil
        audioAnalyser = nil
        assetPropertiesLoader = nil
        super.tearDown()
    }

    // MARK: - waveformVisualisation(fromAudioURL:for:completionHandler)

    func test_waveformVisualisationFromAudioURL_failsToLoadAssetProperties_throwsError() throws {
        let expectedError = AssetPropertyLoadingCompositeError(failedProperties: [], cancelledProperties: [])
        assetPropertiesLoader.loadPropertiesResult = .failure(expectedError)

        let executionExpectation = expectation(description: "Wait for waveform visualisation to complete")
        subject.waveformVisualisation(
            fromAudioURL: audioURL,
            for: 10,
            completionHandler: { result in
                switch result {
                case .success:
                    XCTFail("Unexpected path.")
                case let .failure(error):
                    XCTAssertEqual(expectedError, error)
                }
                executionExpectation.fulfill()
            }
        )

        wait(for: [executionExpectation], timeout: defaultTimeout)
    }

    func test_waveformVisualisationFromAudioURL_analyserSucceeds_returnsExpectedResult() throws {
        let expected: [Float] = .init(repeating: .random(in: 0...5), count: 10)
        assetPropertiesLoader.loadPropertiesResult = .success(.init(url: audioURL))
        audioAnalyser.analyseResult = .success(expected)

        let executionExpectation = expectation(description: "Wait for waveform visualisation to complete")
        subject.waveformVisualisation(
            fromAudioURL: audioURL,
            for: 10,
            completionHandler: { result in
                switch result {
                case let .success(analysisResult):
                    XCTAssertEqual(analysisResult, expected)
                case .failure:
                    XCTFail()
                }
                executionExpectation.fulfill()
            }
        )

        wait(for: [executionExpectation], timeout: defaultTimeout)
    }

    // MARK: - waveformVisualisation(fromLiveAudioURL:for)

    func test_waveformVisualisationFromLiveAudioURL_analyserFails_throwsError() throws {
        let error = NSError(domain: .unique, code: .unique)
        audioAnalyser.analyseResult = .failure(error)

        XCTAssertThrowsError(try subject.waveformVisualisation(fromLiveAudioURL: audioURL, for: 10), error)
    }

    func test_waveformVisualisationFromLiveAudioURL_analyserSucceeds_returnsExpectedResult() throws {
        let expected: [Float] = .init(repeating: .random(in: 0...5), count: 10)
        audioAnalyser.analyseResult = .success(expected)

        let actual = try subject.waveformVisualisation(fromLiveAudioURL: audioURL, for: 10)

        XCTAssertEqual(expected, actual)
    }
}
